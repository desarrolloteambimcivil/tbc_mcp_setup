<#
.SYNOPSIS
  Checks installer\skills.ps1 in a temporary folder: install, backup of a skill the user wrote,
  reinstall over its own copy, and uninstall that restores the backup. No test framework needed.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File tests\skills.Tests.ps1
#>
$ErrorActionPreference = 'Stop'
$script = Join-Path (Split-Path -Parent $PSScriptRoot) 'installer\skills.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ("tbc-mcp-skills-" + [Guid]::NewGuid().ToString('N'))
$failures = 0

function Check([string]$Name, [bool]$Condition) {
    if ($Condition) { Write-Host "PASS $Name" } else { Write-Host "FAIL $Name"; $script:failures++ }
}

function Put([string]$Path, [string]$Text) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText($Path, $Text)
}

try {
    $source = Join-Path $root 'source'
    $target = Join-Path $root 'home\.claude\skills'
    $record = Join-Path $root 'skills-installed.json'
    Put (Join-Path $source 'tbc-a\SKILL.md') 'suite a v1'
    Put (Join-Path $source 'ema-b\SKILL.md') 'suite b v1'
    Put (Join-Path $source 'not-a-skill\readme.txt') 'ignored'
    Put (Join-Path $target 'ema-b\SKILL.md') 'written by the user'
    Put (Join-Path $target 'mine\SKILL.md') 'unrelated user skill'

    & $script -Source $source -Target $target -Record $record | Out-Null
    Check 'installs each skill folder' ((Get-Content (Join-Path $target 'tbc-a\SKILL.md') -Raw) -eq 'suite a v1')
    Check 'replaces a same-name skill' ((Get-Content (Join-Path $target 'ema-b\SKILL.md') -Raw) -eq 'suite b v1')
    Check 'skips folders without SKILL.md' (-not (Test-Path (Join-Path $target 'not-a-skill')))
    $backups = @(Get-ChildItem (Join-Path $root 'home\.claude\skills-backup') -Directory)
    Check 'backs up the user copy outside the skills folder' ($backups.Count -eq 1 -and (Get-Content (Join-Path $backups[0].FullName 'SKILL.md') -Raw) -eq 'written by the user')

    Put (Join-Path $source 'tbc-a\SKILL.md') 'suite a v2'
    & $script -Source $source -Target $target -Record $record | Out-Null
    Check 'updates its own copy in place' ((Get-Content (Join-Path $target 'tbc-a\SKILL.md') -Raw) -eq 'suite a v2')
    Check 'does not back up its own copy again' (@(Get-ChildItem (Join-Path $root 'home\.claude\skills-backup') -Directory).Count -eq 1)

    & $script -Uninstall -Target $target -Record $record | Out-Null
    Check 'removes the skills it installed' (-not (Test-Path (Join-Path $target 'tbc-a')))
    Check 'restores the user copy' ((Get-Content (Join-Path $target 'ema-b\SKILL.md') -Raw) -eq 'written by the user')
    Check 'never touches other skills' ((Get-Content (Join-Path $target 'mine\SKILL.md') -Raw) -eq 'unrelated user skill')
    Check 'removes its record' (-not (Test-Path $record))
}
finally {
    if (Test-Path $root) { Remove-Item $root -Recurse -Force }
}

if ($failures) { Write-Host "$failures failed"; exit 1 }
Write-Host 'All passed'
