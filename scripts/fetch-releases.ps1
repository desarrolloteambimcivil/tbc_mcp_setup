<#
.SYNOPSIS
  Downloads the setup ZIPs (and their .sha256) of a tbc-revit-mcp and a tbc-acad-mcp release
  into downloads\, for installer\build.ps1.
.DESCRIPTION
  Uses the GitHub CLI (gh). Without a tag it takes each repository's latest stable release.
  Only the published assets are used: the suite never rebuilds a product.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\fetch-releases.ps1
  powershell -ExecutionPolicy Bypass -File scripts\fetch-releases.ps1 -RevitTag v1.3.3 -AcadTag v2.2.0
#>
[CmdletBinding()]
param(
    [string]$RevitTag,
    [string]$AcadTag
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$downloads = Join-Path $repoRoot 'downloads'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) not found. Install it with: winget install GitHub.cli' }

if (Test-Path $downloads) { Remove-Item $downloads -Recurse -Force }
New-Item -ItemType Directory -Path $downloads | Out-Null

$products = @(
    @{ Repo = 'desarrolloteambimcivil/tbc_mcp_revit'; Tag = $RevitTag; Pattern = 'TbcRevitMcp.Setup-*-win-x64.zip*' }
    @{ Repo = 'desarrolloteambimcivil/tbc_mcp_autocad'; Tag = $AcadTag; Pattern = 'TbcAcadMcp.Setup-*-win-x64.zip*' }
)
foreach ($p in $products) {
    $tag = $p.Tag
    if (-not $tag) {
        $tag = (& gh release view --repo $p.Repo --json tagName --jq .tagName)
        if ($LASTEXITCODE -ne 0 -or -not $tag) { throw "No published release in $($p.Repo)" }
    }
    Write-Host "[fetch] $($p.Repo) $tag"
    & gh release download $tag --repo $p.Repo --pattern $p.Pattern --dir $downloads
    if ($LASTEXITCODE -ne 0) { throw "Download from $($p.Repo) $tag failed" }
}
Get-ChildItem $downloads | ForEach-Object { Write-Host "[fetch] $($_.Name)" }
