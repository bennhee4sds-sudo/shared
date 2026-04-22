# Project Preview Hub Skill

This skill packages the working pattern used to create and maintain a Starlight-based Project Preview Hub on Windows.

## Purpose

Use this skill when you want to:
- create a new Project Preview Hub
- repair an existing preview hub
- add auto-sync from a projects root
- support preview of Markdown, images, PDFs, diagrams, wireframes, personas, customer journeys, and related deliverables

## Included

- `SKILL.md`
  - trigger and workflow guidance
- `references/blueprint.md`
  - architecture, required files, behavior rules
- `references/windows-ops.md`
  - local run, watcher, scheduled task usage
- `assets/templates/...`
  - ready-to-copy template files for:
    - `astro.config.mjs`
    - `scripts/docs-sources.mjs`
    - `scripts/collect-docs.mjs`
    - `scripts/sync-docs.ps1`
    - `scripts/watch-docs.ps1`
    - `scripts/launch-watch-docs.ps1`
    - `src/content/docs/index.mdx`

## What The Templates Handle

- dynamic project folder discovery
- artifact mirroring into `src/content/docs/<slug>/`
- hidden project overview page generation
- Korean text normalization with UTF-8 and EUC-KR/CP949 fallback
- Windows-safe sync behavior for add, update, delete, and rename cases
- temp sync work outside `src/content/docs` so Astro does not import transient `.__sync__` paths
- asset-first, Markdown-second copy order to reduce `ImageNotFound` races during live preview refresh
- watcher-based sync with fallback full sync interval
- scheduled task friendly watcher launch flow

## Placeholders To Replace

- `__PROJECTS_ROOT__`
- `__HUB_REPO_NAME__`
- `__HUB_TITLE__`
- `__SITE_URL__`
- `__TASK_NAME__`

## Typical Usage

1. Create or prepare a Starlight repo.
2. Copy the template files from `assets/templates`.
3. Replace the placeholders with environment-specific values.
4. Ensure `package.json` includes:
   - `collect`
   - `sync:docs`
   - `watch:docs`
5. Run:

```powershell
cd <hub-repo>
$env:ASTRO_TELEMETRY_DISABLED='1'
npm.cmd run collect
npm.cmd run dev -- --host
```

## Validation

If Python and `PyYAML` are available, validate with:

```powershell
& "C:\Users\keumsik.im\AppData\Local\Programs\Python\Python312\python.exe" `
  "C:\Users\keumsik.im\.codex\skills\.system\skill-creator\scripts\quick_validate.py" `
  "<path-to-skill>"
```

## Notes

- This skill was built from a working local Project Preview Hub implementation.
- The templates are optimized for Windows + PowerShell + `npm.cmd`.
- If browser content looks stale after major structural changes, restart the dev server once.
- If a hub previously used in-content temp sync folders and now shows `Could not import /.astro/content-assets.mjs` or stale `ImageNotFound` errors, clear `.astro` once and restart the dev server.
