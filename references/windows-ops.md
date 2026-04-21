# Windows Ops

## Local Run

```powershell
cd <hub-repo>
$env:ASTRO_TELEMETRY_DISABLED='1'
npm.cmd run collect
npm.cmd run dev -- --host
```

## One-Time Sync

```powershell
cd <hub-repo>
powershell -ExecutionPolicy Bypass -File .\scripts\sync-docs.ps1
```

## Watcher

```powershell
cd <hub-repo>
powershell -ExecutionPolicy Bypass -File .\scripts\watch-docs.ps1
```

## Scheduled Task

Recommended task name: `__TASK_NAME__`

Typical registration command:

```powershell
$repoRoot = '<hub-repo>'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$repoRoot\scripts\launch-watch-docs.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName '__TASK_NAME__' -Action $action -Trigger $trigger -Principal $principal
```

## Notes

- Use `npm.cmd` on Windows to avoid shell alias issues.
- Restart the dev server after large structural changes if the browser still shows stale content.
- If a watcher task is already running, `launch-watch-docs.ps1` should exit cleanly because of its mutex.
