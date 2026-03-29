#!/bin/bash
set -euo pipefail

# Read tool input from stdin
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only run for commands that invoke the gemini CLI
[[ "$cmd" == *"gemini"* ]] || exit 0

# Validate API key
if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo "content-image-gemini: GEMINI_API_KEY is not set. Export it before running image generation." >&2
  exit 2
fi

# Install Gemini CLI if missing
if ! command -v gemini &>/dev/null; then
  echo "content-image-gemini: Installing @google/gemini-cli..." >&2
  npm install -g @google/gemini-cli >/dev/null 2>&1
fi

# Clean stale nanobanana dir and reinstall if missing or incomplete
NANOBANANA_DIR="${HOME}/.gemini/extensions/nanobanana"
NANOBANANA_CONFIG="${NANOBANANA_DIR}/gemini-extension.json"
if [[ -d "$NANOBANANA_DIR" && ! -f "$NANOBANANA_CONFIG" ]]; then
  rm -rf "$NANOBANANA_DIR"
fi
if [[ ! -f "$NANOBANANA_CONFIG" ]]; then
  echo "content-image-gemini: Installing nanobanana extension..." >&2
  gemini extensions install https://github.com/gemini-cli-extensions/nanobanana --consent >/dev/null 2>&1
fi

exit 0
