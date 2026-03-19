#!/usr/bin/env bash
# status-line.sh — Live cost display for Claude Code status bar
# Shows running session cost from the live transcript, falls back to 30-day total

LIVE_FILE="/tmp/claude-cost-live.json"
LOG_FILE="${CLAUDE_PROJECT_DIR:-$(pwd)}/.cost-log/sessions.jsonl"

# --- Try live session tracking ---
if [[ -f "$LIVE_FILE" ]]; then
  TRANSCRIPT_PATH=$(jq -r '.transcript_path // empty' "$LIVE_FILE" 2>/dev/null || echo "")

  if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    ASSISTANT_ENTRIES=$(grep -o '{.*}' "$TRANSCRIPT_PATH" 2>/dev/null \
      | jq -c 'select(.type == "assistant")' 2>/dev/null || true)

    if [[ -n "$ASSISTANT_ENTRIES" ]]; then
      MODEL=$(echo "$ASSISTANT_ENTRIES" | head -1 | jq -r '.message.model // "unknown"' 2>/dev/null || echo "unknown")

      IN_RATE=3.00; OUT_RATE=15.00; CW_RATE=3.75; CR_RATE=0.30
      if echo "$MODEL" | grep -qi "claude-opus-4"; then
        IN_RATE=15.00; OUT_RATE=75.00; CW_RATE=18.75; CR_RATE=1.50
      elif echo "$MODEL" | grep -qi "claude-haiku-4"; then
        IN_RATE=0.80; OUT_RATE=4.00; CW_RATE=1.00; CR_RATE=0.08
      fi

      COST=$(echo "$ASSISTANT_ENTRIES" | jq -s \
        --argjson ir "$IN_RATE" --argjson or_ "$OUT_RATE" \
        --argjson cwr "$CW_RATE" --argjson crr "$CR_RATE" '
        {
          i:  (map(.message.usage.input_tokens                  // 0) | add // 0),
          o:  (map(.message.usage.output_tokens                 // 0) | add // 0),
          cw: (map(.message.usage.cache_creation_input_tokens   // 0) | add // 0),
          cr: (map(.message.usage.cache_read_input_tokens       // 0) | add // 0)
        } | (.i * $ir + .o * $or_ + .cw * $cwr + .cr * $crr) / 1000000
        ' 2>/dev/null || echo "0")

      COST_FMT=$(printf "%.4f" "$COST" 2>/dev/null || echo "$COST")
      echo "~\$$COST_FMT session"
      exit 0
    fi
  fi
fi

# --- Fallback: 30-day project total ---
if [[ -f "$LOG_FILE" ]]; then
  THIRTY_DAYS_AGO=$(date -u -v-30d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
    || date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
    || echo "")

  if [[ -n "$THIRTY_DAYS_AGO" ]]; then
    TOTAL=$(jq -s --arg since "$THIRTY_DAYS_AGO" \
      '[.[] | select(.timestamp >= $since) | .cost_usd] | add // 0' \
      "$LOG_FILE" 2>/dev/null || echo "0")
  else
    TOTAL=$(jq -s '[.[].cost_usd] | add // 0' "$LOG_FILE" 2>/dev/null || echo "0")
  fi

  TOTAL_FMT=$(printf "%.2f" "$TOTAL" 2>/dev/null || echo "0.00")
  echo "~\$$TOTAL_FMT 30d"
fi
