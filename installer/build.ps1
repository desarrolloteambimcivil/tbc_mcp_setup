<#
.SYNOPSIS
  Builds installer\output\TbcMcp_Setup_<version>.exe from the two product release ZIPs.
.DESCRIPTION
  The release ZIPs of tbc-revit-mcp and tbc-acad-mcp are the single source of what gets
  installed. This script checks each against its .sha256 sidecar, extracts them to
  installer\payload\revit and installer\payload\acad, checks their layout, writes
  payload\suite.json and compiles tbc-mcp.iss with Inno Setup 6.

  scripts\fetch-releases.ps1 downloads the ZIPs of a published release into downloads\.
.PARAMETER RevitZip
  TbcRevitMcp.Setup-v<version>-win-x64.zip. Defaults to the newest one in downloads\.
.PARAMETER AcadZip
  TbcAcadMcp.Setup-v<version>-win-x64.zip. Defaults to the newest one in downloads\.
.PARAMETER SkillsDir
  Folder of Claude Code skills (one subfolder with a SKILL.md each) to ship as an optional
  component. Leave it out for the public build: company skills are not published.
.PARAMETER Version
  Suite version (x.y.z). Defaults to the VERSION file.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File installer\build.ps1
  powershell -ExecutionPolicy Bypass -File installer\build.ps1 -SkillsDir ..\private\skills
#>
[CmdletBinding()]
param(
    [string]$RevitZip,
    [string]$AcadZip,
    [string]$SkillsDir,
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$installerDir = $PSScriptRoot
$repoRoot = Split-Path -Parent $installerDir
$payloadDir = Join-Path $installerDir 'payload'
$downloads = Join-Path $repoRoot 'downloads'

function Find-Zip([string]$Given, [string]$Pattern) {
    if ($Given) { return (Resolve-Path $Given).Path }
    $found = Get-ChildItem $downloads -Filter $Pattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $found) { throw "No $Pattern in $downloads. Pass it or run scripts\fetch-releases.ps1 first." }
    return $found.FullName
}

# Both products write '<hash>  <name>' or '<hash> *<name>'; a ZIP without its sidecar is refused.
function Assert-Checksum([string]$Zip) {
    $sidecar = "$Zip.sha256"
    if (-not (Test-Path $sidecar)) { throw "Missing checksum file $sidecar" }
    $expected = ((Get-Content $sidecar -Raw).Trim() -split '\s+')[0]
    $actual = (Get-FileHash $Zip -Algorithm SHA256).Hash
    if ($actual -ne $expected.ToUpperInvariant()) { throw "Checksum mismatch for $Zip" }
}

function Expand-Product([string]$Zip, [string]$Name, [string[]]$Required) {
    Assert-Checksum $Zip
    $dest = Join-Path $payloadDir $Name
    Expand-Archive $Zip -DestinationPath $dest
    foreach ($item in $Required) {
        if (-not (Test-Path (Join-Path $dest $item))) { throw "$(Split-Path -Leaf $Zip) is missing $item" }
    }
    $manifest = Get-Content (Join-Path $dest 'manifest.json') -Raw | ConvertFrom-Json
    if ($manifest.dirty) { throw "$(Split-Path -Leaf $Zip) was packaged from a dirty working tree." }
    Write-Host "[build] $Name $($manifest.version) ($($manifest.commit)) checksum ok"
    return $manifest
}

if (-not $Version) { $Version = (Get-Content (Join-Path $repoRoot 'VERSION') -Raw).Trim() }
# Inno's VersionInfoVersion only takes numbers.
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Unsupported suite version '$Version' (expected x.y.z)." }

$RevitZip = Find-Zip $RevitZip 'TbcRevitMcp.Setup-v*-win-x64.zip'
$AcadZip = Find-Zip $AcadZip 'TbcAcadMcp.Setup-v*-win-x64.zip'

if (Test-Path $payloadDir) { Remove-Item $payloadDir -Recurse -Force }
New-Item -ItemType Directory -Path $payloadDir | Out-Null
$revit = Expand-Product $RevitZip 'revit' @('install.ps1', 'uninstall.ps1', 'manifest.json', 'server', 'plugins')
$acad = Expand-Product $AcadZip 'acad' @('install.ps1', 'uninstall.ps1', 'manifest.json', 'server', 'bundle')

$defines = @("/DAppVersion=$Version", "/DRevitVersion=$($revit.version)", "/DAcadVersion=$($acad.version)")
$skills = @()
if ($SkillsDir) {
    $skills = @(Get-ChildItem (Resolve-Path $SkillsDir).Path -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') })
    if ($skills.Count -eq 0) { throw "No skill folders (with SKILL.md) in $SkillsDir" }
    $skillsPayload = Join-Path $payloadDir 'skills'
    New-Item -ItemType Directory -Path $skillsPayload | Out-Null
    $skills | ForEach-Object { Copy-Item $_.FullName (Join-Path $skillsPayload $_.Name) -Recurse }
    $defines += '/DWithSkills'
    Write-Host "[build] skills: $(($skills | ForEach-Object Name) -join ', ')"
}

$suite = [ordered]@{
    name = 'TBC-MCP'
    version = $Version
    builtAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    products = [ordered]@{
        'tbc-revit-mcp' = [ordered]@{ version = $revit.version; commit = $revit.commit; zip = Split-Path -Leaf $RevitZip }
        'tbc-acad-mcp' = [ordered]@{ version = $acad.version; commit = $acad.commit; zip = Split-Path -Leaf $AcadZip }
    }
    skills = @($skills | ForEach-Object Name)
}
[IO.File]::WriteAllText((Join-Path $payloadDir 'suite.json'), ($suite | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))

# Inno Setup is not always in Program Files: winget installs it per user under LOCALAPPDATA.
$isccOnPath = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
$candidates = @(
    $env:INNO_SETUP_DIR
    if ($isccOnPath) { Split-Path -Parent $isccOnPath }
    "${env:ProgramFiles(x86)}\Inno Setup 6"
    "$env:ProgramFiles\Inno Setup 6"
    "$env:LOCALAPPDATA\Programs\Inno Setup 6"
) | Where-Object { $_ }
$iscc = $candidates | ForEach-Object { Join-Path $_ 'ISCC.exe' } | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 (ISCC.exe) not found. Install it with: winget install JRSoftware.InnoSetup' }

Write-Host "[build] suite $Version, compiler $iscc"
& $iscc @defines (Join-Path $installerDir 'tbc-mcp.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }

$exe = Join-Path $installerDir "output\TbcMcp_Setup_$Version.exe"
$hash = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -Path "$exe.sha256" -Value "$hash *$(Split-Path -Leaf $exe)" -Encoding ascii -NoNewline
Write-Host "[build] $exe"
Write-Host "[build] sha256 $hash"
