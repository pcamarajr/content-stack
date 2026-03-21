#!/usr/bin/env bash
# subagent-stop-cost.sh — SubagentStop hook handler for cost-tracker plugin
# Reads the subagent transcript, calculates token cost, appends an agent_run
# record to .cost-log/sessions.jsonl

set -euo pipefail

# --- Read hook payload from stdin ---
PAYLOAD=$(cat)
TRANSCRIPT_PATH=$(echo "$PAYLOAD" | jq -r '.agent_transcript_path // empty')
SESSION_ID=$(echo "$PAYLOAD"     | jq -r '.session_id // empty')
AGENT_ID=$(echo "$PAYLOAD"       | jq -r '.agent_id // empty')

# --- Validate transcript ---
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "[cost-tracker] Warning: subagent transcript not found, agent run not recorded."
  exit 0
fi

# --- Parse assistant entries from transcript ---
ASSISTANT_ENTRIES=$(grep -o '{.*}' "$TRANSCRIPT_PATH" 2>/dev/null \
  | jq -c 'select(.type == "assistant")' 2>/dev/null || true)

if [[ -z "$ASSISTANT_ENTRIES" ]]; then
  echo "[cost-tracker] Warning: no assistant turns found in subagent transcript, agent run not recorded."
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

RECORD=$(jq -cn \
  --arg  record_type        "agent_run" \
  --arg  session_id         "$SESSION_ID" \
  --arg  agent_id           "$AGENT_ID" \
  --arg  timestamp          "$TIMESTAMP" \
  --arg  model              "$MODEL" \
  --argjson input_tokens    "$INPUT_TOKENS" \
  --argjson output_tokens   "$OUTPUT_TOKENS" \
  --argjson cache_write_tokens "$CACHE_WRITE_TOKENS" \
  --argjson cache_read_tokens  "$CACHE_READ_TOKENS" \
  --argjson cost_usd        "$COST" \
  --arg  pricing            "$PRICING" \
  '{
    record_type:        $record_type,
    session_id:         $session_id,
    agent_id:           $agent_id,
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
