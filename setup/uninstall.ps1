<#
.SYNOPSIS
    Uninstalls EDAMAME for Codex CLI on Windows.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$UserProfile = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$AppDataRoot = if ($env:APPDATA) { $env:APPDATA } else { Join-Path $UserProfile "AppData\Roaming" }
$LocalAppDataRoot = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $UserProfile "AppData\Local" }

$ConfigHome = Join-Path $AppDataRoot "codex-edamame"
$StateHome = Join-Path $LocalAppDataRoot "codex-edamame\state"
$DataHome = Join-Path $LocalAppDataRoot "codex-edamame"
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $UserProfile ".codex" }
$CodexConfigPath = Join-Path $CodexHome "config.toml"

function Remove-CodexMcpEntry {
    param([Parameter(Mandatory = $true)][string]$ConfigPath)
    if (-not (Test-Path $ConfigPath)) { return }
    $Marker = "[mcp_servers.edamame-codex]"
    $Raw = Get-Content -Raw $ConfigPath
    if (-not $Raw.Contains($Marker)) { return }
    Copy-Item -Force $ConfigPath "$ConfigPath.bak"
    $Lines = $Raw -split "`r?`n"
    $Out = New-Object System.Collections.Generic.List[string]
    $Skipping = $false
    foreach ($Line in $Lines) {
        if ($Line.Trim() -eq $Marker) { $Skipping = $true; continue }
        if ($Skipping -and $Line.StartsWith("[") -and $Line.Trim() -ne $Marker) { $Skipping = $false }
        if (-not $Skipping) { $Out.Add($Line) }
    }
    ($Out -join "`n").TrimEnd() | Set-Content -Path $ConfigPath -Encoding UTF8
}

Remove-CodexMcpEntry -ConfigPath $CodexConfigPath

foreach ($PathToRemove in @($DataHome, $ConfigHome, $StateHome)) {
    if (Test-Path $PathToRemove) {
        Remove-Item -Recurse -Force $PathToRemove
    }
}

Write-Host @"
Uninstalled EDAMAME for Codex CLI from:
  $DataHome
"@
