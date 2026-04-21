# Blueprint

This skill packages the working structure used for a Windows-based Starlight preview hub.

## Required Files

- `astro.config.mjs`
- `scripts/docs-sources.mjs`
- `scripts/collect-docs.mjs`
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
- Mirror Markdown, PDFs, images, videos, diagrams, and common office artifacts.
- Generate one hidden `index.mdx` preview page per project so the sidebar shows only real docs.
- Add frontmatter titles to Markdown files when missing.
- Remove a duplicated top-level `# Heading` if it matches the frontmatter title.
- Read Markdown with UTF-8 first, but prefer EUC-KR/CP949 when that yields better Korean text.
- Write normalized Markdown back as UTF-8.
- During sync, do not clear `.astro`; dev server imports depend on it.
- During collection on Windows, copy into a temp folder, copy temp contents into the destination, prune stale files, then remove the temp folder.
- Auto-sync should watch the entire projects root and run a fallback full sync on a timer.

## package.json Scripts

Ensure the target repo includes these scripts:

```json
{
  "collect": "node ./scripts/collect-docs.mjs",
  "sync:docs": "powershell -ExecutionPolicy Bypass -File ./scripts/sync-docs.ps1",
  "watch:docs": "powershell -ExecutionPolicy Bypass -File ./scripts/watch-docs.ps1",
  "dev": "astro dev",
  "build": "astro build",
  "preview": "astro preview"
}
```

## Template Order

Apply templates in this order:

1. `scripts/docs-sources.mjs`
2. `scripts/collect-docs.mjs`
3. `scripts/sync-docs.ps1`
4. `scripts/watch-docs.ps1`
5. `scripts/launch-watch-docs.ps1`
6. `astro.config.mjs`
7. `src/content/docs/index.mdx`

Run `npm.cmd run collect` after copying the templates.
