#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/Users/jonzeolla/src/zenable/next-gen-governance"
PROMPT_FILE="/Users/jonzeolla/prompts/nightly-pr-review.txt"
LOG_DIR="/Users/jonzeolla/.claude/logs"

mkdir -p "$LOG_DIR"

# Allow running from within a Claude Code session
unset CLAUDECODE 2>/dev/null || true

cd "$REPO_DIR"

/opt/homebrew/bin/claude \
  --verbose \
  --allowedTools 'Bash,Read,Write,Edit,MultiEdit,Glob,Grep,LS,Task,WebSearch,WebFetch,mcp__chrome-devtools,mcp__zenable' \
  -p "$(cat "$PROMPT_FILE")" \
  >> "$LOG_DIR/nightly-pr-review.log" 2>&1
