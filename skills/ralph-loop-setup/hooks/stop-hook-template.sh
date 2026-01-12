#!/bin/bash
# Ralph Wiggum Stop Hook Template
# Intercepts exit, runs verification, and re-prompts if loop is active
#
# CUSTOMIZE: Change VERIFY_COMMAND for your project
#
# Based on:
# - Ryan Carson's snarktank/ralph
# - Anthropic's long-running agent patterns
# - frankbria/ralph-claude-code enhancements

set -euo pipefail

# ============================================
# CUSTOMIZATION - Edit these for your project
# ============================================

# Verification command - change to match your project
# Examples:
#   Node/Next.js: "pnpm verify" or "npm run test && npm run lint"
#   Python: "pytest && mypy . && ruff check ."
#   Go: "go test ./... && go vet ./..."
VERIFY_COMMAND="pnpm verify"

# Context files location (relative to project root)
PROGRESS_FILE="plans/progress.md"
PRD_FILE="plans/prd.json"
GUARDRAILS_FILE="plans/guardrails.md"

# ============================================
# Core Logic - Usually no changes needed below
# ============================================

# State file location
RALPH_STATE_FILE=".claude/ralph-loop.local.md"

# Read hook input from stdin (JSON with transcript_path)
HOOK_INPUT=$(cat)

# If no state file, allow normal exit
if [ ! -f "$RALPH_STATE_FILE" ]; then
  exit 0
fi

# Parse state file (YAML frontmatter)
ACTIVE=$(grep "^active:" "$RALPH_STATE_FILE" | cut -d' ' -f2 || echo "false")
ITERATION=$(grep "^iteration:" "$RALPH_STATE_FILE" | cut -d' ' -f2 || echo "0")
MAX_ITERATIONS=$(grep "^max_iterations:" "$RALPH_STATE_FILE" | cut -d' ' -f2 || echo "50")
COMPLETION_PROMISE=$(grep "^completion_promise:" "$RALPH_STATE_FILE" | cut -d' ' -f2- | tr -d '"' || echo "COMPLETE")

# Validate numeric fields
if ! [[ "$ITERATION" =~ ^[0-9]+$ ]]; then
  ITERATION=0
fi
if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  MAX_ITERATIONS=50
fi

# If not active, allow exit
if [ "$ACTIVE" != "true" ]; then
  exit 0
fi

# Get transcript path to check last output
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

# Check if we've hit max iterations
NEXT_ITERATION=$((ITERATION + 1))
if [ "$NEXT_ITERATION" -gt "$MAX_ITERATIONS" ]; then
  echo "Warning: Max iterations ($MAX_ITERATIONS) reached. Stopping loop." >&2
  rm -f "$RALPH_STATE_FILE"
  exit 0
fi

# Check for completion promise in last output
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # Get last assistant message
  LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 || echo "")
  if [ -n "$LAST_LINE" ]; then
    LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
      .message.content |
      map(select(.type == "text")) |
      map(.text) |
      join("\n")
    ' 2>/dev/null || echo "")

    # Extract promise text from <promise>...</promise> tags
    PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/\1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

    # Check if promise matches completion promise
    if [ -n "$PROMISE_TEXT" ] && [ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]; then
      echo "Completion promise detected: $PROMISE_TEXT" >&2
      rm -f "$RALPH_STATE_FILE"
      exit 0
    fi
  fi
fi

# Update iteration count in state file
TEMP_FILE=$(mktemp)
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# Run verification and capture output
echo "" >&2
echo "=================================================================" >&2
echo "RALPH LOOP - Iteration $NEXT_ITERATION of $MAX_ITERATIONS" >&2
echo "=================================================================" >&2
echo "" >&2
echo "Running verification ($VERIFY_COMMAND)..." >&2
VERIFY_OUTPUT=$($VERIFY_COMMAND 2>&1) || true
VERIFY_EXIT_CODE=$?

# Get the original task from state file (after the second ---)
TASK=$(awk '/^## Task$/,0' "$RALPH_STATE_FILE" | tail -n +2)

# Read guardrails if they exist
GUARDRAILS_CONTEXT=""
if [ -f "$GUARDRAILS_FILE" ]; then
  GUARDRAILS_CONTEXT=$(cat "$GUARDRAILS_FILE" 2>/dev/null || echo "")
fi

# Build the continuation prompt based on verification result
if [ $VERIFY_EXIT_CODE -eq 0 ]; then
  echo "Verification passed!" >&2
  PROMPT="# Ralph Loop - Iteration $NEXT_ITERATION of $MAX_ITERATIONS

## Verification Status
**PASSED** - All tests, types, and lint checks passed.

## Guardrails (Signs)
Follow these learned constraints:

$GUARDRAILS_CONTEXT

## Your Task
$TASK

## Instructions
1. Review what was accomplished in the previous iteration
2. Check $PROGRESS_FILE for context
3. Follow the guardrails above - they prevent repeated mistakes
4. Continue working on the task
5. If genuinely complete (all acceptance criteria met), re-read prd.json to confirm ALL tasks pass, then output:
   \`<promise>$COMPLETION_PROMISE</promise>\`
6. Otherwise, make more progress and end normally

**Remember:** Only output the completion promise when ALL tasks in prd.json are complete."
else
  echo "Verification FAILED (exit code: $VERIFY_EXIT_CODE)" >&2
  PROMPT="# Ralph Loop - Iteration $NEXT_ITERATION of $MAX_ITERATIONS

## Verification Status
**FAILED** - Fix these issues before continuing:

\`\`\`
$VERIFY_OUTPUT
\`\`\`

## Guardrails (Signs)
Follow these learned constraints:

$GUARDRAILS_CONTEXT

## Your Task
$TASK

## Instructions
1. Fix the verification errors above
2. Run \`$VERIFY_COMMAND\` to check your fixes
3. Follow the guardrails above - they prevent repeated mistakes
4. Once verification passes, continue with the task
5. Do NOT output the completion promise until verification passes AND all tasks in prd.json are complete

**Priority:** Fix verification errors first, then continue with the task."
fi

SYSTEM_MSG="Ralph loop iteration $NEXT_ITERATION/$MAX_ITERATIONS. Verification: $([ $VERIFY_EXIT_CODE -eq 0 ] && echo 'PASSED' || echo 'FAILED')"

# Output JSON to block exit and continue
jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
