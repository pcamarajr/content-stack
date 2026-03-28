#!/bin/bash
set -euo pipefail

# Read tool input from stdin
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only run when a gemini command is about to execute
if [[ "$cmd" != *"gemini"* ]]; then
  exit 0
fi

# Install Gemini CLI if missing
if ! command -v gemini &>/dev/null; then
  echo "content-image-gemini: Installing @google/gemini-cli..." >&2
  npm install -g @google/gemini-cli >&2
fi

# Install nanobanana extension if missing
# Capture output first to avoid pipefail exiting on a non-zero gemini extensions list
installed_extensions=$(gemini extensions list 2>/dev/null || echo "")
if ! echo "$installed_extensions" | grep -q "nanobanana"; then
  echo "content-image-gemini: Installing nanobanana extension..." >&2
  gemini extensions install https://github.com/gemini-cli-extensions/nanobanana >&2
fi

exit 0
