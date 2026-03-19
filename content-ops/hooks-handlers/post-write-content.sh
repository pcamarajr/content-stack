#!/usr/bin/env bash
set -euo pipefail
# Hook 4: Auto-update trackers when a default-language content file is written
#
# Triggers on: PostToolUse > Edit|Write
# Action: If a new content file was written in the default language,
#         instructs Claude to update the translation tracker and content backlog.

INPUT=$(cat)
fp=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.filePath // empty')

if [ -z "$fp" ]; then
  echo "[content-ops] Warning: could not extract file path from hook input; tracker update skipped." >&2
  exit 0
fi

DEFAULT_LANG=$(grep -m1 'default_language:' \
  "$CLAUDE_PROJECT_DIR/.content-ops/config.md" 2>/dev/null \
  | sed -E 's/.*default_language:[[:space:]]*["'\'']?([^"'\''[:space:]#]+)["'\'']?.*/\1/' \
  | tr -d "\"'" \
  ) || true
DEFAULT_LANG=${DEFAULT_LANG:-en}

# Only act on default-language content files (src/content/.../LANG/...)
if ! echo "$fp" | grep -qE "src/content/.+/${DEFAULT_LANG}/.+\\.mdx?\$"; then
  exit 0
fi

echo "A default-language content file was written at: $fp."
echo "If this is a new file (not an edit of an existing one):"
echo "  1) Add it to the translation tracker with 'done' for the default language"
echo "     and 'pending' for all other configured languages."
echo "  2) Check the content backlog and mark matching entries as 'done'."
echo "Follow update-trackers skill rules for formatting."
