---
name: ralph-loop-setup
description: Sets up autonomous TDD loops at project level. Use when installing Ralph loops in projects, updating hooks based on latest practices, or troubleshooting loop behavior. Based on Ryan Carson's Ralph Wiggum technique.
allowed-tools: Bash, Read, Glob, Write, Edit
---

# Ralph Loop Setup Skill

Set up and maintain autonomous TDD loops for iterative development with verification feedback.

## When This Activates

- User asks to "set up Ralph" or "add autonomous loop" to a project
- User wants to update Ralph hooks based on latest practices
- Troubleshooting loop behavior (not iterating, verification failing)
- Setting up a new project for autonomous development

## What is Ralph?

The [Ralph Wiggum technique](https://ghuntley.com/ralph/) is an autonomous TDD workflow where Claude iteratively works on tasks until a verification command passes and a completion promise is detected.

**Key components:**
1. **Start Command** - Initializes loop with task and options
2. **Loop Mechanism** - Either stop hook (same-session) or external script (fresh-context)
3. **State File** - Tracks iteration count, completion promise
4. **Context Files** - `progress.md` for cross-session memory, `prd.json` for tasks, `guardrails.md` for learned constraints

## Two Architectural Modes

Ralph supports two fundamentally different loop architectures. **Fresh-context is the default for multi-task mode** because it follows the true Ralph pattern: deliberate rotation, not accidental compaction.

### Fresh-Context (Default for `--next`)

Uses an external bash script that spawns new Claude sessions each iteration.

```bash
/ralph-loop --next                          # Fresh-context by default
./scripts/ralph/ralph.sh --max-iterations 100
```

**Pros:** Each iteration starts clean, no context pollution, failures evaporate, true re-anchoring.
**Cons:** More complex setup, loses conversation context.
**Best for:** Multi-task backlogs, long runs (20+ iterations).

### Same-Session (Opt-In)

Uses Claude Code's stop hook to block exit and re-prompt within the same session.

```bash
/ralph-loop "Fix all TypeScript errors"    # Single task = same-session
/ralph-loop --next --same-session          # Multi-task with same-session (opt-in)
```

**Pros:** Simpler setup, works within Claude Code's native system, preserves conversation context.
**Cons:** Context accumulates, failed attempts stay in transcript.
**Best for:** Bounded single tasks, short runs (under 20 iterations).

This follows [Geoffrey Huntley's original vision](https://ghuntley.com/ralph/), [Gordon Mickel's flow-next](https://github.com/gmickel/gmickel-claude-marketplace), and [Agrim Singh's "ralph for idiots"](https://x.com/agrimsingh/status/2010412150918189210) insight that Anthropic's same-session pattern is "anti-ralph" because it accumulates context until it rots.

## Installation

To add Ralph loops to a project:

```bash
# From project root
/ralph-loop-setup
```

This creates:
- `.claude/commands/ralph-loop.md` - Start command (supports both modes)
- `.claude/commands/cancel-ralph.md` - Cancel command
- `.claude/hooks/stop-hook.sh` - Same-session verification hook
- `.claude/settings.json` - Hook registration (or updates existing)
- `scripts/ralph/ralph.sh` - Fresh-context external loop
- `scripts/ralph/snapshot.ts` - Visual snapshot script (optional)
- `scripts/ralph/snapshot-config.json` - Snapshot page configuration
- `plans/progress.md` - Cross-session context
- `plans/guardrails.md` - Learned constraints ("signs") that prevent repeated failures
- `plans/prd.json` - Task tracking

## Usage

Once installed:

```bash
# Single task, same-session (default for single tasks)
/ralph-loop "Fix all TypeScript errors" --max-iterations 20

# Multi-task, fresh-context (default for --next)
/ralph-loop --next
/ralph-loop --next --max-iterations 100

# Multi-task, same-session (opt-in)
/ralph-loop --next --same-session

# With visual snapshots for UI regression review
/ralph-loop --next --snapshots

# Work on a separate branch
/ralph-loop --next --branch ralph/backlog

# Preview without starting
/ralph-loop --next --dry-run

# Cancel active loop
/cancel-ralph

# Run external loop directly
./scripts/ralph/ralph.sh --max-iterations 100 --branch ralph/backlog
```

## Branch Handling Options

Ralph supports two ways to manage branches:

### Option 1: CLI Flag (per-run)

Specify branch when starting the loop:

```bash
/ralph-loop --next --branch ralph/backlog-cleanup
/ralph-loop "Fix bugs" --branch feature/bugfix
```

**Best for:** Ad-hoc runs, different branches per task batch.

### Option 2: prd.json branchName (per-batch)

Set `branchName` in prd.json for all tasks in that batch:

```json
{
  "branchName": "feature/my-feature",
  "features": [...]
}
```

Then just run:
```bash
/ralph-loop --next
```

Ralph will automatically checkout/create the branch from prd.json.

**Best for:** Consistent branch for a set of related tasks.

### Priority

If both are specified, `--branch` flag takes precedence over prd.json `branchName`.

## Guardrails (Signs)

Guardrails are learned constraints that prevent repeated failures. They persist in `plans/guardrails.md` and are read at the start of each iteration.

**Philosophy:** Progress should persist. Failures should evaporate.

### Seed Guardrails

The template includes seed signs that prevent common pitfalls:

- **SIGN-001: Verify Before Complete** - Run verification before outputting completion promise
- **SIGN-002: Check All Tasks Before Complete** - Re-read prd.json to confirm ALL tasks pass
- **SIGN-003: Document Learnings** - Update progress.md with patterns discovered
- **SIGN-004: Small Focused Changes** - Keep changes incremental

### Adding New Signs

When Ralph makes a repeated mistake, add a sign to prevent it:

```markdown
### SIGN-XXX: [Descriptive Name]
**Trigger:** [When this applies]
**Instruction:** [What to do instead]
**Reason:** [Why this matters]
**Added after:** [Iteration N / date when learned]
```

Signs are append-only. Mistakes evaporate, lessons accumulate.

## Visual Snapshots (UI Regression Review)

The `--snapshots` flag captures screenshots of key pages before and after Ralph loops complete. This helps catch UI/UX regressions that tests don't catch.

### How It Works

1. **Before:** Captures screenshots of configured pages when loop starts
2. **During:** Normal Ralph loop execution (no interruption)
3. **After:** Captures same pages when all tasks complete
4. **Output:** Paths to before/after directories for manual comparison

### Configuration

Edit `scripts/ralph/snapshot-config.json`:

```json
{
  "baseUrl": "http://localhost:3000",
  "viewport": { "width": 1280, "height": 800 },
  "outputDir": "scripts/ralph/snapshots",
  "pages": [
    { "name": "dashboard", "path": "/dashboard", "waitFor": "nav" },
    { "name": "settings", "path": "/settings", "delay": 500 }
  ]
}
```

**Page options:**
- `name` - Filename for the screenshot (required)
- `path` - URL path to capture (required)
- `selector` - CSS selector to capture specific element instead of viewport
- `waitFor` - CSS selector to wait for before capturing
- `delay` - Additional ms to wait after page load

### Usage

```bash
# Capture before/after snapshots
/ralph-loop --next --snapshots

# Run snapshot script directly
npx ts-node scripts/ralph/snapshot.ts before
npx ts-node scripts/ralph/snapshot.ts after --run-id 20260111-120000
```

### Output

Snapshots are stored in `scripts/ralph/snapshots/{run-id}/`:
```
scripts/ralph/snapshots/20260111-120000/
├── before/
│   ├── dashboard.png
│   ├── settings.png
│   └── manifest.json
└── after/
    ├── dashboard.png
    ├── settings.png
    └── manifest.json
```

**Important:** Snapshots are advisory, non-blocking. Tests passing is the gate; visual review is recommended but doesn't block completion.

## Project Requirements

Ralph loops work best with projects that have:

1. **Verification command** - A single command that validates code quality
   - Node/Next.js: `pnpm verify` (test + tsc + lint)
   - Python: `make check` or `pytest && mypy && ruff`
   - Go: `go test ./... && go vet ./...`

2. **Clear acceptance criteria** - Tasks with measurable completion

3. **Test coverage** - Automated tests for feedback

## Customization

### Verification Command

Edit `.claude/hooks/stop-hook.sh`:

```bash
# Change this line to your project's verification command
VERIFY_OUTPUT=$(pnpm verify 2>&1) || true
```

### Context Files Location

Default location is `plans/`. Edit the start command to change:

```markdown
# In .claude/commands/ralph-loop.md
1. **Read plans/progress.md** → Change to your path
2. **Check plans/prd.json** → Change to your path
```

## Templates

See the templates directory for:
- [ralph-loop-command.md](templates/ralph-loop-command.md) - Start command (both modes)
- [cancel-ralph-command.md](templates/cancel-ralph-command.md) - Cancel command
- [ralph-fresh.sh](templates/ralph-fresh.sh) - External loop script
- [prd-template.json](templates/prd-template.json) - Task structure with branchName
- [progress-template.md](templates/progress-template.md) - Session notes

## Troubleshooting

### Loop not iterating
1. Check if `.claude/settings.json` has correct hook registration
2. Verify hook format is v2.1: `{"type": "command", "command": "..."}`
3. Check if state file `.claude/ralph-loop.local.md` exists

### Verification not running
1. Ensure hook is executable: `chmod +x .claude/hooks/stop-hook.sh`
2. Check if verification command works standalone
3. Look for `jq` dependency (required for JSON output)

### Premature completion
1. Verify completion promise format: `<promise>COMPLETE</promise>`
2. Check transcript for promise detection
3. Increase max iterations if needed

### Branch not switching
1. Check `--branch` flag syntax: `--branch branch-name` (no `=`)
2. Verify prd.json has `branchName` at top level (not inside tasks)
3. Ensure no uncommitted changes blocking checkout

## Reference

- [Geoffrey Huntley's Original Ralph](https://ghuntley.com/ralph/) - The canonical origin story
- [Agrim Singh's "ralph for idiots"](https://x.com/agrimsingh/status/2010412150918189210) - Fresh-context as the true pattern
- [Ryan Carson's Guide](https://x.com/ryancarson/status/2008548371712135632) - Step-by-step tutorial
- [snarktank/ralph](https://github.com/snarktank/ralph) - Ryan Carson's implementation
- [Gordon Mickel's flow-next](https://github.com/gmickel/gmickel-claude-marketplace) - Fresh-context critique
- [frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code) - Circuit breaker enhancements
- [Anthropic Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

## Maintenance

See [maintenance.md](maintenance.md) for on-demand cleanup tasks:
- **Progress log cleanup** - Archive and truncate `progress.md` when it gets long
- **PRD cleanup** - Archive completed tasks from `prd.json`
- **Run logs cleanup** - Remove old fresh-context run directories

## Related Skills

- **managing-context** - Handoffs for manual session continuity
- **frontmatter-scanner** - Scanning files for context
