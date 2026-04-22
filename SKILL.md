---
name: project-preview-hub
description: Create, update, or troubleshoot a Starlight-based Project Preview Hub that mirrors project folders into a live preview site with auto-sync, encoding normalization for Korean documents, and Windows watcher automation. Use when Codex needs to scaffold or repair a preview hub for project artifacts such as Markdown docs, PDFs, images, diagrams, wireframes, personas, customer journeys, and related deliverables.
---

# Project Preview Hub

Use this skill when the user wants a reusable preview hub that reflects project artifacts from a projects root into a Starlight site.

## Workflow

1. Inspect the target workspace and decide whether to reuse an existing Starlight repo or create a new one.
2. Read [references/blueprint.md](references/blueprint.md) for the required architecture and behavior rules.
3. Copy the templates from [assets/templates](assets/templates) into the target repo and replace placeholders:
   - `__PROJECTS_ROOT__`
   - `__HUB_REPO_NAME__`
   - `__HUB_TITLE__`
   - `__SITE_URL__`
   - `__TASK_NAME__`
4. Ensure the target `package.json` includes `collect`, `sync:docs`, and `watch:docs` scripts as described in the blueprint.
5. Run `npm.cmd run collect`, then start the site with `npm.cmd run dev -- --host`.
6. If the user wants background automation, use [references/windows-ops.md](references/windows-ops.md) to register the watcher as a scheduled task.

## Required Behaviors

- Discover project folders dynamically from the configured projects root.
- Mirror Markdown and artifact files into `src/content/docs/<slug>/`.
- Generate a hidden project `index.mdx` preview page per project.
- Normalize Markdown text to UTF-8 during collection and prefer valid Korean decoding when source files are CP949/EUC-KR.
- Avoid deleting `.astro` during sync.
- On Windows, do not rely on renaming a live destination directory during sync. Build into a temp directory outside `src/content/docs`, copy into the destination, then prune removed files.
- Copy non-Markdown assets before Markdown files so image and PDF references are already present when Astro re-imports updated docs.
- Keep preview sync robust for add, update, delete, and project-folder rename cases.
- If older temp-dir logic was previously used, document that one manual `.astro` clear and dev-server restart may be needed to flush stale `.__sync__` imports.

## Resources

- Architecture and file responsibilities: [references/blueprint.md](references/blueprint.md)
- Windows setup and operations: [references/windows-ops.md](references/windows-ops.md)
- Ready-to-copy templates: [assets/templates](assets/templates)
