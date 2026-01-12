# Ralph Loop Setup

A Claude Code plugin for installing autonomous TDD workflows (Ralph loops) into any project.

Based on [Geoffrey Huntley's Ralph Wiggum technique](https://ghuntley.com/ralph/)—a continuous loop pattern where Claude iteratively works on tasks with test/lint/type feedback until completion.

## Features

- **Two modes**: Fresh-context (default for multi-task) and same-session (opt-in)
- **Guardrails**: Learned constraints that prevent repeated failures
- **Visual snapshots**: Optional before/after screenshots for UI regression review
- **Multi-task support**: Auto-pick next failing task from prd.json
- **Project-specific**: Configuration lives in your repo, not global settings

## Installation

### Option 1: Plugin Install (Recommended)

```bash
/plugin install MarioGiancini/ralph-loop-setup
```

### Option 2: Git Clone

```bash
# Clone to your Claude Code user skills directory
git clone https://github.com/MarioGiancini/ralph-loop-setup.git ~/.claude/skills/ralph-loop-setup
```

### Updating

```bash
# If installed via plugin
/plugin update ralph-loop-setup

# If installed via git clone
cd ~/.claude/skills/ralph-loop-setup && git pull
```

## Usage

Once installed, you can install Ralph into any project:

```
Install Ralph loops in this project. Verification command is `pnpm verify`.
```

Or be more specific:

```
Install Ralph loops with:
- Verification: pnpm test
- Branch: ralph/feature-work
- Max iterations: 30
```

The skill will create:
- `.claude/commands/ralph-loop.md` - Start command
- `.claude/commands/cancel-ralph.md` - Cancel command
- `.claude/hooks/stop-hook.sh` - Same-session verification hook
- `scripts/ralph/ralph.sh` - Fresh-context external loop
- `plans/prd.json` - Task tracking
- `plans/progress.md` - Cross-session learnings
- `plans/guardrails.md` - Learned constraints

## Commands After Installation

```bash
# Single task, same-session (default for single tasks)
/ralph-loop "Fix all TypeScript errors" --max-iterations 20

# Multi-task, fresh-context (default for --next)
/ralph-loop --next

# Multi-task, same-session (opt-in when context helps)
/ralph-loop --next --same-session

# With visual snapshots for UI regression review
/ralph-loop --next --snapshots

# Work on a separate branch
/ralph-loop --next --branch ralph/backlog

# Preview without starting
/ralph-loop --next --dry-run

# Cancel active loop
/cancel-ralph
```

## How It Works

### Fresh-Context Mode (Default for `--next`)

External bash loop spawns new Claude session each iteration:
- Each iteration starts with clean context
- Failed attempts don't pollute future iterations
- True "re-anchoring" from source files
- **Requires `--dangerously-skip-permissions`** (handled by the script)

### Same-Session Mode (Default for single tasks, opt-in with `--same-session`)

Stop hook blocks exit and re-prompts in same session:
- Simpler implementation
- Can leverage conversation context
- Good for bounded tasks under 20 iterations

### Guardrails (Signs)

Learned constraints that prevent repeated failures. Each iteration reads and follows them.

```markdown
### SIGN-001: Verify Before Complete
**Trigger:** About to output completion promise
**Instruction:** Run verification and confirm it passes first

### SIGN-002: Check All Tasks Before Complete
**Trigger:** Completing a task in multi-task mode
**Instruction:** Re-read prd.json. Only output completion when ALL pass.
```

Add project-specific signs as you encounter failure patterns.

## Requirements

- Claude Code CLI
- Bash (for fresh-context mode)
- `jq` (for state parsing)
- Your project's test/lint toolchain

## Philosophy

> "Progress should persist. Failures should evaporate."

- **Fresh context** prevents drift from accumulated failures
- **Guardrails** encode lessons from past iterations
- **Re-anchoring** ensures each iteration reads the truth from files

## Credits

- [Geoffrey Huntley](https://ghuntley.com/ralph/) - Original Ralph pattern
- [Ryan Carson](https://github.com/snarktank/ralph) - snarktank/ralph implementation
- [Gordon Mickel](https://github.com/gmickel/gmickel-claude-marketplace) - flow-next architecture
- [Agrim Singh](https://x.com/agrimsingh/status/2010412150918189210) - Guardrails pattern and "progress persists, failures evaporate" philosophy
- [Anthropic](https://docs.anthropic.com/en/docs/claude-code) - Long-running agent guidance

## License

MIT
