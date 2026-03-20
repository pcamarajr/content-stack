#!/usr/bin/env bash
# status-line.sh — Live cost display for Claude Code status bar
# Shows running session cost from the live transcript, falls back to 30-day total

LIVE_FILE="/tmp/claude-cost-live.json"
LOG_FILE="${CLAUDE_PROJECT_DIR:-$(pwd)}/.cost-log/sessions.jsonl"

# --- Try live session tracking ---
if [[ -f "$LIVE_FILE" ]]; then
  TRANSCRIPT_PATH=$(jq -r '.transcript_path // empty' "$LIVE_FILE" 2>/dev/null || echo "")
  LIVE_SESSION_ID=$(jq -r '.session_id // empty' "$LIVE_FILE" 2>/dev/null || echo "")

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

      TOTALS=$(echo "$ASSISTANT_ENTRIES" | jq -s \
        --argjson ir "$IN_RATE" --argjson or_ "$OUT_RATE" \
        --argjson cwr "$CW_RATE" --argjson crr "$CR_RATE" '
        {
          i:  (map(.message.usage.input_tokens                // 0) | add // 0),
          o:  (map(.message.usage.output_tokens               // 0) | add // 0),
          cw: (map(.message.usage.cache_creation_input_tokens // 0) | add // 0),
          cr: (map(.message.usage.cache_read_input_tokens     // 0) | add // 0)
        } | . + {
          cost:      ((.i * $ir + .o * $or_ + .cw * $cwr + .cr * $crr) / 1000000),
          total_tok: (.i + .o + .cr),
          cache_pct: (if (.i + .cr) > 0 then (.cr / (.i + .cr) * 100 | round) else 0 end)
        }
        ' 2>/dev/null)

      LIVE_COST=$(echo "$TOTALS" | jq -r '.cost      // 0')
      TOTAL_TOK=$(echo "$TOTALS" | jq -r '.total_tok // 0')
      CACHE_PCT=$(echo "$TOTALS" | jq -r '.cache_pct // 0')

      # Add completed segments for this session from the log
      HIST_COST=0
      if [[ -f "$LOG_FILE" && -n "$LIVE_SESSION_ID" ]]; then
        HIST_COST=$(jq -s --arg sid "$LIVE_SESSION_ID" \
          '[.[] | select(.session_id == $sid) | .cost_usd] | add // 0' \
          "$LOG_FILE" 2>/dev/null || echo "0")
      fi

      COST=$(jq -n --argjson live "$LIVE_COST" --argjson hist "$HIST_COST" '$live + $hist')

      COST_FMT=$(printf "%.4f" "$COST" 2>/dev/null || echo "$COST")
      TOK_FMT=$(echo "$TOTAL_TOK" | awk '{if($1>=1000) printf "%.0fk", $1/1000; else print $1}')

      # Also show 30d total if log exists
      THIRTY_D_PART=""
      if [[ -f "$LOG_FILE" ]]; then
        THIRTY_DAYS_AGO=$(date -u -v-30d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
          || date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
        if [[ -n "$THIRTY_DAYS_AGO" ]]; then
          TOTAL=$(jq -s --arg since "$THIRTY_DAYS_AGO" \
            '[.[] | select(.timestamp >= $since) | .cost_usd] | add // 0' \
            "$LOG_FILE" 2>/dev/null || echo "0")
        else
          TOTAL=$(jq -s '[.[].cost_usd] | add // 0' "$LOG_FILE" 2>/dev/null || echo "0")
        fi
        TOTAL_FMT=$(printf "%.2f" "$TOTAL" 2>/dev/null || echo "0.00")
        THIRTY_D_PART=" · ~\$${TOTAL_FMT}/30d"
      fi

      printf "\033[0;32mcost:(\033[0;37m~\$%s session%s · %s tok · %s%% cached\033[0;32m)\033[0m\n" \
        "$COST_FMT" "$THIRTY_D_PART" "$TOK_FMT" "$CACHE_PCT"
      exit 0
    fi
  fi
fi

# --- Fallback: 30-day project total (no active session) ---
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
  printf "\033[0;32mcost:(\033[0;37m~\$%s 30d\033[0;32m)\033[0m\n" "$TOTAL_FMT"
fi
