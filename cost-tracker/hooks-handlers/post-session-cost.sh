#!/usr/bin/env bash
# post-session-cost.sh — Stop hook handler for cost-tracker plugin
# Reads the session transcript, calculates token cost, appends to .cost-log/sessions.jsonl

set -euo pipefail

# --- Read hook payload from stdin ---
PAYLOAD=$(cat)
TRANSCRIPT_PATH=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // empty')

# --- Validate transcript ---
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "[cost-tracker] Warning: transcript not found, session not recorded."
  exit 0
fi

# --- Parse assistant entries from transcript ---
ASSISTANT_ENTRIES=$(grep -o '{.*}' "$TRANSCRIPT_PATH" 2>/dev/null \
  | jq -c 'select(.type == "assistant")' 2>/dev/null || true)

if [[ -z "$ASSISTANT_ENTRIES" ]]; then
  echo "[cost-tracker] Warning: no assistant turns found, session not recorded."
  exit 0
fi

# --- Extract model from first assistant entry ---
MODEL=$(echo "$ASSISTANT_ENTRIES" | head -1 | jq -r '.message.model // "Unknown"')
if [[ -z "$MODEL" || "$MODEL" == "null" ]]; then
  MODEL="Unknown"
fi

# --- Sum token counts across all assistant entries ---
TOTALS=$(echo "$ASSISTANT_ENTRIES" | jq -s '{
  input_tokens:       (map(.message.usage.input_tokens // 0)                  | add // 0),
  output_tokens:      (map(.message.usage.output_tokens // 0)                 | add // 0),
  cache_write_tokens: (map(.message.usage.cache_creation_input_tokens // 0)   | add // 0),
  cache_read_tokens:  (map(.message.usage.cache_read_input_tokens // 0)       | add // 0)
}')

INPUT_TOKENS=$(echo "$TOTALS"       | jq '.input_tokens')
OUTPUT_TOKENS=$(echo "$TOTALS"      | jq '.output_tokens')
CACHE_WRITE_TOKENS=$(echo "$TOTALS" | jq '.cache_write_tokens')
CACHE_READ_TOKENS=$(echo "$TOTALS"  | jq '.cache_read_tokens')

# --- Pricing table (USD per 1M tokens) ---
# Pattern match: check if model contains the key string
PRICING="standard"

if echo "$MODEL" | grep -qi "claude-opus-4"; then
  IN_RATE=15.00; OUT_RATE=75.00; CW_RATE=18.75; CR_RATE=1.50
elif echo "$MODEL" | grep -qi "claude-sonnet-4"; then
  IN_RATE=3.00;  OUT_RATE=15.00; CW_RATE=3.75;  CR_RATE=0.30
elif echo "$MODEL" | grep -qi "claude-haiku-4"; then
  IN_RATE=0.80;  OUT_RATE=4.00;  CW_RATE=1.00;  CR_RATE=0.08
else
  # Fallback: Sonnet rates, mark as estimated
  IN_RATE=3.00;  OUT_RATE=15.00; CW_RATE=3.75;  CR_RATE=0.30
  PRICING="estimated"
fi

# --- Calculate cost ---
COST=$(jq -n \
  --argjson input  "$INPUT_TOKENS" \
  --argjson output "$OUTPUT_TOKENS" \
  --argjson cw     "$CACHE_WRITE_TOKENS" \
  --argjson cr     "$CACHE_READ_TOKENS" \
  --argjson ir     "$IN_RATE" \
  --argjson or_    "$OUT_RATE" \
  --argjson cwr    "$CW_RATE" \
  --argjson crr    "$CR_RATE" \
  '($input * $ir + $output * $or_ + $cw * $cwr + $cr * $crr) / 1000000')

# --- Write record ---
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOG_DIR="${CLAUDE_PROJECT_DIR}/.cost-log"
LOG_FILE="${LOG_DIR}/sessions.jsonl"

mkdir -p "$LOG_DIR"

RECORD=$(jq -n \
  --arg  session_id         "$SESSION_ID" \
  --arg  timestamp          "$TIMESTAMP" \
  --arg  model              "$MODEL" \
  --argjson input_tokens    "$INPUT_TOKENS" \
  --argjson output_tokens   "$OUTPUT_TOKENS" \
  --argjson cache_write_tokens "$CACHE_WRITE_TOKENS" \
  --argjson cache_read_tokens  "$CACHE_READ_TOKENS" \
  --argjson cost_usd        "$COST" \
  --arg  pricing            "$PRICING" \
  '{
    session_id:         $session_id,
    timestamp:          $timestamp,
    model:              $model,
    input_tokens:       $input_tokens,
    output_tokens:      $output_tokens,
    cache_write_tokens: $cache_write_tokens,
    cache_read_tokens:  $cache_read_tokens,
    cost_usd:           ($cost_usd | . * 100000 | round / 100000),
    pricing:            $pricing
  }')

if ! echo "$RECORD" >> "$LOG_FILE" 2>/dev/null; then
  echo "[cost-tracker] Warning: could not write to .cost-log/sessions.jsonl."
  exit 0
fi

# --- Compute 30-day running total ---
THIRTY_DAYS_AGO=$(date -u -v-30d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || echo "")

if [[ -n "$THIRTY_DAYS_AGO" ]]; then
  TOTAL_30D=$(jq -s --arg since "$THIRTY_DAYS_AGO" \
    '[.[] | select(.timestamp >= $since) | .cost_usd] | add // 0' \
    "$LOG_FILE" 2>/dev/null || echo "0")
else
  TOTAL_30D=$(jq -s '[.[].cost_usd] | add // 0' "$LOG_FILE" 2>/dev/null || echo "0")
fi

# --- Format output ---
SESSION_COST_FMT=$(printf "%.4f" "$COST" 2>/dev/null || echo "$COST")
TOTAL_30D_FMT=$(printf "%.4f" "$TOTAL_30D" 2>/dev/null || echo "$TOTAL_30D")

printf '{"systemMessage": "[cost-tracker] Session: ~$%s | 30d total: ~$%s"}\n' "$SESSION_COST_FMT" "$TOTAL_30D_FMT"
