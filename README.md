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
New-Item -ItemType Directory -Force -Path $HOME\.codex\skills | Out-Null
Remove-Item -LiteralPath $HOME\.codex\skills\project-preview-hub -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath $HOME\Projects\shared -Destination $HOME\.codex\skills\project-preview-hub -Recurse
& "$HOME\AppData\Local\Programs\Python\Python312\python.exe" `
  "$HOME\.codex\skills\.system\skill-creator\scripts\quick_validate.py" `
  "$HOME\.codex\skills\project-preview-hub"
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

Copy this repository into that folder with the required skill name:

```powershell
New-Item -ItemType Directory -Force -Path $HOME\.codex\skills | Out-Null
Remove-Item -LiteralPath $HOME\.codex\skills\project-preview-hub -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath $HOME\Projects\shared -Destination $HOME\.codex\skills\project-preview-hub -Recurse
```

After copying, the main file should exist here:

```text
C:\Users\<your-user>\.codex\skills\project-preview-hub\SKILL.md
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

## Files Included

- `SKILL.md`
  - main skill instructions
- `references/blueprint.md`
  - architecture and behavior rules
- `references/windows-ops.md`
  - local run and Windows scheduled task guidance
- `assets/templates/...`
  - ready-to-copy templates for:
  - `astro.config.mjs`
  - `scripts/docs-sources.mjs`
  - `scripts/collect-docs.mjs`
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
npm.cmd run collect
npm.cmd run dev -- --host
```

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
