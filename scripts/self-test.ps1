param(
    [string]$CanonicalHubRepo = "",
    [string]$ProjectsRoot = "",
    [string]$WorkspaceRoot = "",
    [switch]$KeepTestRepo
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[self-test] $Message"
}

function Invoke-CheckedCommand {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $FilePath @ArgumentList
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($ArgumentList -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Copy-DirectorySafe {
    param(
        [string]$Source,
        [string]$Destination,
        [string[]]$ExcludeDirectories = @()
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    $arguments = @($Source, $Destination, '/E', '/NFL', '/NDL', '/NJH', '/NJS', '/NC', '/NS')

    if ($ExcludeDirectories.Count -gt 0) {
        $arguments += '/XD'
        $arguments += $ExcludeDirectories
    }

    & robocopy @arguments | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Apply-Template {
    param(
        [string]$TemplatePath,
        [string]$TargetPath,
        [hashtable]$Values
    )

    $content = Get-Content -Raw $TemplatePath
    foreach ($key in $Values.Keys) {
        $content = $content.Replace($key, $Values[$key])
    }
    Write-Utf8File -Path $TargetPath -Content $content
}

function Test-PythonSupportsYaml {
    param([string]$Executable)

    try {
        & $Executable -c "import yaml" *> $null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Resolve-PythonExecutable {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe'),
        'python',
        'py'
    ) | Where-Object { $_ }

    foreach ($candidate in $candidates) {
        if (($candidate -notin @('python', 'py')) -and -not (Test-Path $candidate)) {
            continue
        }

        try {
            & $candidate --version *> $null
        }
        catch {
            continue
        }

        if ($LASTEXITCODE -eq 0 -and (Test-PythonSupportsYaml -Executable $candidate)) {
            return $candidate
        }
    }

    return $null
}

$skillRepoRoot = Split-Path -Parent $PSScriptRoot
$templatesRoot = Join-Path $skillRepoRoot 'assets\templates'
$defaultProjectsRoot = Split-Path -Parent $skillRepoRoot

if (-not $CanonicalHubRepo) {
    $candidate = Join-Path $defaultProjectsRoot 'P002_project-preview-hub'
    if (Test-Path $candidate) {
        $CanonicalHubRepo = $candidate
    }
}

if (-not $CanonicalHubRepo) {
    throw "CanonicalHubRepo is required when P002_project-preview-hub is not present beside the skill repository."
}

if (-not (Test-Path $CanonicalHubRepo)) {
    throw "Canonical hub repo not found: $CanonicalHubRepo"
}

if (-not $ProjectsRoot) {
    $ProjectsRoot = Split-Path -Parent $CanonicalHubRepo
}

if (-not (Test-Path $ProjectsRoot)) {
    throw "Projects root not found: $ProjectsRoot"
}

if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Join-Path $ProjectsRoot '.preview-hub-self-test'
}

$testRepoName = 'preview-hub-self-test-repo'
$testRepoRoot = Join-Path $WorkspaceRoot $testRepoName

Write-Step "Skill repo: $skillRepoRoot"
Write-Step "Canonical hub repo: $CanonicalHubRepo"
Write-Step "Projects root: $ProjectsRoot"
Write-Step "Workspace root: $WorkspaceRoot"

Remove-Item -LiteralPath $WorkspaceRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $WorkspaceRoot | Out-Null

$exclude = @('.git', '.astro', 'dist', 'node_modules', 'logs')
Write-Step "Copying canonical repo into temp test repo"
Copy-DirectorySafe -Source $CanonicalHubRepo -Destination $testRepoRoot -ExcludeDirectories $exclude

$templateValues = @{
    '__PROJECTS_ROOT__' = $ProjectsRoot
    '__HUB_REPO_NAME__' = $testRepoName
    '__HUB_TITLE__' = 'Preview Hub Self Test'
    '__SITE_URL__' = 'https://example.com'
    '__TASK_NAME__' = 'PreviewHubSelfTest'
}

$templatePairs = @(
    @{ Template = 'astro.config.mjs.tmpl'; Target = 'astro.config.mjs' }
    @{ Template = 'scripts\docs-sources.mjs.tmpl'; Target = 'scripts\docs-sources.mjs' }
    @{ Template = 'scripts\collect-docs.mjs.tmpl'; Target = 'scripts\collect-docs.mjs' }
    @{ Template = 'scripts\preflight.ps1.tmpl'; Target = 'scripts\preflight.ps1' }
    @{ Template = 'scripts\preview-guard.ps1.tmpl'; Target = 'scripts\preview-guard.ps1' }
    @{ Template = 'scripts\sync-docs.ps1.tmpl'; Target = 'scripts\sync-docs.ps1' }
    @{ Template = 'scripts\watch-docs.ps1.tmpl'; Target = 'scripts\watch-docs.ps1' }
    @{ Template = 'scripts\launch-watch-docs.ps1.tmpl'; Target = 'scripts\launch-watch-docs.ps1' }
    @{ Template = 'src\content\docs\index.mdx.tmpl'; Target = 'src\content\docs\index.mdx' }
)

Write-Step "Applying templates"
foreach ($pair in $templatePairs) {
    $templatePath = Join-Path $templatesRoot $pair.Template
    $targetPath = Join-Path $testRepoRoot $pair.Target
    Apply-Template -TemplatePath $templatePath -TargetPath $targetPath -Values $templateValues
}

$python = Resolve-PythonExecutable
$validator = Join-Path $env:USERPROFILE '.codex\skills\.system\skill-creator\scripts\quick_validate.py'

if ($python -and (Test-Path $validator)) {
    Write-Step "Running skill structural validation"
    Invoke-CheckedCommand -FilePath $python -ArgumentList @($validator, $skillRepoRoot) -WorkingDirectory $skillRepoRoot
}
else {
    Write-Step "Skipping structural validation because Python or quick_validate.py was not found"
}

Write-Step "Installing test repo dependencies"
Invoke-CheckedCommand -FilePath 'npm.cmd' -ArgumentList @('install') -WorkingDirectory $testRepoRoot

Write-Step "Running preflight"
Invoke-CheckedCommand -FilePath 'powershell' -ArgumentList @('-ExecutionPolicy', 'Bypass', '-File', '.\scripts\preflight.ps1') -WorkingDirectory $testRepoRoot

$mirroredDocsRoot = Join-Path $testRepoRoot 'src\content\docs'
if (-not (Test-Path $mirroredDocsRoot)) {
    throw "Preflight did not create src/content/docs"
}

$mirroredProjects = Get-ChildItem -Path $mirroredDocsRoot -Directory -ErrorAction Stop
if ($mirroredProjects.Count -eq 0) {
    throw "Collect completed but no mirrored project directories were created."
}

Write-Step "Running build"
$previousTelemetry = $env:ASTRO_TELEMETRY_DISABLED
$env:ASTRO_TELEMETRY_DISABLED = '1'
try {
    Invoke-CheckedCommand -FilePath 'npm.cmd' -ArgumentList @('run', 'build') -WorkingDirectory $testRepoRoot
}
finally {
    if ($null -eq $previousTelemetry) {
        Remove-Item Env:ASTRO_TELEMETRY_DISABLED -ErrorAction SilentlyContinue
    }
    else {
        $env:ASTRO_TELEMETRY_DISABLED = $previousTelemetry
    }
}

$sampleAsset = Join-Path $testRepoRoot 'src\content\docs\p001-biz-health-dashboard\PROJECT_ORG_CHART.svg'
if (Test-Path $sampleAsset) {
    Write-Step "Verified sample asset mirroring: $sampleAsset"
}
else {
    Write-Step "Sample asset path not found. This may be expected if the current projects root does not contain that project."
}

Write-Step "Self-test passed"
Write-Host "Temporary test repo: $testRepoRoot"

if (-not $KeepTestRepo) {
    Write-Step "Cleaning up temp test workspace"
    Remove-Item -LiteralPath $WorkspaceRoot -Recurse -Force -ErrorAction SilentlyContinue
}
else {
    Write-Step "Keeping temp test workspace because -KeepTestRepo was specified"
}
