[CmdletBinding()]
param(
    [string]$TaskName = "ProjectPreviewHubSkillAutoUpdate",
    [string]$SharedRepoPath,
    [string]$SkillPath,
    [string]$DailyTime = "09:00",
    [switch]$DailyOnly
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SharedRepoPath)) {
    $SharedRepoPath = Split-Path -Parent $PSScriptRoot
}
$SharedRepoPath = (Resolve-Path -LiteralPath $SharedRepoPath).Path
if ([string]::IsNullOrWhiteSpace($SkillPath)) {
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
    $SkillPath = Join-Path $codexHome "skills\project-preview-hub"
}
$updateScript = Join-Path $SharedRepoPath "scripts\update-local-skill.ps1"
if (-not (Test-Path -LiteralPath $updateScript)) {
    throw "Update script was not found: $updateScript"
}

$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$updateScript`" -SharedRepoPath `"$SharedRepoPath`" -SkillPath `"$SkillPath`""
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument
$triggers = @()
if (-not $DailyOnly) {
    $triggers += New-ScheduledTaskTrigger -AtLogOn
}
$triggers += New-ScheduledTaskTrigger -Daily -At $DailyTime
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggers -Principal $principal | Out-Null

$manifestPath = Join-Path $SkillPath ".local\install-manifest.json"
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $updated = [ordered]@{
        skillName = $manifest.skillName
        version = $manifest.version
        installedFrom = $manifest.installedFrom
        installedAt = $manifest.installedAt
        updatedAt = $manifest.updatedAt
        sharedRepoPath = $manifest.sharedRepoPath
        codexHome = $manifest.codexHome
        skillPath = $manifest.skillPath
        gitPath = $manifest.gitPath
        pythonPath = $manifest.pythonPath
        autoUpdateTaskName = $TaskName
        autoUpdateEnabled = $true
    }
    ($updated | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $manifestPath -Encoding UTF8
}

Write-Host "[skill-auto-update] Registered scheduled task: $TaskName" -ForegroundColor Green
Write-Host "[skill-auto-update] It will run at logon and daily at $DailyTime unless -DailyOnly was used."
