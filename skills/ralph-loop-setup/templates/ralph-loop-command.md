---
description: Start an autonomous Ralph loop for iterative development
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, TodoWrite
argument-hint: "<task>" | --next [--same-session] [--screenshots] [--branch NAME] [--max-iterations N] [--verbose] [--monitor] [--dry-run]
---

# Ralph Loop - Autonomous Development

Start an autonomous iteration loop that continues until the task is complete or max iterations is reached.

## Two Modes

**Fresh-Context (default for `--next`):** External bash script spawns new Claude session each iteration. Each iteration starts clean - no context pollution, failures evaporate. The true Ralph pattern.

**Same-Session (`--same-session` or single-task):** Stop hook blocks exit and re-prompts in same Claude session. Good for bounded single tasks under 20 iterations where conversation context helps.

## Arguments

- `$ARGUMENTS` - The task description OR flags
- `--next` - Auto-pick the next failing task from prd.json (enables multi-task mode, uses fresh-context by default)
- `--same-session` - Use same-session mode instead of fresh-context (opt-in for --next)
- `--screenshots` - Capture visual screenshots via Playwright MCP for UI regression review (advisory, non-blocking)
- `--branch NAME` - Create/checkout branch before starting (e.g., `ralph/backlog` or `feature/task-name`)
- `--max-iterations N` - Maximum iterations (default: 50)
- `--verbose` or `-v` - Enable detailed output (timing, last 10 lines of each iteration)
- `--monitor` or `-m` - Auto-open status dashboard in new Terminal window (macOS)
- `--completion-promise TEXT` - Completion signal (default: COMPLETE)
- `--dry-run` - Preview the prompt without starting the loop

## Usage Examples

```bash
# Single task, same-session (default for single tasks)
/ralph-loop "Fix all TypeScript errors" --max-iterations 20

# Multi-task, fresh-context (default for --next)
/ralph-loop --next
/ralph-loop --next --max-iterations 100

# Multi-task with verbose output
/ralph-loop --next --verbose

# Multi-task with auto-opened monitor window (macOS)
/ralph-loop --next --monitor

# Multi-task with verbose + monitor (recommended)
/ralph-loop --next --verbose --monitor

# Multi-task, same-session (opt-in)
/ralph-loop --next --same-session

# With visual screenshots for UI regression review
/ralph-loop --next --screenshots

# Work on a separate branch
/ralph-loop --next --branch ralph/backlog-cleanup

# Preview what would run
/ralph-loop --next --dry-run
```

## Instructions

<instruction>
You are starting a Ralph loop - an autonomous development cycle.

**Step 1: Parse Arguments**

Extract from `$ARGUMENTS`:
- `--next` flag: If present, auto-pick task from prd.json (uses fresh-context by default)
- `--same-session` flag: If present WITH --next, use same-session mode instead of fresh-context
- `--verbose` or `-v` flag: If present, enable detailed output
- `--monitor` or `-m` flag: If present, auto-open status dashboard in new Terminal
- `--screenshots` flag: If present, capture visual screenshots via Playwright MCP
- `--branch NAME`: If present, extract the branch name (value after --branch)
- `--dry-run` flag: If present, output prompt and stop (don't create state file)
- `--max-iterations N`: Extract value or default to 50
- `--completion-promise TEXT`: Extract value or default to "COMPLETE"
- Task: Everything else (if not using --next)

**Step 1.5: Handle Mode Selection**

Determine which mode to use:
- If `--next` flag is present AND `--same-session` is NOT present: Use **fresh-context** (default for multi-task)
- If `--next` flag is present AND `--same-session` IS present: Use **same-session** (opt-in)
- If no `--next` flag (single task): Use **same-session** (default for single tasks)

**For fresh-context mode:**
1. Build the command: `./scripts/ralph/ralph.sh`
2. Add `--max-iterations N` if specified
3. Add `--branch NAME` if specified
4. Add `--verbose` if verbose flag is present
5. Add `--monitor` if monitor flag is present
6. Add `--screenshot` if screenshots flag is present
7. Output: "Starting fresh-context Ralph loop (each iteration gets clean context)..."
8. If NOT using --monitor, output: "Monitor with: ./scripts/ralph/ralph-status.sh --watch"
9. Run the command using Bash **with `run_in_background: true`** - this prevents the timeout indicator in Claude Code UI
10. The external script will handle everything in the background

**Important:** Fresh-context mode launches an external bash script that spawns new Claude sessions. Use `run_in_background: true` when calling the Bash tool so the script runs in the background without blocking. Monitor progress with `./scripts/ralph/ralph-status.sh --watch` or the auto-opened monitor window. Do NOT create a state file for fresh mode.

**For same-session mode:** Continue to Step 2 below.

**Step 2: Handle Branch**

Determine the branch to use (in priority order):
1. `--branch` flag value (if provided)
2. `branchName` from prd.json (if present at top level)
3. Stay on current branch (if neither specified)

If a branch is determined:
1. Check if the branch exists: `git branch --list <branch-name>`
2. If branch exists: `git checkout <branch-name>`
3. If branch doesn't exist: `git checkout -b <branch-name>`
4. Confirm branch switch was successful

If `--dry-run` is also set, just report what branch would be used without switching.

**Step 3: Determine the Task**

If `--next` flag is present:
1. Read `plans/prd.json`
2. Find the first feature where `passes: false`, ordered by priority (high > medium > low)
3. Extract:
   - `id` and `title` for the task description
   - `acceptance_criteria` for success conditions
   - `plan_file` path if specified (read its content)
   - `github_issue` number if present
4. If NO failing tasks remain, output: "All tasks in prd.json are complete! Nothing to do."

If task provided directly (no --next):
- Use the provided task description
- Check prd.json for matching task to get acceptance criteria

**Step 4: Build Rich Context**

Read and include:
1. **Task details** from prd.json (id, title, acceptance_criteria)
2. **Plan file content** if `plan_file` is specified
3. **Last 20 lines of progress.md** for cross-session context
4. **GitHub issue reference** if present

**Step 4.5: Read Guardrails**

Read `plans/guardrails.md` if it exists. This file contains learned constraints ("signs") from previous iterations that prevent repeated failures. Include guardrails content in the state file so they're visible during work.

**Step 5: Handle --dry-run**

If `--dry-run` is present:
1. Output the full prompt that WOULD be used
2. Show which task would be picked
3. Show the acceptance criteria
4. Show which branch would be used (if --branch specified)
5. DO NOT create the state file
6. Stop here

**Step 6: Create State File**

Create `.claude/ralph-loop.local.md` with **EXACT format** (YAML frontmatter with `---` delimiters required):

```markdown
---
active: true
iteration: 0
max_iterations: [extracted or 50]
completion_promise: "[extracted or COMPLETE]"
mode: "[next or single]"
branch: "[branch name or empty string if not specified]"
screenshots: [true if --screenshots flag present, false otherwise]
started_at: "[current ISO timestamp]"
---

## Current Task

**ID:** [task id from prd.json]
**Title:** [task title]
**GitHub Issue:** #[number] (if present)

### Acceptance Criteria
- [ ] [criterion 1]
- [ ] [criterion 2]
...

### Plan File Content (if applicable)
[Content from plan_file if specified]

---

## Guardrails (Signs)

[Include content from plans/guardrails.md if it exists]

---

## Context

### Recent Progress (last 20 lines of progress.md)
[Include last 20 lines]

---

## Instructions

1. Work on the current task until ALL acceptance criteria are met
2. Run verification command after significant changes
3. Commit working changes incrementally (include `Fixes #[github_issue]` in commit message if task has github_issue)
4. Update plans/progress.md with your progress

### When Current Task is Complete:
1. **COMMIT your changes** with message format: `feat: [task-id] - description\n\nFixes #[github_issue]` (if github_issue is present)
2. Update prd.json: Set `passes: true` and add `completed_at: "YYYY-MM-DD"`
3. Check if more `passes: false` tasks remain in prd.json
4. If MORE tasks remain: End normally (stop hook will continue with next task)
5. If ALL tasks pass:
   - If `screenshots: true` in state file, use Playwright MCP to capture final screenshots of key pages
   - Output `<promise>COMPLETE</promise>`

**IMPORTANT:** Only output the completion promise when ALL prd.json tasks pass, not just the current one.

### Screenshots (when --screenshots flag used)
Use Playwright MCP to capture visual screenshots for UI regression review:
1. Navigate to key pages using `browser_navigate`
2. Capture screenshots using `browser_take_screenshot` with descriptive filenames
3. Screenshots are advisory - tests passed, but visual review recommended

**Step 7: Begin Working**

1. Read the context files (progress.md, guardrails.md, prd.json, plan_file if specified)
2. Start implementing the task
3. Run verification to check your work
4. Commit when tests pass
5. Follow the completion logic above

**Multi-Task Flow:**
- When you complete a task, update prd.json with `passes: true`
- Check if there are remaining `passes: false` tasks
- If yes, just end normally - the stop hook will pick up the next task
- Only output `<promise>COMPLETE</promise>` when prd.json has no remaining failing tasks

**Important Reminders:**
- Do NOT output the completion promise until ALL tasks in prd.json pass
- Each iteration should make meaningful progress
- Update progress.md with learnings after each task
- The stop hook runs verification automatically between iterations
</instruction>
