param([switch]$Offline)
$ErrorActionPreference = 'Stop'
$taskVault = Split-Path -Parent $PSScriptRoot
$taskLock = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'plugin-lock.json') -Raw | ConvertFrom-Json
foreach ($taskAsset in $taskLock) {
    $taskDir = Join-Path $taskVault ('.obsidian/plugins/' + $taskAsset.plugin)
    New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
    $taskDestination = Join-Path $taskDir $taskAsset.file
    $taskValid = (Test-Path -LiteralPath $taskDestination) -and ((Get-FileHash -LiteralPath $taskDestination -Algorithm SHA256).Hash.ToLower() -eq $taskAsset.sha256)
    if (-not $taskValid) {
        if ($Offline) { throw "Missing or changed plugin file: $($taskAsset.plugin)/$($taskAsset.file)" }
        Invoke-WebRequest -Uri $taskAsset.url -OutFile $taskDestination -UseBasicParsing
        if ((Get-FileHash -LiteralPath $taskDestination -Algorithm SHA256).Hash.ToLower() -ne $taskAsset.sha256) { throw "Plugin checksum mismatch: $($taskAsset.plugin)/$($taskAsset.file)" }
    }
}
$taskSettingsPath = Join-Path $taskVault '.obsidian/plugins/project-planner/data.json'
if (-not (Test-Path -LiteralPath $taskSettingsPath)) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'project-planner.settings.json') -Destination $taskSettingsPath
}
Write-Output 'Project Planner and Dataview files verified. Existing personal settings preserved.'
