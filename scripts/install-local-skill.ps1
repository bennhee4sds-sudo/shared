[CmdletBinding()]
param(
    [string]$SkillName = "project-preview-hub",
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }),
    [string]$SharedRepoPath,
    [string]$InstalledFrom = "https://github.com/bennhee4sds-sudo/shared.git",
    [string]$AutoUpdateTaskName = "ProjectPreviewHubSkillAutoUpdate",
    [switch]$RegisterAutoUpdate
)

$ErrorActionPreference = "Stop"

function Resolve-ToolPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }

        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
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
        [string]$SkillPath,

        [string]$PythonPath
    )

    $validator = Join-Path $CodexHome "skills\.system\skill-creator\scripts\quick_validate.py"
    if (-not (Test-Path -LiteralPath $validator)) {
        Write-Warning "[skill-install] Validator not found at $validator. Skipping structural validation."
        return $false
    }

    if (-not $PythonPath) {
        Write-Warning "[skill-install] Python was not found. Skipping structural validation."
        return $false
    }

    & $PythonPath $validator $SkillPath
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
$skillsRoot = Join-Path $CodexHome "skills"
$skillPath = Join-Path $skillsRoot $SkillName
$localPath = Join-Path $skillPath ".local"
$manifestPath = Join-Path $localPath "install-manifest.json"
$versionPath = Join-Path $SharedRepoPath "VERSION"
$version = if (Test-Path -LiteralPath $versionPath) { (Get-Content -LiteralPath $versionPath -Raw).Trim() } else { "unknown" }

$gitPath = Resolve-ToolPath -Candidates @("git", "git.exe", "C:\Program Files\Git\cmd\git.exe")
$pythonPath = Resolve-ToolPath -Candidates @(
    (Join-Path $env:USERPROFILE "AppData\Local\Programs\Python\Python312\python.exe"),
    "C:\Python312\python.exe",
    "py",
    "python"
)

Write-Host "[skill-install] Installing $SkillName" -ForegroundColor Cyan
Write-Host "[skill-install] Source: $SharedRepoPath"
Write-Host "[skill-install] Target: $skillPath"

New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null

if (Test-Path -LiteralPath $skillPath) {
    $backupRoot = Join-Path $CodexHome "skill-backups\$SkillName"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $backupRoot $timestamp
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    Copy-DirectoryContents -Source $skillPath -Destination $backupPath
    Write-Host "[skill-install] Existing skill backed up to $backupPath" -ForegroundColor DarkGray
    Remove-Item -LiteralPath $skillPath -Recurse -Force
}

Copy-SkillFiles -Source $SharedRepoPath -Destination $skillPath
New-Item -ItemType Directory -Force -Path $localPath | Out-Null

$manifest = [ordered]@{
    skillName = $SkillName
    version = $version
    installedFrom = $InstalledFrom
    installedAt = (Get-Date).ToString("o")
    updatedAt = (Get-Date).ToString("o")
    sharedRepoPath = $SharedRepoPath
    codexHome = $CodexHome
    skillPath = $skillPath
    gitPath = $gitPath
    pythonPath = $pythonPath
    autoUpdateTaskName = $AutoUpdateTaskName
    autoUpdateEnabled = [bool]$RegisterAutoUpdate
}

($manifest | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$validated = Invoke-Validation -SkillPath $skillPath -PythonPath $pythonPath

if ($RegisterAutoUpdate) {
    $registerScript = Join-Path $SharedRepoPath "scripts\register-skill-auto-update.ps1"
    if (Test-Path -LiteralPath $registerScript) {
        powershell -ExecutionPolicy Bypass -File $registerScript -TaskName $AutoUpdateTaskName -SharedRepoPath $SharedRepoPath -SkillPath $skillPath
    } else {
        Write-Warning "[skill-install] Auto-update registration script was not found."
    }
}

Write-Host "[skill-install] Installed $SkillName version $version." -ForegroundColor Green
if (-not $validated) {
    Write-Warning "[skill-install] Installation completed, but structural validation was skipped."
}
