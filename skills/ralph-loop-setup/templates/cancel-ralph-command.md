---
description: Cancel the active Ralph loop
allowed-tools: Bash, Read
---

# Cancel Ralph Loop

Stop the currently running Ralph loop by removing the state file.

## Instructions

<instruction>
Cancel the active Ralph loop:

1. Check if `.claude/ralph-loop.local.md` exists
2. If it exists:
   - Read it to show current iteration status
   - Delete the file
   - Confirm cancellation
3. If it doesn't exist:
   - Inform user no active loop was found

```bash
# Check and remove state file
if [ -f ".claude/ralph-loop.local.md" ]; then
  cat .claude/ralph-loop.local.md
  rm .claude/ralph-loop.local.md
  echo "Ralph loop cancelled."
else
  echo "No active Ralph loop found."
fi
```

Report the final status to the user.
</instruction>
