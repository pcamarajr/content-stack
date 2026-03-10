#!/usr/bin/env bash
set -euo pipefail
# Hook 1: Remind to reindex after content commits
#
# Triggers on: PostToolUse > Bash
# Action: After a git commit that touches default-language content files,
#         remind Claude to regenerate the content index if stale.
#         Run /reindex to scan frontmatter and write .content-ops/content-index.json.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on git commit commands
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

DEFAULT_LANG=$(grep -m1 'default_language:' \
  "$CLAUDE_PROJECT_DIR/.content-ops/config.md" 2>/dev/null \
  | sed -E 's/.*default_language:[[:space:]]*["'\'']?([^"'\''[:space:]#]+)["'\'']?.*/\1/' \
  | tr -d "\"'" \
  ) || true
DEFAULT_LANG=${DEFAULT_LANG:-en}

FILES=$(
  git -C "$CLAUDE_PROJECT_DIR" diff --name-only HEAD~1 2>/dev/null \
    | grep -E "src/content/.+/${DEFAULT_LANG}/.+\\.mdx?\$" \
    || true
)

if [ -z "$FILES" ]; then
  exit 0
fi

echo "Default-language content files were just committed."
echo "If the content index is stale, run /reindex to regenerate .content-ops/content-index.json"
echo "Committed files:"
echo "$FILES"
