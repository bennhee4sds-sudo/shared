[CmdletBinding()]
param(
    [string]$SkillName = "project-preview-hub",
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }),
    [string]$SharedRepoPath,
    [string]$SkillPath,
    [switch]$SkipPull
)

$ErrorActionPreference = "Stop"

function Resolve-ToolPath {
    param([string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
        if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    return $null
}

function Copy-SkillFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    $excludedNames = @('.git', '.local', 'node_modules', '.preview-hub-self-test', 'logs')
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | Where-Object {
        $excludedNames -notcontains $_.Name
    } | ForEach-Object {
        $target = Join-Path $Destination $_.Name
        if ($_.PSIsContainer) {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
        } else {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        $target = Join-Path $Destination $_.Name
        if ($_.PSIsContainer) {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
        } else {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }
}

function Invoke-Validation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CandidateSkillPath,

        [string]$PythonPath,

        [string]$CodexHome
    )

    $validator = Join-Path $CodexHome "skills\.system\skill-creator\scripts\quick_validate.py"
    if (-not (Test-Path -LiteralPath $validator)) {
        Write-Warning "[skill-update] Validator not found at $validator. Skipping structural validation."
        return $false
    }
    if (-not $PythonPath) {
        Write-Warning "[skill-update] Python was not found. Skipping structural validation."
        return $false
    }

    & $PythonPath $validator $CandidateSkillPath
    if ($LASTEXITCODE -ne 0) {
        throw "Skill validation failed with exit code $LASTEXITCODE."
    }
    return $true
}

if ([string]::IsNullOrWhiteSpace($SharedRepoPath)) {
    $SharedRepoPath = Split-Path -Parent $PSScriptRoot
}
$SharedRepoPath = (Resolve-Path -LiteralPath $SharedRepoPath).Path
$CodexHome = [System.IO.Path]::GetFullPath($CodexHome)
if (-not $SkillPath) {
    $SkillPath = Join-Path (Join-Path $CodexHome "skills") $SkillName
}
$SkillPath = [System.IO.Path]::GetFullPath($SkillPath)
$manifestPath = Join-Path $SkillPath ".local\install-manifest.json"
$manifest = $null

if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.sharedRepoPath -and (Test-Path -LiteralPath $manifest.sharedRepoPath)) {
        $SharedRepoPath = (Resolve-Path -LiteralPath $manifest.sharedRepoPath).Path
    }
    if ($manifest.codexHome) {
        $CodexHome = [System.IO.Path]::GetFullPath($manifest.codexHome)
    }
    if ($manifest.skillPath) {
        $SkillPath = [System.IO.Path]::GetFullPath($manifest.skillPath)
    }
}

if (-not (Test-Path -LiteralPath $SkillPath)) {
    throw "Installed skill path was not found: $SkillPath. Run install-local-skill.ps1 first."
}

$logDir = Join-Path $CodexHome "skill-update-logs\$SkillName"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logPath = Join-Path $logDir "skill-update.log"
Start-Transcript -Path $logPath -Append | Out-Null

try {
    $versionPath = Join-Path $SharedRepoPath "VERSION"
    $version = if (Test-Path -LiteralPath $versionPath) { (Get-Content -LiteralPath $versionPath -Raw).Trim() } else { "unknown" }
    $gitPath = if ($manifest -and $manifest.gitPath -and (Test-Path -LiteralPath $manifest.gitPath)) { $manifest.gitPath } else { Resolve-ToolPath -Candidates @("git", "git.exe", "C:\Program Files\Git\cmd\git.exe") }
    $pythonPath = if ($manifest -and $manifest.pythonPath -and (Test-Path -LiteralPath $manifest.pythonPath)) { $manifest.pythonPath } else { Resolve-ToolPath -Candidates @((Join-Path $env:USERPROFILE "AppData\Local\Programs\Python\Python312\python.exe"), "C:\Python312\python.exe", "py", "python") }

    Write-Host "[skill-update] Updating $SkillName" -ForegroundColor Cyan
    Write-Host "[skill-update] Source: $SharedRepoPath"
    Write-Host "[skill-update] Target: $SkillPath"

    if (-not $SkipPull -and (Test-Path -LiteralPath (Join-Path $SharedRepoPath ".git"))) {
        if (-not $gitPath) {
            throw "Git was not found, but shared repo update requires Git."
        }
        & $gitPath -C $SharedRepoPath pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            throw "git pull failed with exit code $LASTEXITCODE."
        }
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $CodexHome "skill-backups\$SkillName"
    $backupPath = Join-Path $backupRoot $timestamp
    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "$SkillName-update-$timestamp"
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

    if (Test-Path -LiteralPath $tempPath) {
        Remove-Item -LiteralPath $tempPath -Recurse -Force
    }
    Copy-DirectoryContents -Source $SkillPath -Destination $backupPath
    Copy-SkillFiles -Source $SharedRepoPath -Destination $tempPath

    $localDir = Join-Path $tempPath ".local"
    New-Item -ItemType Directory -Force -Path $localDir | Out-Null
    if (Test-Path -LiteralPath $manifestPath) {
        Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $localDir "install-manifest.json") -Force
    }

    Invoke-Validation -CandidateSkillPath $tempPath -PythonPath $pythonPath -CodexHome $CodexHome | Out-Null

    Remove-Item -LiteralPath $SkillPath -Recurse -Force
    Move-Item -LiteralPath $tempPath -Destination $SkillPath

    $newManifestPath = Join-Path $SkillPath ".local\install-manifest.json"
    $currentManifest = if (Test-Path -LiteralPath $newManifestPath) {
        Get-Content -LiteralPath $newManifestPath -Raw | ConvertFrom-Json
    } else {
        [pscustomobject]@{}
    }

    $updatedManifest = [ordered]@{
        skillName = $SkillName
        version = $version
        installedFrom = if ($currentManifest.installedFrom) { $currentManifest.installedFrom } else { "https://github.com/bennhee4sds-sudo/shared.git" }
        installedAt = if ($currentManifest.installedAt) { $currentManifest.installedAt } else { (Get-Date).ToString("o") }
        updatedAt = (Get-Date).ToString("o")
        sharedRepoPath = $SharedRepoPath
        codexHome = $CodexHome
        skillPath = $SkillPath
        gitPath = $gitPath
        pythonPath = $pythonPath
        autoUpdateTaskName = if ($currentManifest.autoUpdateTaskName) { $currentManifest.autoUpdateTaskName } else { "ProjectPreviewHubSkillAutoUpdate" }
        autoUpdateEnabled = if ($null -ne $currentManifest.autoUpdateEnabled) { [bool]$currentManifest.autoUpdateEnabled } else { $false }
    }

    ($updatedManifest | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $newManifestPath -Encoding UTF8
    Invoke-Validation -CandidateSkillPath $SkillPath -PythonPath $pythonPath -CodexHome $CodexHome | Out-Null

    Write-Host "[skill-update] Updated $SkillName to version $version." -ForegroundColor Green
    Write-Host "[skill-update] Backup: $backupPath" -ForegroundColor DarkGray
}
catch {
    Write-Error "[skill-update] Update failed. Existing skill was preserved or backup is available. $($_.Exception.Message)"
    throw
}
finally {
    Stop-Transcript | Out-Null
}
