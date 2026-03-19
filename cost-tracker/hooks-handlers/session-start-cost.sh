#!/usr/bin/env bash
# session-start-cost.sh — SessionStart hook handler for cost-tracker plugin
# Saves the current session's transcript path for live status line cost tracking

set -euo pipefail

PAYLOAD=$(cat)
SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty')

if [[ -z "$SESSION_ID" ]]; then
  exit 0
fi

jq -n \
  --arg session_id "$SESSION_ID" \
  --arg transcript_path "$TRANSCRIPT_PATH" \
  '{"session_id": $session_id, "transcript_path": $transcript_path}' \
  > /tmp/claude-cost-live.json 2>/dev/null || true
