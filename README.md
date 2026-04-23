# Project Preview Hub Skill

This repository contains a reusable Codex skill for creating and repairing a Windows-based Project Preview Hub.

The hub mirrors project folders into a Starlight site so teammates can preview project artifacts such as:
- Markdown documents
- images and SVG diagrams
- PDFs
- wireframes
- ERDs
- personas
- customer journeys
- decks, sheets, and related delivery artifacts

## Quick Start

1. Clone this repository locally.
2. Copy this repository into your local Codex skills folder as `project-preview-hub`.
3. Validate the skill.
4. Ask Codex to use `project-preview-hub` when creating or repairing a preview hub.

## Install In 60 Seconds

If you already have Git and Python, this is the shortest path:

```powershell
cd $HOME\Projects
git clone https://github.com/bennhee4sds-sudo/shared.git
cd $HOME\Projects\shared
powershell -ExecutionPolicy Bypass -File .\scripts\install-local-skill.ps1
```

Then use a prompt like:

```text
Use project-preview-hub to create a preview hub for C:\Users\me\Projects
```

## Install From GitHub

Clone the repository:

```powershell
cd $HOME\Projects
git clone https://github.com/bennhee4sds-sudo/shared.git
```

If you already have it:

```powershell
cd $HOME\Projects\shared
git pull
```

## Copy Into Local Codex Skills Folder

Codex loads local skills from `$HOME\.codex\skills`.

Use the installer. It copies this repository into the required skill name and writes a local manifest:

```powershell
cd $HOME\Projects\shared
powershell -ExecutionPolicy Bypass -File .\scripts\install-local-skill.ps1
```

After copying, the main file should exist here:

```text
C:\Users\<your-user>\.codex\skills\project-preview-hub\SKILL.md
```

The installer also creates:

```text
C:\Users\<your-user>\.codex\skills\project-preview-hub\.local\install-manifest.json
```

The manifest records local environment values such as `codexHome`, `skillPath`, `sharedRepoPath`, `pythonPath`, and `gitPath`. Future updates read this file so a teammate who installed in a different B-environment keeps that B-environment during updates.

## Enable Automatic Skill Updates

After the first install, register the safe updater:

```powershell
cd $HOME\Projects\shared
powershell -ExecutionPolicy Bypass -File .\scripts\register-skill-auto-update.ps1
```

The scheduled task runs at logon and daily at `09:00` by default.

The updater:
- reads `.local\install-manifest.json`
- runs `git pull` in the shared repo
- prepares the new skill in a temp folder
- validates the candidate skill when the validator is available
- backs up the existing local skill
- replaces the installed skill only after validation succeeds
- preserves `.local\install-manifest.json`
- writes logs under `.local\logs`

If validation, Git, Python, permissions, or network access fail, the updater leaves the existing installed skill in place.

To update manually:

```powershell
cd $HOME\Projects\shared
powershell -ExecutionPolicy Bypass -File .\scripts\update-local-skill.ps1
```

## Validate The Skill

If Python is installed, validate with:

```powershell
& "$HOME\AppData\Local\Programs\Python\Python312\python.exe" `
  "$HOME\.codex\skills\.system\skill-creator\scripts\quick_validate.py" `
  "$HOME\.codex\skills\project-preview-hub"
```

Expected result:

```text
Skill is valid!
```

## How To Use The Skill

In Codex, ask for the skill explicitly. Example prompts:

```text
Use project-preview-hub to create a new preview hub for C:\Users\me\Projects
```

```text
Use project-preview-hub to repair my existing docs-hub repo
```

```text
Use project-preview-hub to add auto-sync and scheduled task support
```

## What This Skill Sets Up

The templates and instructions cover:
- dynamic project folder discovery
- artifact mirroring into `src/content/docs/<slug>/`
- hidden project overview page generation
- UTF-8 normalization with EUC-KR/CP949 fallback for Korean Markdown
- Windows-safe sync behavior for add, update, delete, and rename cases
- temp sync work outside `src/content/docs` so Astro does not import transient temp paths
- asset-first, Markdown-second copy order to reduce `ImageNotFound` races
- watcher-based sync with fallback full sync interval
- scheduled-task-friendly watcher launch flow

## Preventing Regression

This skill now includes a maintainer self-test and a canonical-source workflow so fixes are less likely to drift or regress.

- Use one working hub repo as the canonical implementation.
- Apply fixes there first.
- Sync the matching change into the templates.
- Run the included self-test before publishing the updated skill.

Maintainer self-test:

```powershell
cd <skill-repo>
powershell -ExecutionPolicy Bypass -File .\scripts\self-test.ps1 `
  -CanonicalHubRepo C:\Users\<your-user>\Projects\docs-hub `
  -ProjectsRoot C:\Users\<your-user>\Projects
```

What the self-test checks:
- skill structural validation when the validator is available
- template application into a fresh temporary hub repo
- `powershell -ExecutionPolicy Bypass -File .\scripts\preflight.ps1`
- actual mirrored output generation

## Files Included

- `SKILL.md`
  - main skill instructions
- `VERSION`
  - distributed skill version marker
- `references/blueprint.md`
  - architecture and behavior rules
- `references/windows-ops.md`
  - local run and Windows scheduled task guidance
- `references/maintenance.md`
  - maintainer workflow for syncing fixes and preventing template drift
- `scripts/self-test.ps1`
  - maintainer end-to-end validation script for installation and runtime checks
- `scripts/install-local-skill.ps1`
  - teammate installer that creates `.local/install-manifest.json`
- `scripts/update-local-skill.ps1`
  - manifest-aware safe updater
- `scripts/register-skill-auto-update.ps1`
  - Windows scheduled task registration for automatic skill updates
- `assets/templates/scripts/preflight.ps1.tmpl`
  - runtime preflight template for file checks, collect, and build verification
- `assets/templates/...`
  - ready-to-copy templates for:
  - `astro.config.mjs`
  - `scripts/docs-sources.mjs`
  - `scripts/collect-docs.mjs`
  - `scripts/preflight.ps1`
  - `scripts/sync-docs.ps1`
  - `scripts/watch-docs.ps1`
  - `scripts/launch-watch-docs.ps1`
  - `src/content/docs/index.mdx`

## Placeholders To Replace

When Codex applies the templates to a target repo, these placeholders must be replaced:

- `__PROJECTS_ROOT__`
- `__HUB_REPO_NAME__`
- `__HUB_TITLE__`
- `__SITE_URL__`
- `__TASK_NAME__`

## Typical Hub Runtime Commands

After the hub repo is created:

```powershell
cd <hub-repo>
$env:ASTRO_TELEMETRY_DISABLED='1'
powershell -ExecutionPolicy Bypass -File .\scripts\preflight.ps1
npm.cmd run dev -- --host
```

## Sync Behavior

The generated sync flow is designed so local preview updates are not treated as failed only because GitHub push failed.

- local collect and commit should still complete
- push failure should be reported clearly
- strict failure on push should only be used when that behavior is explicitly desired

## Troubleshooting

If the preview looks stale after major structural changes:

```powershell
cd <hub-repo>
Ctrl+C
Remove-Item -LiteralPath .\.astro -Recurse -Force
$env:ASTRO_TELEMETRY_DISABLED='1'
npm.cmd run dev -- --host
```

This is especially helpful when an older hub previously used temp sync folders inside `src/content/docs` and stale generated imports remain in `.astro`.

## FAQ

### Do I install the repo as `shared` or `project-preview-hub`?

Clone the GitHub repository as `shared` if you want, but copy it into your local Codex skills folder using the folder name `project-preview-hub`.

### Where does Codex look for the skill?

Codex looks under:

```text
C:\Users\<your-user>\.codex\skills\project-preview-hub
```

### Do I need to edit the template files by hand?

Usually no. The skill is meant to guide Codex to apply the templates and replace placeholders in the target hub repo.

### When should I clear `.astro`?

Only when the preview shows stale import errors such as:
- `Could not import /.astro/content-assets.mjs`
- `ImageNotFound` after a sync structure change

### What kinds of files can this preview hub handle?

It is designed for common project artifacts such as:
- Markdown and MDX
- images and SVGs
- PDFs
- ERDs and diagram files
- wireframes and design artifacts
- personas and customer journey files
- office documents and related delivery materials

## Notes

- This skill was built from a working local Project Preview Hub implementation.
- The templates are optimized for Windows, PowerShell, and `npm.cmd`.
- The repository name is `shared`, but the installed local skill folder name should be `project-preview-hub`.
