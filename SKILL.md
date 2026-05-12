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
4. Ensure the target `package.json` includes `collect`, `preflight`, `sync:docs`, and `watch:docs` scripts as described in the blueprint.
5. Run `powershell -ExecutionPolicy Bypass -File .\scripts\preflight.ps1`, optionally confirm the fixed port with `npm.cmd run check:port`, then start the site with `npm.cmd run dev -- --host`.
6. If the user wants background automation, use [references/windows-ops.md](references/windows-ops.md) to register the watcher as a scheduled task.
7. For teammate installation of this skill, prefer [scripts/install-local-skill.ps1](scripts/install-local-skill.ps1). It writes `.local/install-manifest.json` so environment-specific paths survive future updates.
8. If the teammate wants skill auto-update, use [scripts/register-skill-auto-update.ps1](scripts/register-skill-auto-update.ps1). The updater must read the local manifest, back up the existing skill, validate the candidate update, and preserve the existing skill on failure.
9. When maintaining the reusable skill itself, use [references/maintenance.md](references/maintenance.md) and run [scripts/self-test.ps1](scripts/self-test.ps1) before reporting the packaging update as complete.

## Required Behaviors

- Discover project folders dynamically from the configured projects root.
- Mirror Markdown and artifact files into `src/content/docs/<slug>/`.
- Generate a hidden project `index.mdx` preview page per project.
- Normalize Markdown text to UTF-8 during collection and prefer valid Korean decoding when source files are CP949/EUC-KR.
- Avoid deleting `.astro` during sync.
- Keep local preview update success separate from GitHub push success unless the user explicitly wants strict remote-delivery failure handling.
- On Windows, do not rely on renaming a live destination directory during sync. Build into a temp directory outside `src/content/docs`, copy into the destination, then prune removed files.
- Copy non-Markdown assets before Markdown files so image and PDF references are already present when Astro re-imports updated docs.
- Keep preview sync robust for add, update, delete, and project-folder rename cases.
- If older temp-dir logic was previously used, document that one manual `.astro` clear and dev-server restart may be needed to flush stale `.__sync__` imports.
- Add a runtime preflight path so config, CSS, collect, and build regressions are checked before treating operational changes as complete.
- Install the skill with a local `.local/install-manifest.json` when distributing it to teammates.
- Preserve `.local/install-manifest.json` during updates so customized B-environment paths are not overwritten by shared A-environment defaults.
- Automatic skill updates must be safe-by-default: pull latest shared content, stage to a temp folder, validate, back up the existing local skill, then replace only after validation succeeds.

## Resources

- Architecture and file responsibilities: [references/blueprint.md](references/blueprint.md)
- Windows setup and operations: [references/windows-ops.md](references/windows-ops.md)
- Maintenance and anti-regression workflow: [references/maintenance.md](references/maintenance.md)
- Local install script: [scripts/install-local-skill.ps1](scripts/install-local-skill.ps1)
- Local update script: [scripts/update-local-skill.ps1](scripts/update-local-skill.ps1)
- Auto-update registration script: [scripts/register-skill-auto-update.ps1](scripts/register-skill-auto-update.ps1)
- Ready-to-copy templates: [assets/templates](assets/templates)
