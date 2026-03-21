#!/usr/bin/env bash
# report.sh — On-demand cost report for cost-tracker plugin
# Reads .cost-log/sessions.jsonl and prints a summary to stdout

set -euo pipefail

LOG_FILE="${CLAUDE_PROJECT_DIR}/.cost-log/sessions.jsonl"

# --- Handle missing or empty file ---
if [[ ! -f "$LOG_FILE" ]] || [[ ! -s "$LOG_FILE" ]]; then
  echo "No sessions recorded yet."
  exit 0
fi

# --- Parse all records, skip malformed lines ---
SKIP_COUNT=0
VALID_RECORDS=""
SESSION_RECORDS=""
AGENT_RECORDS=""

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if echo "$line" | jq -e 'has("session_id") and has("cost_usd") and has("timestamp")' > /dev/null 2>&1; then
    VALID_RECORDS="${VALID_RECORDS}${line}"$'\n'
    RECORD_TYPE=$(echo "$line" | jq -r '.record_type // "session"')
    if [[ "$RECORD_TYPE" == "agent_run" ]]; then
      AGENT_RECORDS="${AGENT_RECORDS}${line}"$'\n'
    else
      SESSION_RECORDS="${SESSION_RECORDS}${line}"$'\n'
    fi
  else
    SKIP_COUNT=$((SKIP_COUNT + 1))
  fi
done < "$LOG_FILE"

if [[ -z "$VALID_RECORDS" ]]; then
  echo "No sessions recorded yet."
  [[ $SKIP_COUNT -gt 0 ]] && echo "[cost-tracker] Warning: ${SKIP_COUNT} malformed line(s) skipped."
  exit 0
fi

# --- Compute date thresholds ---
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
THIRTY_DAYS_AGO=$(date -u -v-30d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || echo "")

SEVEN_DAYS_AGO=$(date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || echo "")

# --- All-time totals ---
ALL_TIME=$(echo "$VALID_RECORDS" | jq -s '{
  total_cost:    ([.[].cost_usd] | add // 0),
  session_count: length
}')
ALL_COST=$(echo "$ALL_TIME"  | jq -r '.total_cost')
ALL_COUNT=$(echo "$ALL_TIME" | jq -r '.session_count')

ALL_SESSION_COUNT=0
ALL_AGENT_COUNT=0
ALL_SESSION_COST=0
ALL_AGENT_COST=0

if [[ -n "$SESSION_RECORDS" ]]; then
  ALL_SESSION_STATS=$(echo "$SESSION_RECORDS" | jq -s '{count: length, cost: ([.[].cost_usd] | add // 0)}')
  ALL_SESSION_COUNT=$(echo "$ALL_SESSION_STATS" | jq -r '.count')
  ALL_SESSION_COST=$(echo "$ALL_SESSION_STATS"  | jq -r '.cost')
fi
if [[ -n "$AGENT_RECORDS" ]]; then
  ALL_AGENT_STATS=$(echo "$AGENT_RECORDS" | jq -s '{count: length, cost: ([.[].cost_usd] | add // 0)}')
  ALL_AGENT_COUNT=$(echo "$ALL_AGENT_STATS" | jq -r '.count')
  ALL_AGENT_COST=$(echo "$ALL_AGENT_STATS"  | jq -r '.cost')
fi

# --- 30-day totals ---
if [[ -n "$THIRTY_DAYS_AGO" ]]; then
  RECENT_30=$(echo "$VALID_RECORDS" | jq -s --arg since "$THIRTY_DAYS_AGO" '{
    total_cost:    ([.[] | select(.timestamp >= $since) | .cost_usd] | add // 0),
    session_count: ([.[] | select(.timestamp >= $since)] | length)
  }')
else
  RECENT_30=$(echo "$ALL_TIME")
fi
COST_30D=$(echo "$RECENT_30"  | jq -r '.total_cost')
COUNT_30D=$(echo "$RECENT_30" | jq -r '.session_count')

# --- Per-model breakdown ---
MODEL_BREAKDOWN=$(echo "$VALID_RECORDS" | jq -s '
  group_by(.model) | map({
    model:         .[0].model,
    sessions:      length,
    total_cost:    ([.[].cost_usd] | add // 0)
  }) | sort_by(-.total_cost)
')

# --- Daily spend for last 7 days ---
DAILY_7D=""
for i in 6 5 4 3 2 1 0; do
  if command -v gdate > /dev/null 2>&1; then
    DAY_DATE=$(gdate -u -d "$i days ago" +"%Y-%m-%d" 2>/dev/null || true)
  else
    DAY_DATE=$(date -u -v-${i}d +"%Y-%m-%d" 2>/dev/null \
      || date -u -d "$i days ago" +"%Y-%m-%d" 2>/dev/null \
      || echo "")
  fi
  [[ -z "$DAY_DATE" ]] && continue
  DAY_COST=$(echo "$VALID_RECORDS" | jq -s --arg day "$DAY_DATE" \
    '[.[] | select(.timestamp | startswith($day)) | .cost_usd] | add // 0')
  DAILY_7D="${DAILY_7D}  ${DAY_DATE}: \$$(printf "%.4f" "$DAY_COST")"$'\n'
done

# --- Cache stats ---
CACHE_STATS=$(echo "$VALID_RECORDS" | jq -s '{
  total_input:        ([.[].input_tokens]       | add // 0),
  total_cache_read:   ([.[].cache_read_tokens]  | add // 0),
  total_cache_write:  ([.[].cache_write_tokens] | add // 0),
  total_output:       ([.[].output_tokens]      | add // 0)
}')

TOTAL_INPUT=$(echo "$CACHE_STATS"       | jq '.total_input')
TOTAL_CACHE_READ=$(echo "$CACHE_STATS"  | jq '.total_cache_read')
TOTAL_CACHE_WRITE=$(echo "$CACHE_STATS" | jq '.total_cache_write')

# Cache hit rate = cache_read / (input + cache_read + cache_write), avoid div by zero
CACHE_HIT_RATE=$(jq -n \
  --argjson tr "$TOTAL_CACHE_READ" \
  --argjson ti "$TOTAL_INPUT" \
  --argjson tw "$TOTAL_CACHE_WRITE" \
  'if ($ti + $tr + $tw) > 0 then ($tr / ($ti + $tr + $tw) * 100) else 0 end')

# Estimated savings: cache_read tokens billed at cache_read rate vs input rate
# Use Sonnet rates as baseline estimate (3.00 input vs 0.30 cache_read per 1M)
CACHE_SAVINGS=$(jq -n \
  --argjson cr "$TOTAL_CACHE_READ" \
  '($cr * (3.00 - 0.30)) / 1000000')

# --- Print report ---
echo "============================================"
echo " cost-tracker — Session Cost Report"
echo "============================================"
echo ""
echo "All-time"
echo "  Records: ${ALL_COUNT}  (${ALL_SESSION_COUNT} session(s), ${ALL_AGENT_COUNT} agent run(s))"
echo "  Sessions cost:   \$$(printf "%.4f" "$ALL_SESSION_COST")"
echo "  Agent runs cost: \$$(printf "%.4f" "$ALL_AGENT_COST")"
echo "  Total cost:      \$$(printf "%.4f" "$ALL_COST")"
echo ""
echo "Last 30 days"
echo "  Sessions: ${COUNT_30D}"
echo "  Total cost: \$$(printf "%.4f" "$COST_30D")"
echo ""
echo "Per-model breakdown"
echo "$MODEL_BREAKDOWN" | jq -r '.[] | "  \(.model): \(.sessions) session(s), $\(.total_cost | . * 10000 | round / 10000)"'
echo ""
echo "Daily spend (last 7 days)"
if [[ -n "$DAILY_7D" ]]; then
  echo "$DAILY_7D"
else
  echo "  (date calculation unavailable)"
  echo ""
fi
echo "Cache"
echo "  Hit rate: $(printf "%.1f" "$CACHE_HIT_RATE")%"
echo "  Estimated savings vs. no cache: \$$(printf "%.4f" "$CACHE_SAVINGS") (baseline: Sonnet rates)"
echo ""

if [[ $SKIP_COUNT -gt 0 ]]; then
  echo "[cost-tracker] Warning: ${SKIP_COUNT} malformed line(s) skipped."
fi
