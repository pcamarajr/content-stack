#!/usr/bin/env bash
set -euo pipefail
# Hook 2: Post-commit build verification
#
# Triggers on: PostToolUse > Bash
# Action: Runs pnpm build after every git commit to catch build failures immediately.
# Note: Users may remove or replace this hook if they don't use pnpm.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on git commit commands
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" && pnpm build 2>&1
