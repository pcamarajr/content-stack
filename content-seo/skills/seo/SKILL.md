---
name: seo
description: Site-level SEO intelligence. Routes to one of five workflows — status (site-wide GSC performance), opportunities (pages ranking 4–20), diagnose (deep-dive a page with GSC data + fixes), brief (keyword research before writing), or coverage (audit GSC indexing errors from a CSV export).
argument-hint: "<status|opportunities|diagnose|brief|coverage> [args]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, TodoWrite, AskUserQuestion
---

SEO intelligence skill for content sites. Routes to the appropriate workflow based on the first argument.

**Arguments:** $ARGUMENTS

---

## Phase 1: Load config (all subcommands)

### 1a: Parse argument

Parse `$ARGUMENTS`:

| Argument | Route |
|---|---|
| `status` | Status workflow |
| `opportunities` | Opportunities workflow |
| `diagnose <file>` | Diagnose workflow |
| `brief <topic>` | Brief workflow |
| `coverage [csv]` | Coverage workflow |
| `init [round]` | Delegate to init skill: read `skills/init/SKILL.md` and follow instructions |
| empty or unknown | Show usage (below) |

**Usage (shown on empty/unknown argument):**

```text
/seo <subcommand> [args]

  status              — Site-wide GSC performance: top pages, movers, CTR outliers
  opportunities       — Pages ranking 4–20 with the most untapped traffic
  diagnose <file>     — Deep-dive a page: GSC data + technical audit + content fixes
  brief <topic>       — Keyword research brief before writing (requires DataForSEO)
  coverage [csv]      — Audit GSC indexing errors: paste URLs from GSC or provide a CSV, find root causes, save report
  init [round]        — Setup wizard (project, credentials, strategy)
```

### 1b: Read .content-seo/config.md

**Hard stop if missing:** "content-seo is not configured. Run `/seo init` first."

Extract:
- `content_ops_config` — **hard stop if absent:** "content_ops_config is not set. Run `/seo init project` to link content-ops."
- `gsc_property`
- `gsc_credentials_path` (may be empty — gsc-reporter falls back to env var)
- `seo_rules`

### 1c: Read content-ops config

Read the file at `content_ops_config`. Extract:
- `site_url`
- `default_language`
- `content_types` (keys and paths)
- `content_pillars_path`
- `research_cache_ttl_days` (default: 30)

---

## Status workflow

### Step S1: Spawn gsc-reporter

Spawn the `gsc-reporter` agent via Task:

```text
Use the gsc-reporter agent.

gsc_property: [gsc_property]
credentials_path: [gsc_credentials_path]
query_type: site-wide
date_range: last_28_days
dimensions: page
include_comparison: true
```

### Step S2: Compute metrics

From the returned `GSC_DATA` and `COMPARISON_DATA` rows:

1. **Position movers** — for each page present in both periods, compute position change. Flag pages that gained or lost more than 2 positions.
2. **CTR outliers** — compute average CTR across all pages. Flag pages with impressions > 500 AND CTR less than half the site average.
3. **Top gainers** — pages with the largest positive position change (best 5).
4. **Top losers** — pages with the largest negative position change (worst 5).

### Step S3: Present report

```text
## SEO Status — [site_url]
Period: [start_date] to [end_date] vs prior 28 days

### Top pages by clicks
| Page | Clicks | Impressions | CTR | Position |
|---|---|---|---|---|
[top 10 rows sorted by clicks descending]

### Position movers
| Page | Position (current) | Position (prior) | Change |
|---|---|---|---|
[pages with >2 position change, sorted by absolute change descending]

### High impressions, low CTR (title/description problem)
| Page | Impressions | CTR | Site avg CTR |
|---|---|---|---|
[pages with >500 impressions and CTR < half site average]

→ Run /seo opportunities to see pages ranked 4–20 with untapped traffic.
→ Run /seo diagnose <file> to deep-dive any page.
```

---

## Opportunities workflow

### Step O1: Spawn gsc-reporter

Spawn the `gsc-reporter` agent via Task:

```text
Use the gsc-reporter agent.

gsc_property: [gsc_property]
credentials_path: [gsc_credentials_path]
query_type: site-wide
date_range: last_28_days
dimensions: page
include_comparison: false
```

### Step O2: Score and filter

From the returned rows:

1. Filter to pages with `position` between 4.0 and 20.0 (inclusive).
2. Score each page: `score = impressions × (1 - ctr)` — traffic being left on the table.
3. Sort descending by score.
4. Cap at top 15.

For each page, estimate the traffic gain if it moved to position 3:
- Average CTR at position 3 is approximately 10%. Use `est_gain = impressions × (0.10 - ctr)` (floor at 0).

### Step O3: Map pages to source files

For each page URL in the top 15:
- Derive the file path from the URL and `site_url` + `content_types` paths.
- Example: `https://mysite.com/en/articles/bitcoin-basics` → `src/content/articles/en/bitcoin-basics.md`
- Use Glob to verify the file exists. If it cannot be mapped, note "source file unknown".

### Step O4: Present report

```text
## SEO Opportunities — [site_url]
Pages ranking 4–20 with the most untapped traffic (last 28 days)

| # | Page | Position | Impressions | CTR | Est. gain to #3 | File |
|---|---|---|---|---|---|---|
[top 15 rows]

→ Run /seo diagnose <file> to deep-dive any of these pages.
```

---

## Diagnose workflow

**Arguments:** file path extracted from `$ARGUMENTS` after `diagnose `.

### Step D1: Resolve file and URL

1. Read the source file. Extract frontmatter: `title`, `description`, `tags`, `seo_keyword` (if present).
2. Derive the live URL from the file path and `site_url`:
   - Strip `content_types.<type>.path` prefix and language segment from the file path
   - Append to `site_url`
   - Example: `src/content/articles/en/bitcoin-basics.md` → `https://mysite.com/en/articles/bitcoin-basics`
3. If the derivation is ambiguous, ask the user to confirm the URL.

### Step D2: Determine target keyword

- If `seo_keyword` is present in frontmatter → use it. Skip keyword proposal.
- Otherwise → propose one from the article title + content-ops pillars context. Show it to the user and confirm.

### Step D3: Spawn gsc-reporter (page-specific)

Spawn the `gsc-reporter` agent via Task:

```text
Use the gsc-reporter agent.

gsc_property: [gsc_property]
credentials_path: [gsc_credentials_path]
query_type: page-specific
url_filter: [derived live URL]
date_range: last_28_days
dimensions: both
include_comparison: false
```

### Step D4: Spawn page-analyzer

Determine the content type from the file path (match against `content_types` paths). Get `seo_rules` for that type from config.

Read target audience from the content-ops content strategy file (`content_strategy` path).

Spawn the `page-analyzer` agent via Task:

```text
Use the page-analyzer agent.

Source file: [file path]
Live URL: [derived URL]
Site URL: [site_url from content-ops]
Locale: [default_language]
Target audience: [from content strategy]
SEO rules: [seo_rules for this content type]
gsc_data:
  position: [avg position from gsc-reporter]
  clicks: [total clicks]
  impressions: [total impressions]
  ctr: [avg CTR]
  top_queries: [list of top 10 queries by impressions from gsc-reporter, with impressions count each]
```

### Step D5: Build diagnosis report

```text
## SEO Diagnosis: [title]
URL: [url]
GSC (last 28 days): position [N.N] · [N] clicks · [N] impressions · [N%] CTR
Top queries: [top 5 from gsc-reporter, comma-separated]

### Fixed in source file
[FIXED section from page-analyzer]

### Content issues detected
[NEEDS_OPTIMIZATION section from page-analyzer]

### Keyword mismatches (pages rank for these but content doesn't cover them)
[KEYWORD_MISMATCHES section from page-analyzer, or "none" if section absent]

### Manual action required
[MANUAL_ACTION section from page-analyzer]
```

### Step D6: Trigger content-ops fixes (if content issues exist)

If `NEEDS_OPTIMIZATION` or `KEYWORD_MISMATCHES` sections are non-empty:

Ask the user:

```text
Content issues were found. Trigger content-ops agents to fix them?

  style-enforcer — structure, tone, length issues
  draft-writer   — thin sections and keyword gaps (targeted rewrite, not full article)

Fix now? (yes / no — I'll handle it manually)
```

Use AskUserQuestion with "Yes, fix now" / "No, I'll handle it manually".

**If yes:**

Spawn `style-enforcer` agent via Task for structure/tone/length issues (if any in NEEDS_OPTIMIZATION):

```text
Use the style-enforcer agent to review [file path].
Content type: [content type]
Config:
  word_range: [content_types.<type>.word_range from content-ops config]
  guidelines: [content_types.<type>.guidelines from content-ops config]
  reference_content: [reference_content from content-ops config]
Apply must-fix issues only. Return changes made.
```

If keyword mismatches or thin sections exist, spawn `draft-writer` agent via Task with a targeted brief:

```text
Use the draft-writer agent.

Mode: targeted rewrite (NOT a full article — patch specific issues only)
File to update: [file path]
Content type: [content type]
Author: [from content-ops config]

Issues to address:
[List each KEYWORD_MISMATCH: "Add '[query]' to intro or a relevant heading/section"]
[List each thin section from NEEDS_OPTIMIZATION: "Expand section '[heading]' — currently under 50 words"]

Constraints:
- Do not restructure the article
- Do not add more than 200 words total
- Preserve all frontmatter fields
- Add the target keyword "[seo_keyword or proposed keyword]" in the first 100 words if not already present
```

### Step D7: Write seo_keyword to frontmatter

After all fixes (whether content-ops agents ran or not), if `seo_keyword` is not already in frontmatter:

Add `seo_keyword: "[target keyword]"` to the article frontmatter.

### Step D8: Commit

```bash
git add [source file path]
git commit -m "seo: diagnose and fix \"[title]\""
```

---

## Brief workflow

**Arguments:** topic extracted from `$ARGUMENTS` after `brief `.

### Step B1: Check DataForSEO credentials

```bash
[ -n "$DATAFORSEO_LOGIN" ] && [ -n "$DATAFORSEO_PASSWORD" ] && echo "ok" || echo "missing"
```

**Hard stop if missing:**

```text
/seo brief requires DataForSEO credentials.

  DATAFORSEO_LOGIN    — [set | not set]
  DATAFORSEO_PASSWORD — [set | not set]

Set them as environment variables and re-run.
Get your API password at: https://app.dataforseo.com/api-access
```

### Step B2: Check for existing seo_keyword (if called with a file path)

If the argument is a file path rather than a plain topic:
- Read the file
- If `seo_keyword` is set in frontmatter → ask: "Keyword `[keyword]` is already targeted. Re-research?" with options "Yes, re-research" / "No, skip". Skip if no.

### Step B3: Check keyword cache

Derive cache slug from topic: lowercase, spaces and special chars → hyphens.

Check `.content-seo/keyword-cache/[slug].json`:

```bash
[ -f ".content-seo/keyword-cache/[slug].json" ] && cat ".content-seo/keyword-cache/[slug].json" || echo "cache_miss"
```

If cache hit: check `timestamp` field against `research_cache_ttl_days` (from content-ops config, default 30).
- Fresh (within TTL) → use cached data. Skip to Step B6.
- Stale → proceed with DataForSEO call.

### Step B4: Propose target keyword

Using the topic and content-ops pillars (read pillar files from `content_pillars_path` if set):

Propose a primary keyword and show it to the user:

```text
Proposed primary keyword: "[keyword]"

Based on: topic "[topic]" + pillars context

Confirm this keyword, or enter your own:
```

Use AskUserQuestion. If called from write-content in autonomous/backlog mode → auto-confirm the proposed keyword without asking.

### Step B5: Spawn keyword-researcher

Spawn the `keyword-researcher` agent via Task:

```text
Use the keyword-researcher agent.

Keyword: [confirmed keyword]
Locale: [default_language from content-ops]
Audience: [from content strategy]
Pillars context: [pillar names, comma-separated]
```

After the agent returns, write the cache:

Create directory if needed: `mkdir -p .content-seo/keyword-cache/`

Write `.content-seo/keyword-cache/[slug].json`:

```json
{
  "topic": "[topic]",
  "keyword": "[primary keyword]",
  "timestamp": "[ISO 8601 now]",
  "ttl_days": [research_cache_ttl_days],
  "volume": [monthly search volume],
  "competition": "[competition level]",
  "related_keywords": [
    { "keyword": "...", "volume": N },
    ...
  ],
  "content_gaps": ["...", "...", "..."]
}
```

### Step B6: Return brief

```text
## SEO Brief: [topic]

Primary keyword: [keyword] — [volume]/mo · [competition]

Related keywords:
  [keyword 1] — [volume]/mo
  [keyword 2] — [volume]/mo
  [keyword 3] — [volume]/mo
  [keyword 4] — [volume]/mo
  [keyword 5] — [volume]/mo

Content gaps to cover:
  1. [gap 1]
  2. [gap 2]
  3. [gap 3]

[If cache was used: "Cached result from [date] — re-run with fresh data after [expiry date]"]
```

**If called standalone:** Ask "Save this brief to a file for reference?" with options "Yes, save" / "No thanks". If yes, write to `.content-seo/briefs/[slug].md`.

**If called from write-content:** Return the brief object to the orchestrator. Do not commit, do not save file.

---

## Coverage workflow

**Arguments:** optional CSV path extracted from `$ARGUMENTS` after `coverage `.

### Step C1: Resolve coverage input

Extract what follows `coverage ` from `$ARGUMENTS`.

- If it's a non-empty string pointing to an existing file → `mode: csv`, `csv_path: [value]`. Proceed to Step C2.
- Otherwise (empty argument, or file not found) → prompt the user.

**If no valid CSV was provided,** use AskUserQuestion:

```text
How would you like to provide the GSC coverage data?

Note: GSC's Export button only downloads up to 1,000 representative examples and
doesn't produce a clean url/reason table. The reliable approach is to open each
error type in GSC → copy the URLs → paste them here.

  A — Paste URLs directly: paste the URL list for each error type in any format;
      just describe which error type each group belongs to.

  B — Provide a CSV file path: build a CSV with columns `url` and `reason`
      and enter the path (e.g. ~/Downloads/gsc-errors.csv).
```

Options: "Paste URLs now (A)" / "Provide CSV path (B)"

**If user chooses A (paste):**

Use AskUserQuestion: "Paste your URL list. Include the error type for each group — any format works:"

Set `mode: free_form`, `free_form_input: [pasted text]`. Proceed to Step C2.

**If user chooses B (CSV path):**

Use AskUserQuestion: "Enter the CSV file path:"

Validate file exists (`[ -f "[path]" ]`). If not found, ask once more. If still not found, hard-stop with: "File not found: [path]".

Set `mode: csv`, `csv_path: [path]`. Proceed to Step C2.

### Step C2: Spawn coverage-auditor

Spawn the `coverage-auditor` agent via Task:

```text
Use the coverage-auditor agent.

input_mode: [csv or free_form]
csv_path: [csv_path — only if mode is csv]
free_form_input: [free_form_input — only if mode is free_form]
site_url: [site_url from content-ops config]
content_types: [content_types from content-ops config]
```

### Step C3: Format and save report

Parse the `COVERAGE_FINDINGS` returned by the agent and write:

**Compute today's date:**

```bash
python3 -c "from datetime import date; print(date.today().isoformat())"
```

**Create directory if needed:**

```bash
mkdir -p .content-seo/coverage
```

**Write `.content-seo/coverage/[date].md`** with this structure:

```markdown
---
date: [date]
csv_source: [csv_path]
total_analyzed: N
---

## Coverage Audit — [site_url]
Source: [csv_path] · [N] URLs analyzed · [date]

### Summary
| Category | Count |
|---|---|
[one row per BUCKET + UNRESOLVED]

---

### [Reason] (N URLs)

**Likely root cause:** [codebase_finding]
**Recommended action:** [recommended_action]

| URL | Source file | Finding | HTTP |
|---|---|---|---|
[one row per URL in bucket]

---
[repeat per bucket]

### Could not determine root cause (N URLs)

| URL | GSC Reason | HTTP Status | Notes |
|---|---|---|---|
[UNRESOLVED rows]

---

### Next steps
[checklist item per non-empty bucket with recommended_action]
- [ ] Re-run `/seo coverage` after fixes to verify resolution
```

### Step C4: Confirm to user

```text
✅ Coverage audit complete

  [N] URLs analyzed · [N] errors · [N] excluded · [N] unresolved

  Report saved: .content-seo/coverage/[date].md

  Top issues:
  [list top 3 buckets by count with recommended_action]

→ Share the report with a coding agent to apply fixes.
```
