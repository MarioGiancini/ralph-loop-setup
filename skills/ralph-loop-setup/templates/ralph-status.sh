#!/bin/bash
# Ralph Status Dashboard
# Shows current loop status, task progress, and recent activity
#
# Usage:
#   ./scripts/ralph/ralph-status.sh          # One-time status
#   ./scripts/ralph/ralph-status.sh --watch  # Live updates (every 2s)
#   watch -n 2 ./scripts/ralph/ralph-status.sh  # Alternative live view

set -euo pipefail

STATUS_FILE=".claude/ralph-status.local.json"
PRD_FILE="plans/prd.json"
PROGRESS_FILE="plans/progress.md"
RUNS_DIR="scripts/ralph/runs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse arguments
WATCH_MODE=false
if [ "${1:-}" = "--watch" ] || [ "${1:-}" = "-w" ]; then
  WATCH_MODE=true
fi

print_header() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║            🤖 Ralph Loop Status Dashboard                    ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_no_loop() {
  echo -e "${YELLOW}No active Ralph loop detected.${NC}"
  echo ""
  echo "To start a loop:"
  echo "  ./scripts/ralph/ralph.sh"
  echo "  ./scripts/ralph/ralph.sh --verbose"
  echo "  ./scripts/ralph/ralph.sh --branch ralph/feature"
  echo ""
}

print_status() {
  if [ ! -f "$STATUS_FILE" ]; then
    print_no_loop
    return
  fi

  # Parse status JSON
  RUN_ID=$(jq -r '.run_id' "$STATUS_FILE")
  ITERATION=$(jq -r '.iteration' "$STATUS_FILE")
  MAX_ITER=$(jq -r '.max_iterations' "$STATUS_FILE")
  STATUS=$(jq -r '.status' "$STATUS_FILE")
  TASK_ID=$(jq -r '.current_task.id' "$STATUS_FILE")
  TASK_TITLE=$(jq -r '.current_task.title' "$STATUS_FILE")
  REMAINING=$(jq -r '.remaining_tasks' "$STATUS_FILE")
  STARTED=$(jq -r '.started_at' "$STATUS_FILE")
  UPDATED=$(jq -r '.updated_at' "$STATUS_FILE")
  BRANCH=$(jq -r '.branch' "$STATUS_FILE")
  LOG_FILE=$(jq -r '.log_file' "$STATUS_FILE")

  # Status color
  case "$STATUS" in
    running)   STATUS_COLOR="${GREEN}● RUNNING${NC}" ;;
    verifying) STATUS_COLOR="${CYAN}◐ VERIFYING${NC}" ;;
    complete)  STATUS_COLOR="${GREEN}✓ COMPLETE${NC}" ;;
    starting)  STATUS_COLOR="${YELLOW}○ STARTING${NC}" ;;
    max_iterations) STATUS_COLOR="${RED}✗ MAX ITERATIONS${NC}" ;;
    *)         STATUS_COLOR="${YELLOW}? $STATUS${NC}" ;;
  esac

  # Calculate duration
  if command -v gdate &> /dev/null; then
    START_EPOCH=$(gdate -d "$STARTED" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(gdate +%s)
  else
    START_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${STARTED%%+*}" +%s 2>/dev/null || echo 0)
    NOW_EPOCH=$(date +%s)
  fi

  if [ "$START_EPOCH" -gt 0 ]; then
    DURATION=$((NOW_EPOCH - START_EPOCH))
    DURATION_STR="$(( DURATION / 60 ))m $(( DURATION % 60 ))s"
  else
    DURATION_STR="--"
  fi

  # Print status
  echo -e "${BOLD}Loop Status:${NC} $STATUS_COLOR"
  echo -e "${BOLD}Run ID:${NC}      $RUN_ID"
  echo -e "${BOLD}Branch:${NC}      $BRANCH"
  echo -e "${BOLD}Duration:${NC}    $DURATION_STR"
  echo ""
  echo -e "${BOLD}Progress:${NC}    Iteration $ITERATION of $MAX_ITER"

  # Progress bar
  if [ "$MAX_ITER" -gt 0 ]; then
    PCT=$((ITERATION * 100 / MAX_ITER))
    BAR_WIDTH=40
    FILLED=$((PCT * BAR_WIDTH / 100))
    EMPTY=$((BAR_WIDTH - FILLED))
    printf "             ["
    printf "%0.s█" $(seq 1 $FILLED 2>/dev/null) || true
    printf "%0.s░" $(seq 1 $EMPTY 2>/dev/null) || true
    printf "] %d%%\n" $PCT
  fi

  echo ""
  echo -e "${BOLD}Current Task:${NC}"
  echo -e "  ID:    $TASK_ID"
  echo -e "  Title: $TASK_TITLE"
  echo ""
  echo -e "${BOLD}Tasks Remaining:${NC} $REMAINING"
}

print_tasks() {
  if [ ! -f "$PRD_FILE" ]; then
    echo -e "${YELLOW}No prd.json found${NC}"
    return
  fi

  echo ""
  echo -e "${BOLD}Task List:${NC}"
  echo "─────────────────────────────────────────────────────────────────"

  jq -r '.features[] |
    if .passes then
      "  ✓ \(.id) - \(.title)"
    elif .skip then
      "  ⊘ \(.id) - \(.title) [SKIPPED]"
    else
      "  ○ \(.id) - \(.title)"
    end
  ' "$PRD_FILE"

  echo "─────────────────────────────────────────────────────────────────"

  DONE=$(jq '[.features[] | select(.passes == true)] | length' "$PRD_FILE")
  SKIPPED=$(jq '[.features[] | select(.skip == true)] | length' "$PRD_FILE")
  TOTAL=$(jq '.features | length' "$PRD_FILE")
  if [ "$SKIPPED" -gt 0 ]; then
    echo -e "  ${GREEN}$DONE${NC} of ${BOLD}$TOTAL${NC} complete, ${YELLOW}$SKIPPED${NC} skipped"
  else
    echo -e "  ${GREEN}$DONE${NC} of ${BOLD}$TOTAL${NC} tasks complete"
  fi
}

print_recent_runs() {
  echo ""
  echo -e "${BOLD}Recent Runs:${NC}"

  if [ ! -d "$RUNS_DIR" ]; then
    echo "  No runs yet"
    return
  fi

  # List recent run directories
  RUNS=$(ls -t "$RUNS_DIR" 2>/dev/null | head -5)

  if [ -z "$RUNS" ]; then
    echo "  No runs yet"
    return
  fi

  for RUN in $RUNS; do
    ITER_COUNT=$(ls "$RUNS_DIR/$RUN"/iteration-*.txt 2>/dev/null | wc -l | tr -d ' ')
    echo "  $RUN - $ITER_COUNT iterations"
  done
}

print_log_tail() {
  if [ ! -f "$STATUS_FILE" ]; then
    return
  fi

  LOG_FILE=$(jq -r '.log_file' "$STATUS_FILE")

  if [ -f "$LOG_FILE" ]; then
    echo ""
    echo -e "${BOLD}Latest Output:${NC} (last 8 lines)"
    echo "─────────────────────────────────────────────────────────────────"
    tail -8 "$LOG_FILE" | sed 's/^/  /'
    echo "─────────────────────────────────────────────────────────────────"
  fi
}

# Main
if [ "$WATCH_MODE" = true ]; then
  while true; do
    clear
    print_header
    print_status
    print_tasks
    print_log_tail
    echo ""
    echo -e "${CYAN}Refreshing every 2s... (Ctrl+C to exit)${NC}"
    sleep 2
  done
else
  print_header
  print_status
  print_tasks
  print_recent_runs
  print_log_tail
fi
