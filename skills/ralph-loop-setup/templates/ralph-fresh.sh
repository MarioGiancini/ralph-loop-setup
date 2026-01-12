#!/bin/bash
# Ralph Loop - Fresh Context Mode
# External bash loop that spawns fresh Claude sessions for each iteration
#
# This follows Geoffrey Huntley's original vision:
# - Fresh context per iteration (no accumulated transcript)
# - File I/O as state (prd.json, progress.md, guardrails.md)
# - Deterministic setup (same files loaded every iteration)
# - Guardrails (signs) prevent repeated failures
#
# Usage:
#   ./scripts/ralph/ralph.sh [--max-iterations N] [--branch NAME]
#
# Based on:
# - Geoffrey Huntley's original Ralph pattern
# - Gordon Mickel's flow-next architecture
# - Anthropic's long-running agent guidance

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
PRD_FILE="plans/prd.json"
PROGRESS_FILE="plans/progress.md"
GUARDRAILS_FILE="plans/guardrails.md"

# ============================================
# Configuration (usually no changes needed)
# ============================================

MAX_ITERATIONS=50
BRANCH=""
STATE_FILE=".claude/ralph-state.local.md"
RUNS_DIR="scripts/ralph/runs"

# ============================================
# Parse Arguments
# ============================================

while [[ $# -gt 0 ]]; do
  case $1 in
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: ./ralph.sh [--max-iterations N] [--branch NAME]"
      exit 1
      ;;
  esac
done

# ============================================
# Setup
# ============================================

# Create runs directory for this session
RUN_ID=$(date +%Y%m%d-%H%M%S)
RUN_DIR="$RUNS_DIR/$RUN_ID"
mkdir -p "$RUN_DIR"

echo "=============================================="
echo "Ralph Loop - Fresh Context Mode"
echo "=============================================="
echo "Run ID: $RUN_ID"
echo "Max Iterations: $MAX_ITERATIONS"
echo "Branch: ${BRANCH:-<current>}"
echo "Verify: $VERIFY_COMMAND"
echo "=============================================="
echo ""

# Handle branch if specified
if [ -n "$BRANCH" ]; then
  if git branch --list "$BRANCH" | grep -q "$BRANCH"; then
    git checkout "$BRANCH"
  else
    git checkout -b "$BRANCH"
  fi
  echo "Working on branch: $BRANCH"
fi

# Check if there are tasks to work on
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: $PRD_FILE not found"
  exit 1
fi

REMAINING_TASKS=$(jq '[.features[] | select(.passes == false)] | length' "$PRD_FILE")
if [ "$REMAINING_TASKS" -eq 0 ]; then
  echo "All tasks in prd.json are already complete!"
  exit 0
fi

echo "Found $REMAINING_TASKS pending tasks"
echo ""

# ============================================
# Main Loop
# ============================================

ITERATION=0
while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))

  echo ""
  echo "=============================================="
  echo "Iteration $ITERATION of $MAX_ITERATIONS"
  echo "=============================================="

  # Get next task info
  NEXT_TASK=$(jq -r '
    .features
    | map(select(.passes == false))
    | sort_by(
        if .priority == "high" then 0
        elif .priority == "medium" then 1
        else 2 end
      )
    | first
    | if . then
        "Task: \(.id) - \(.title)\nGitHub: #\(.github_issue // "N/A")"
      else
        "ALL_COMPLETE"
      end
  ' "$PRD_FILE")

  if [ "$NEXT_TASK" = "ALL_COMPLETE" ]; then
    echo "All tasks complete!"
    rm -f "$STATE_FILE"
    exit 0
  fi

  echo "$NEXT_TASK"
  echo ""

  # Read guardrails if they exist
  GUARDRAILS_CONTENT=""
  if [ -f "$GUARDRAILS_FILE" ]; then
    GUARDRAILS_CONTENT=$(cat "$GUARDRAILS_FILE")
  fi

  # Create state file for this iteration
  cat > "$STATE_FILE" << EOF
---
iteration: $ITERATION
max_iterations: $MAX_ITERATIONS
run_id: "$RUN_ID"
mode: fresh
---

## Guardrails (Signs)

Follow these learned constraints to avoid repeated failures:

$GUARDRAILS_CONTENT

---

## Instructions

You are in a Ralph loop (fresh-context mode). Each iteration is a fresh Claude session.

1. Read $PRD_FILE and find the first task where passes: false
2. Read $PROGRESS_FILE for context from previous iterations
3. Read and follow the Guardrails above - they prevent repeated mistakes
4. Work on the task until acceptance criteria are met
5. Run verification: $VERIFY_COMMAND
6. When the task is complete:
   - Update prd.json: set passes: true and add completed_at
   - Update progress.md with what you learned
7. If ALL tasks in prd.json pass, output: <promise>COMPLETE</promise>
8. Otherwise, end normally (next iteration will continue)

**Important:** Only output the completion promise when ALL tasks pass (re-read prd.json to verify).
EOF

  # Spawn fresh Claude session
  echo "Spawning fresh Claude session..."
  OUTPUT_FILE="$RUN_DIR/iteration-$ITERATION.txt"

  # Use claude CLI with print mode to capture output
  # The prompt re-anchors from files every iteration
  # --dangerously-skip-permissions required for non-interactive mode
  claude --print --output-format text --dangerously-skip-permissions \
    "You are in a Ralph loop. Read .claude/ralph-state.local.md for instructions and guardrails, \
     then read $PRD_FILE to find the next failing task, \
     and $PROGRESS_FILE for context. Follow all guardrails/signs in the state file. \
     Work on the task, run '$VERIFY_COMMAND' to verify, \
     and update prd.json when complete. \
     Output <promise>COMPLETE</promise> only when ALL tasks pass (re-read prd.json to verify)." \
    > "$OUTPUT_FILE" 2>&1 || true

  # Check for completion promise
  if grep -q "<promise>COMPLETE</promise>" "$OUTPUT_FILE"; then
    echo ""
    echo "=============================================="
    echo "Completion promise detected!"
    echo "All tasks complete."
    echo "=============================================="
    rm -f "$STATE_FILE"
    exit 0
  fi

  # Run verification
  echo ""
  echo "Running verification..."
  VERIFY_OUTPUT=$($VERIFY_COMMAND 2>&1) || true
  VERIFY_EXIT=$?

  if [ $VERIFY_EXIT -eq 0 ]; then
    echo "Verification PASSED"
  else
    echo "Verification FAILED (exit $VERIFY_EXIT)"
    echo "$VERIFY_OUTPUT" | tail -20
  fi

  # Check remaining tasks
  REMAINING=$(jq '[.features[] | select(.passes == false)] | length' "$PRD_FILE")
  echo ""
  echo "Remaining tasks: $REMAINING"

  if [ "$REMAINING" -eq 0 ]; then
    echo ""
    echo "=============================================="
    echo "All tasks complete!"
    echo "=============================================="
    rm -f "$STATE_FILE"
    exit 0
  fi

  # Brief pause between iterations
  sleep 2
done

echo ""
echo "=============================================="
echo "Max iterations ($MAX_ITERATIONS) reached"
echo "=============================================="
rm -f "$STATE_FILE"
exit 1
