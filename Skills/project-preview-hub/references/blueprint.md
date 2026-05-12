# Blueprint

This skill packages the working structure used for a Windows-based Starlight preview hub.

## Required Files

- `astro.config.mjs`
- `scripts/docs-sources.mjs`
- `scripts/collect-docs.mjs`
- `scripts/preflight.ps1`
- `scripts/preview-guard.ps1`
- `scripts/sync-docs.ps1`
- `scripts/watch-docs.ps1`
- `scripts/launch-watch-docs.ps1`
- `src/content/docs/index.mdx`

## Placeholders

Replace these placeholders in template files:

- `__PROJECTS_ROOT__`: Absolute projects root to scan.
- `__HUB_REPO_NAME__`: Repo folder name to exclude from scanning.
- `__HUB_TITLE__`: Site title shown in Starlight.
- `__SITE_URL__`: Site URL used in Astro config.
- `__TASK_NAME__`: Scheduled task and mutex name prefix.

## Expected Behavior

- Scan direct child folders under the projects root.
- Ignore the hub repo, `_starlight-template`, hidden folders, and build folders.
- Use `String.raw` for injected Windows absolute paths in template output so backslashes do not break the generated script.
- Mirror Markdown, PDFs, images, videos, diagrams, and common office artifacts.
- Generate one hidden `index.mdx` preview page per project so the sidebar shows only real docs.
- Add frontmatter titles to Markdown files when missing.
- Remove a duplicated top-level `# Heading` if it matches the frontmatter title.
- Read Markdown with UTF-8 first, but prefer EUC-KR/CP949 when that yields better Korean text.
- Write normalized Markdown back as UTF-8.
- During sync, do not clear `.astro`; dev server imports depend on it.
- Local preview sync should not be treated as failed only because GitHub push failed. Remote delivery failure should be reported without breaking the local sync result unless strict failure is explicitly required.
- During collection on Windows, copy into a temp folder outside `src/content/docs`, copy temp contents into the destination, prune stale files, then remove the temp folder.
- Copy non-Markdown assets into the destination before Markdown files so updated docs do not reference assets that have not been copied yet.
- Auto-sync should watch the entire projects root and run a fallback full sync on a timer.
- If a hub previously used temp folders inside `src/content/docs`, one manual `.astro` clear and dev-server restart may be needed to flush stale generated imports.
- Add a runtime preflight script that checks required files, validates referenced custom CSS assets, reports preview port status, verifies mirror freshness, and runs `collect` plus `build` before operational changes are treated as complete.
- Guard the fixed preview port with a startup script so `4322` is either used by the hub or fails loudly before Astro starts.

## package.json Scripts

Ensure the target repo includes these scripts:

```json
{
  "collect": "node ./scripts/collect-docs.mjs",
  "preflight": "powershell -ExecutionPolicy Bypass -File ./scripts/preflight.ps1",
  "check:port": "powershell -ExecutionPolicy Bypass -File ./scripts/preview-guard.ps1 -Mode port-only",
  "sync:docs": "powershell -ExecutionPolicy Bypass -File ./scripts/sync-docs.ps1",
  "watch:docs": "powershell -ExecutionPolicy Bypass -File ./scripts/watch-docs.ps1",
  "dev": "powershell -ExecutionPolicy Bypass -File ./scripts/preview-guard.ps1 -Mode dev",
  "build": "astro build",
  "preview": "powershell -ExecutionPolicy Bypass -File ./scripts/preview-guard.ps1 -Mode preview"
}
```

## Template Order

Apply templates in this order:

1. `scripts/docs-sources.mjs`
2. `scripts/collect-docs.mjs`
3. `scripts/preflight.ps1`
4. `scripts/preview-guard.ps1`
5. `scripts/sync-docs.ps1`
6. `scripts/watch-docs.ps1`
7. `scripts/launch-watch-docs.ps1`
8. `astro.config.mjs`
9. `src/content/docs/index.mdx`

Run `npm.cmd run preflight` after copying the templates.

## Maintenance Note

For reusable skill maintenance, keep one working hub repo as the canonical implementation and sync template changes from that source only after the fix is confirmed there.
