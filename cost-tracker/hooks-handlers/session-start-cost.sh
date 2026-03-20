#!/usr/bin/env bash
# session-start-cost.sh — SessionStart hook handler for cost-tracker plugin
# 1. Saves the current session's transcript path for live status line cost tracking
# 2. Patches .claude/settings.local.json to append the cost line below any existing statusLine

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
  > "/tmp/claude-cost-live-${SESSION_ID}.json" 2>/dev/null || true

# --- Patch local settings to append cost line below existing statusLine ---

CWD=$(echo "$PAYLOAD" | jq -r '.cwd // .workspace.current_dir // empty')
[[ -z "$CWD" ]] && CWD=$(pwd)

COST_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/status-line.sh"
LOCAL_SETTINGS="${CWD}/.claude/settings.local.json"

# Read the user-level statusLine only (avoid reading project/local to prevent loops)
USER_CMD=$(jq -r '.statusLine.command // empty' "${HOME}/.claude/settings.json" 2>/dev/null || true)

if [[ -n "$USER_CMD" ]]; then
  COMBINED="bash -c 'a=\$(${USER_CMD} 2>/dev/null); b=\$(COST_SESSION_ID=\"${SESSION_ID}\" bash \"${COST_SCRIPT}\" 2>/dev/null); printf \"%s\\n%s\" \"\$a\" \"\$b\"'"
else
  COMBINED="COST_SESSION_ID=\"${SESSION_ID}\" bash \"${COST_SCRIPT}\""
fi

# Merge statusLine into local settings, preserving other keys
CURRENT="{}"
[[ -f "$LOCAL_SETTINGS" ]] && CURRENT=$(cat "$LOCAL_SETTINGS")

echo "$CURRENT" \
  | jq --arg cmd "$COMBINED" '.statusLine = {"type": "command", "command": $cmd}' \
  > "$LOCAL_SETTINGS" 2>/dev/null || true
