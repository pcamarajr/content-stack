#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Constants (substituted by /astro-builder:init lighthouse)
# ---------------------------------------------------------------------------
PORT=__PORT__
CATEGORIES="__CATEGORIES__"
THRESHOLD_PERFORMANCE=__PERF_THRESHOLD__
THRESHOLD_ACCESSIBILITY=__ACC_THRESHOLD__
THRESHOLD_BEST_PRACTICES=__BP_THRESHOLD__
THRESHOLD_SEO=__SEO_THRESHOLD__
LIGHTHOUSE_CONFIG=".astro-builder/lighthouse.json"
REPORT_DIR=".lighthouseci"

# ---------------------------------------------------------------------------
# Section 3 — Parse git pre-push stdin
# ---------------------------------------------------------------------------
ZERO_SHA="0000000000000000000000000000000000000000"
CHANGED_FILES=""

while IFS=' ' read -r local_ref local_sha remote_ref remote_sha; do
  # Deletion push — skip
  [ "$local_sha" = "$ZERO_SHA" ] && continue

  if [ "$remote_sha" = "$ZERO_SHA" ]; then
    # New branch — diff from the initial commit
    files=$(git diff --name-only "$local_sha" 2>/dev/null || true)
  else
    files=$(git diff --name-only "${remote_sha}..${local_sha}" 2>/dev/null || true)
  fi
  CHANGED_FILES="${CHANGED_FILES}${files}"$'\n'
done

# Deduplicate and remove blank lines
CHANGED_FILES=$(echo "$CHANGED_FILES" | sort -u | grep -v '^$' || true)

# No changed files — nothing to audit
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Section 4 — Check page-affecting patterns
# ---------------------------------------------------------------------------
PAGE_PATTERNS="src/content/ src/pages/ src/page-views/ src/layouts/ src/components/ astro.config"
MATCHED=false
GLOBAL_CHANGE=false

for pattern in $PAGE_PATTERNS; do
  if echo "$CHANGED_FILES" | grep -q "$pattern"; then
    MATCHED=true
    # Layout/component changes affect all pages
    if echo "$pattern" | grep -qE "src/layouts/|src/components/"; then
      if echo "$CHANGED_FILES" | grep -qE "src/layouts/|src/components/"; then
        GLOBAL_CHANGE=true
      fi
    fi
  fi
done

if [ "$MATCHED" = "false" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Section 5 — Map changed files to URLs (read lighthouse.json with jq)
# ---------------------------------------------------------------------------
URLS=""

if ! command -v jq >/dev/null 2>&1; then
  echo "[lighthouse] ⚠️  jq not found — cannot parse lighthouse.json for URL mapping."
  echo "[lighthouse]    Install jq: brew install jq (macOS) or apt install jq (Linux)"
  echo "[lighthouse]    Falling back to static pages only."
  # Attempt python3 fallback for staticPages
  if command -v python3 >/dev/null 2>&1 && [ -f "$LIGHTHOUSE_CONFIG" ]; then
    URLS=$(python3 -c "
import json, sys
with open('$LIGHTHOUSE_CONFIG') as f:
    cfg = json.load(f)
for p in cfg.get('staticPages', ['/']):
    print(p)
" 2>/dev/null || echo "/")
  else
    URLS="/"
  fi
else
  # jq is available
  STATIC_PAGES=$(jq -r '.staticPages[]?' "$LIGHTHOUSE_CONFIG" 2>/dev/null || echo "/")
  FALLBACK_MAX=$(jq -r '.fallbackMaxPages // 10' "$LIGHTHOUSE_CONFIG" 2>/dev/null || echo "10")

  if [ "$GLOBAL_CHANGE" = "true" ]; then
    # Fallback strategy: static pages + most-recently modified file per urlMap pattern
    URLS="$STATIC_PAGES"

    while IFS= read -r entry; do
      pattern=$(echo "$entry" | jq -r '.key')
      url_template=$(echo "$entry" | jq -r '.value')

      # Find most-recently modified file matching the glob pattern
      # Guard against empty find output: BSD xargs (macOS) runs the command even with no input
      _found=$(find . -path "./$pattern" -type f 2>/dev/null)
      latest_file=""
      [ -n "$_found" ] && latest_file=$(echo "$_found" | xargs ls -t 2>/dev/null | head -1 || true)

      if [ -n "$latest_file" ]; then
        locale=$(basename "$(dirname "$latest_file")")
        slug=$(basename "$latest_file" .md)
        url=$(echo "$url_template" | sed "s/{locale}/$locale/g" | sed "s/{slug}/$slug/g")
        URLS="${URLS}"$'\n'"$url"
      fi
    done < <(jq -c '.urlMap | to_entries[]?' "$LIGHTHOUSE_CONFIG" 2>/dev/null || true)

    # Cap at fallbackMaxPages
    URLS=$(echo "$URLS" | sort -u | grep -v '^$' | head -n "$FALLBACK_MAX")
  else
    # Per-file mapping
    URLS="$STATIC_PAGES"

    while IFS= read -r file; do
      # src/pages/{locale}/{path}.astro → /{locale}/{path}
      if echo "$file" | grep -q "^src/pages/"; then
        path_part=$(echo "$file" | sed 's|^src/pages/||' | sed 's|\.astro$||' | sed 's|/index$||')
        URLS="${URLS}"$'\n'"/$path_part"
        continue
      fi

      # src/content/{collection}/{locale}/{slug}.md → look up urlMap
      if echo "$file" | grep -q "^src/content/"; then
        collection=$(echo "$file" | sed 's|^src/content/||' | cut -d/ -f1)
        locale=$(echo "$file" | sed 's|^src/content/||' | cut -d/ -f2)
        slug=$(basename "$file" .md)

        url_template=$(jq -r --arg coll "$collection" '
          .urlMap | to_entries[] |
          select(.key | startswith("src/content/\($coll)/")) |
          .value
        ' "$LIGHTHOUSE_CONFIG" 2>/dev/null | head -1 || true)

        if [ -n "$url_template" ]; then
          url=$(echo "$url_template" | sed "s/{locale}/$locale/g" | sed "s/{slug}/$slug/g")
          URLS="${URLS}"$'\n'"$url"
        fi
      fi
      # Non-matching files: silently ignored
    done <<< "$CHANGED_FILES"

    URLS=$(echo "$URLS" | sort -u | grep -v '^$')
  fi
fi

# Final deduplication
URLS=$(echo "$URLS" | sort -u | grep -v '^$' || true)

if [ -z "$URLS" ]; then
  echo "[lighthouse] No pages to audit for changed files."
  exit 0
fi

# ---------------------------------------------------------------------------
# Section 6 — Build project
# ---------------------------------------------------------------------------
echo "[lighthouse] Building project..."
pnpm build || { echo "[lighthouse] ❌ Build failed. Fix errors and retry push."; exit 1; }

# ---------------------------------------------------------------------------
# Section 7 — Find Chrome via Playwright
# ---------------------------------------------------------------------------
CHROME_PATH=$(node -e "
  try { const { chromium } = require('playwright'); console.log(chromium.executablePath()); }
  catch(e) { process.exit(1); }
" 2>/dev/null) || {
  echo "[lighthouse] ❌ Playwright Chromium not found."
  echo "[lighthouse]    Run: pnpm add -D playwright && pnpm exec playwright install chromium"
  exit 1
}
export CHROME_PATH

# ---------------------------------------------------------------------------
# Section 8 — Start preview server
# ---------------------------------------------------------------------------
echo "[lighthouse] Starting preview server on port $PORT..."
pnpm preview --port "$PORT" >/dev/null 2>&1 &
PREVIEW_PID=$!
trap 'kill "$PREVIEW_PID" 2>/dev/null || true' EXIT

RETRIES=30
until curl -sf "http://localhost:${PORT}" >/dev/null 2>&1; do
  RETRIES=$((RETRIES - 1))
  if [ "$RETRIES" -eq 0 ]; then
    echo "[lighthouse] ❌ Preview server timeout on port $PORT."
    exit 1
  fi
  sleep 1
done

echo "[lighthouse] Preview server ready."

# ---------------------------------------------------------------------------
# Section 9 — Run Lighthouse per URL, collect scores
# ---------------------------------------------------------------------------
mkdir -p "$REPORT_DIR"
FAILED=0
REPORT_LINES=""

while IFS= read -r URL_PATH; do
  [ -z "$URL_PATH" ] && continue

  FULL_URL="http://localhost:${PORT}${URL_PATH}"
  REPORT_FILE="${REPORT_DIR}/report-$(echo "$URL_PATH" | tr '/' '-').json"

  echo "[lighthouse] Auditing $URL_PATH ..."

  CHROME_PATH="$CHROME_PATH" pnpm exec lighthouse "$FULL_URL" \
    --only-categories="$CATEGORIES" \
    --output=json \
    --output-path="$REPORT_FILE" \
    --chrome-flags="--headless=new --no-sandbox --disable-gpu" \
    --quiet 2>/dev/null || {
    echo "[lighthouse] ⚠️  Audit failed for $URL_PATH — skipping."
    continue
  }

  if ! command -v jq >/dev/null 2>&1; then
    echo "[lighthouse] ⚠️  jq not found — skipping score comparison for $URL_PATH."
    REPORT_LINES="${REPORT_LINES}| $URL_PATH | ? | ? | ? | ? |"$'\n'
    continue
  fi

  SCORE_PERF=$(jq '(.categories.performance.score // 0) * 100 | floor' "$REPORT_FILE" 2>/dev/null || echo "0")
  SCORE_ACC=$(jq '(.categories.accessibility.score // 0) * 100 | floor' "$REPORT_FILE" 2>/dev/null || echo "0")
  SCORE_BP=$(jq '(.categories["best-practices"].score // 0) * 100 | floor' "$REPORT_FILE" 2>/dev/null || echo "0")
  SCORE_SEO=$(jq '(.categories.seo.score // 0) * 100 | floor' "$REPORT_FILE" 2>/dev/null || echo "0")

  ROW_FAILED=0
  FAIL_REASONS=""

  if [ "$SCORE_PERF" -lt "$THRESHOLD_PERFORMANCE" ]; then
    ROW_FAILED=1; FAILED=1
    FAIL_REASONS="${FAIL_REASONS} performance=${SCORE_PERF}<${THRESHOLD_PERFORMANCE}"
  fi
  if [ "$SCORE_ACC" -lt "$THRESHOLD_ACCESSIBILITY" ]; then
    ROW_FAILED=1; FAILED=1
    FAIL_REASONS="${FAIL_REASONS} accessibility=${SCORE_ACC}<${THRESHOLD_ACCESSIBILITY}"
  fi
  if [ "$SCORE_BP" -lt "$THRESHOLD_BEST_PRACTICES" ]; then
    ROW_FAILED=1; FAILED=1
    FAIL_REASONS="${FAIL_REASONS} best-practices=${SCORE_BP}<${THRESHOLD_BEST_PRACTICES}"
  fi
  if [ "$SCORE_SEO" -lt "$THRESHOLD_SEO" ]; then
    ROW_FAILED=1; FAILED=1
    FAIL_REASONS="${FAIL_REASONS} seo=${SCORE_SEO}<${THRESHOLD_SEO}"
  fi

  STATUS_MARK=""
  [ "$ROW_FAILED" -eq 1 ] && STATUS_MARK=" ❌" || STATUS_MARK=" ✅"

  REPORT_LINES="${REPORT_LINES}| ${URL_PATH}${STATUS_MARK} | ${SCORE_PERF} | ${SCORE_ACC} | ${SCORE_BP} | ${SCORE_SEO} |"$'\n'

  if [ "$ROW_FAILED" -eq 1 ]; then
    REPORT_LINES="${REPORT_LINES}_Failed:${FAIL_REASONS}_"$'\n'
    # Print top 5 failed audits
    if [ -f "$REPORT_FILE" ]; then
      AUDIT_DETAILS=$(jq -r '[.audits | to_entries[] | select(.value.score != null and .value.score < 1)] | .[:5][] | "  - " + .value.title' "$REPORT_FILE" 2>/dev/null || true)
      if [ -n "$AUDIT_DETAILS" ]; then
        REPORT_LINES="${REPORT_LINES}${AUDIT_DETAILS}"$'\n'
      fi
    fi
  fi
done <<< "$URLS"

# ---------------------------------------------------------------------------
# Section 10 — Print markdown report and exit
# ---------------------------------------------------------------------------
echo ""
echo "## Lighthouse Audit Report"
echo ""
echo "| URL | Perf | A11y | Best Practices | SEO |"
echo "|-----|------|------|----------------|-----|"
echo "$REPORT_LINES"

if [ "$FAILED" -eq 1 ]; then
  echo "❌ Push blocked. Fix the issues above and retry."
  echo "Full reports: .lighthouseci/"
  exit 1
else
  echo "✅ All Lighthouse scores pass."
  exit 0
fi
