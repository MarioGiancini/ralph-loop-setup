---
description: Cancel the active Ralph loop (both modes)
allowed-tools: Bash, Read
argument-hint: [--force]
---

# Cancel Ralph Loop

Stop any running Ralph loop - works for both fresh-context and same-session modes.

## Arguments

- `$ARGUMENTS` - Optional flags
- `--force` or `-f` - Kill processes and remove state files without prompting

## Instructions

<instruction>
Cancel/stop the active Ralph loop using the unified stop script:

**Step 1: Check current state**

Run the stop script in check mode first (no --force):

```bash
./scripts/ralph/ralph-stop.sh
```

This will show:
- Any running `ralph.sh` processes (fresh-context mode)
- Any Claude subprocesses spawned by Ralph
- Any same-session state files

**Step 2: Stop if requested**

If `--force` is in `$ARGUMENTS`, or if user confirms:

```bash
./scripts/ralph/ralph-stop.sh --force
```

This will:
1. Kill any `ralph.sh` processes
2. Kill any Claude subprocesses from Ralph
3. Remove `.claude/ralph-loop.local.md` state file
4. Remove `.claude/ralph-status.local.json` status file

**Step 3: Report status**

Tell the user what was found and stopped:
- If fresh-context loop was running, mention they may need to close the monitor pane manually
- If same-session loop was running, confirm state file was removed
- If nothing was found, confirm no active loop

**Note:** The monitor pane (if open) is just a watcher - closing it doesn't stop the loop, and stopping the loop doesn't close the monitor. User should close it manually with Cmd+W or by typing `exit`.
</instruction>
