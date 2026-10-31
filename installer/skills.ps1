<#
.SYNOPSIS
  Installs or removes the Claude Code skills shipped with the TBC-MCP suite.
.DESCRIPTION
  Install: copies each folder of -Source that has a SKILL.md to <Target>\<name>. A folder already
  there that this script did not install is moved to <Target>\..\skills-backup\<name>-<time> first,
  so a skill the user wrote is never lost. What was installed and backed up goes to -Record.

  Uninstall: removes only the folders listed in -Record and puts back the backup each one replaced.
  Skills the suite did not install are never touched.

  Runs in Windows PowerShell 5.1, which is what the installer calls.
.PARAMETER Target
  Skills folder. Defaults to the user's Claude Code skills, %USERPROFILE%\.claude\skills.
.EXAMPLE
  powershell -File skills.ps1 -Source .\skills -Record .\skills-installed.json
  powershell -File skills.ps1 -Uninstall -Record .\skills-installed.json
#>
[CmdletBinding()]
param(
    [string]$Source,
    [Parameter(Mandatory = $true)][string]$Record,
    [string]$Target = (Join-Path $env:USERPROFILE '.claude\skills'),
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$backupRoot = Join-Path (Split-Path -Parent $Target) 'skills-backup'

function Read-Record {
    if (-not (Test-Path -LiteralPath $Record)) { return @() }
    $items = Get-Content -LiteralPath $Record -Raw | ConvertFrom-Json
    return @($items)
}

function Write-Record($Items) {
    $json = ConvertTo-Json -InputObject @($Items) -Depth 4
    [IO.File]::WriteAllText($Record, $json, (New-Object Text.UTF8Encoding($false)))
}

if ($Uninstall) {
    foreach ($item in (Read-Record)) {
        $dest = Join-Path $Target $item.name
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        if ($item.backup -and (Test-Path -LiteralPath $item.backup)) {
            Move-Item -LiteralPath $item.backup -Destination $dest
            Write-Host "[skills] $($item.name): restored the previous copy"
        } else {
            Write-Host "[skills] $($item.name): removed"
        }
    }
    if (Test-Path -LiteralPath $Record) { Remove-Item -LiteralPath $Record -Force }
    return
}

if (-not $Source) { throw 'Pass -Source with the skills to install, or -Uninstall.' }
$previous = @(Read-Record)
$ownedNames = @($previous | ForEach-Object { $_.name })
$skills = @(Get-ChildItem -LiteralPath $Source -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') })
if ($skills.Count -eq 0) { throw "No skill folders (with SKILL.md) in $Source" }

New-Item -ItemType Directory -Path $Target -Force | Out-Null
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$installed = @()
foreach ($skill in $skills) {
    $dest = Join-Path $Target $skill.Name
    $entry = $previous | Where-Object { $_.name -eq $skill.Name } | Select-Object -First 1
    $backup = if ($entry) { $entry.backup } else { $null }
    if ((Test-Path -LiteralPath $dest) -and ($ownedNames -notcontains $skill.Name)) {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        $backup = Join-Path $backupRoot "$($skill.Name)-$stamp"
        Move-Item -LiteralPath $dest -Destination $backup
        Write-Host "[skills] $($skill.Name): existing copy moved to $backup"
    } elseif (Test-Path -LiteralPath $dest) {
        Remove-Item -LiteralPath $dest -Recurse -Force
    }
    Copy-Item -LiteralPath $skill.FullName -Destination $dest -Recurse
    $installed += [pscustomobject]@{ name = $skill.Name; backup = $backup }
    Write-Host "[skills] $($skill.Name): installed"
}
# Keep entries of skills an earlier version installed and this one no longer ships, so uninstall still removes them.
foreach ($old in $previous) {
    if (-not ($installed | Where-Object { $_.name -eq $old.name })) { $installed += $old }
}
Write-Record $installed
