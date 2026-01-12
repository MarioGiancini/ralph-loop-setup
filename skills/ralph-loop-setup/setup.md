# Ralph Loop Setup Guide

How to add autonomous TDD loops to your project.

## Prerequisites

1. **Claude Code** installed and working
2. **jq** installed for JSON processing (`brew install jq` on macOS)
3. **Verification command** - A single command that validates code quality

## Quick Setup

The easiest way is to ask Claude to install Ralph for you:

```
Install Ralph loops in this project. Verification command is `pnpm test`.
```

Claude will read the templates from this skill and create all necessary files.

### Manual Setup

If you prefer manual setup, from your project root:

```bash
# 1. Create directories
mkdir -p .claude/commands .claude/hooks plans scripts/ralph

# 2. Copy templates from the plugin
# (Templates are in ~/.claude/skills/ralph-loop-setup/skills/ralph-loop-setup/templates/)

# 3. Configure settings.json (see below)
```

## Settings Configuration

Create or update `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/stop-hook.sh"
          }
        ]
      }
    ]
  }
}
```

**Important:** Use v2.1 format with `type` and `command` properties.

## Customization

### 1. Verification Command

Edit `.claude/hooks/stop-hook.sh` and change `VERIFY_COMMAND`:

```bash
# Node/Next.js
VERIFY_COMMAND="pnpm verify"  # or "npm test && npm run lint"

# Python
VERIFY_COMMAND="pytest && mypy . && ruff check ."

# Go
VERIFY_COMMAND="go test ./... && go vet ./..."

# Rust
VERIFY_COMMAND="cargo test && cargo clippy"
```

### 2. Context Files Location

Edit the paths in `stop-hook.sh`:

```bash
PROGRESS_FILE="plans/progress.txt"  # Change as needed
PRD_FILE="plans/prd.json"           # Change as needed
```

### 3. Start Command

Edit `.claude/commands/ralph-loop.md` to match your context file paths:

```markdown
1. **Read plans/progress.txt** → Change to your path
2. **Check plans/prd.json** → Change to your path
```

## Gitignore

Add the state file to `.gitignore`:

```
# Ralph loop state (local only)
.claude/ralph-loop.local.md
```

## Verification

Test your setup:

```bash
# 1. Start Claude in your project
cd your-project
claude

# 2. Try the command
/ralph-loop "Test setup - fix any lint errors"

# 3. Check for iteration output
# Should see "RALPH LOOP - Iteration 1 of 50"

# 4. Cancel if working
/cancel-ralph
```

## Troubleshooting

### "Unknown command: ralph-loop"

- Ensure `.claude/commands/ralph-loop.md` exists
- Check file has correct YAML frontmatter
- Restart Claude session

### Hook not running

- Check `.claude/settings.json` format (v2.1 required)
- Ensure hook is executable: `chmod +x .claude/hooks/stop-hook.sh`
- Look for errors in stderr output

### Loop exits immediately

- Check if completion promise is being output prematurely
- Verify state file `.claude/ralph-loop.local.md` was created
- Check `active: true` in state file

### Verification command fails

- Test command manually: `pnpm verify` (or your command)
- Check for missing dependencies
- Ensure you're in the correct directory

## Example Projects

### Mission Control (Next.js 16)

```bash
VERIFY_COMMAND="pnpm verify"  # runs: pnpm test && pnpm tsc && pnpm lint
PROGRESS_FILE="plans/progress.txt"
PRD_FILE="plans/prd.json"
```

### Python Project

```bash
VERIFY_COMMAND="make check"  # or: pytest && mypy . && ruff check .
PROGRESS_FILE="docs/progress.md"
PRD_FILE="tasks.json"
```

## Files Reference

| File | Purpose | Committed |
|------|---------|-----------|
| `.claude/commands/ralph-loop.md` | Start command | Yes |
| `.claude/commands/cancel-ralph.md` | Cancel command | Yes |
| `.claude/hooks/stop-hook.sh` | Verification hook | Yes |
| `.claude/settings.json` | Hook registration | Yes |
| `.claude/ralph-loop.local.md` | Active loop state | No (gitignored) |
| `plans/progress.txt` | Cross-session context | Yes |
| `plans/prd.json` | Task tracking | Yes |
