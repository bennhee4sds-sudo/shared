# Maintenance

## Canonical Source Rule

Maintain one working hub repository as the canonical implementation.

Recommended approach:
- treat the live hub repo as the implementation source of truth
- treat the skill templates as the reusable packaging of that implementation
- do not let the templates drift ahead of the canonical repo without validating both

## Sync Rule

When a fix is first discovered in a working hub:
1. apply the fix in the canonical hub repo
2. confirm the fix works there
3. copy the matching changes into the skill templates
4. run the skill self-test
5. update README or references if the install or ops flow changed
6. sync the same final state to the local skill path and the shared GitHub repo

## Required Self-Test

Use [scripts/self-test.ps1](../scripts/self-test.ps1) before treating a reusable skill update as complete.

The self-test is meant to verify:
- the skill can be structurally validated when the validator is available
- a fresh test hub can be assembled from the templates
- `powershell -ExecutionPolicy Bypass -File .\scripts\preflight.ps1` succeeds
- mirrored project content is actually produced

Typical command:

```powershell
cd <skill-repo>
powershell -ExecutionPolicy Bypass -File .\scripts\self-test.ps1 `
  -CanonicalHubRepo C:\Users\<user>\Projects\docs-hub `
  -ProjectsRoot C:\Users\<user>\Projects
```

## Release Checklist

Before reporting a reusable skill update as complete:
- confirm the canonical hub repo contains the intended fix
- sync the matching change into the templates
- run `self-test.ps1`
- confirm local runtime sync and GitHub push behavior are not incorrectly coupled when that separation matters
- confirm the README still matches the actual install and usage flow
- sync the updated skill to the local Codex skill path
- sync the updated skill to the shared GitHub repository

## Why This Matters

These steps reduce the most common failure modes:
- fixing only the live hub but not the templates
- fixing only the templates but not the live implementation
- passing structural validation while install or runtime still fails
- breaking Windows path handling or Astro live preview behavior without noticing
