#!/usr/bin/env bash
# Ralph Stop - Kill active Ralph loops (both modes)
# Usage: ./scripts/ralph/ralph-stop.sh [--force]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_FILE="$PROJECT_DIR/.claude/ralph-loop.local.md"
STATUS_FILE="$PROJECT_DIR/.claude/ralph-status.local.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FORCE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
  FORCE=true
fi

echo "=============================================="
echo "Ralph Stop"
echo "=============================================="
echo ""

# Track what we found/killed
FOUND_SOMETHING=false

# 1. Check for fresh-context mode (ralph.sh process)
RALPH_PIDS=$(pgrep -f "ralph.sh" 2>/dev/null || true)
if [ -n "$RALPH_PIDS" ]; then
  FOUND_SOMETHING=true
  echo -e "${YELLOW}Found ralph.sh process(es):${NC}"
  ps -p $RALPH_PIDS -o pid,command 2>/dev/null | head -5
  echo ""

  if [ "$FORCE" = true ]; then
    echo "Killing ralph.sh processes..."
    kill $RALPH_PIDS 2>/dev/null || true
    echo -e "${GREEN}Killed ralph.sh${NC}"
  else
    echo -e "Run with ${YELLOW}--force${NC} to kill, or press Ctrl+C in the ralph.sh terminal"
  fi
fi

# 2. Check for Claude subprocesses spawned by Ralph
CLAUDE_PIDS=$(pgrep -f "claude.*ralph" 2>/dev/null || true)
if [ -n "$CLAUDE_PIDS" ]; then
  FOUND_SOMETHING=true
  echo -e "${YELLOW}Found Claude subprocess(es):${NC}"
  ps -p $CLAUDE_PIDS -o pid,command 2>/dev/null | head -5
  echo ""

  if [ "$FORCE" = true ]; then
    echo "Killing Claude subprocesses..."
    kill $CLAUDE_PIDS 2>/dev/null || true
    echo -e "${GREEN}Killed Claude processes${NC}"
  else
    echo -e "Run with ${YELLOW}--force${NC} to kill"
  fi
fi

# 3. Check for same-session state file
if [ -f "$STATE_FILE" ]; then
  FOUND_SOMETHING=true
  echo -e "${YELLOW}Found same-session state file:${NC}"

  # Extract key info from state file
  ITERATION=$(grep "^iteration:" "$STATE_FILE" 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "?")
  MAX_ITER=$(grep "^max_iterations:" "$STATE_FILE" 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "?")
  echo "  Iteration: $ITERATION / $MAX_ITER"
  echo ""

  if [ "$FORCE" = true ]; then
    rm -f "$STATE_FILE"
    echo -e "${GREEN}Removed state file${NC}"
  else
    echo -e "Run with ${YELLOW}--force${NC} to remove state file"
  fi
fi

# 4. Check for status file
if [ -f "$STATUS_FILE" ]; then
  if [ "$FORCE" = true ]; then
    rm -f "$STATUS_FILE"
    echo -e "${GREEN}Removed status file${NC}"
  fi
fi

echo ""

if [ "$FOUND_SOMETHING" = false ]; then
  echo -e "${GREEN}No active Ralph loop found.${NC}"
elif [ "$FORCE" = true ]; then
  echo "=============================================="
  echo -e "${GREEN}Ralph loop stopped.${NC}"
  echo "=============================================="
else
  echo "=============================================="
  echo -e "Use ${YELLOW}./scripts/ralph/ralph-stop.sh --force${NC} to stop all"
  echo "=============================================="
fi
