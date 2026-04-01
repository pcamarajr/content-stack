---
name: optimize
description: Optimize content using DataForSEO keyword data. Rewrites the content file for better keyword coverage, semantic depth, and relevance. Requires /init credentials.
argument-hint: <file-path>
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch, Task, TodoWrite, AskUserQuestion
---

Optimize content with DataForSEO keyword intelligence. Rewrites the source file for better keyword coverage and semantic relevance.

**File:** $ARGUMENTS

---

## Phase 1: Load config

Read `.content-seo/config.md` → parse YAML frontmatter.

**Hard stops:**
- If `.content-seo/config.md` does not exist → "Run `/init project` first."
- Check credentials with Bash: `[ -n "$DATAFORSEO_LOGIN" ] && [ -n "$DATAFORSEO_PASSWORD" ] && echo "ok" || echo "missing"`
  If missing → "Run `/init credentials` to configure your DataForSEO API credentials."

Extract: `site_url`, `default_locale`, `target_audience`, `pillars`, `seo_rules`.

---

## Phase 2: Read content file

Read `$ARGUMENTS`. Extract:
- `title` from frontmatter
- `tags` or existing keywords from frontmatter
- Approximate word count (count paragraphs / estimate)
- Existing `description` or `excerpt`
- Body text summary (first 300 words)

Detect the content type by matching the file path against `seo_rules` keys (or content-ops `content_types` if available). Load the matching `seo_rules` entry.

---

## Phase 3: Determine target keyword

Using the article title, tags, body summary, and configured `pillars`, propose the best primary keyword.

Show:

```text
Based on your content and SEO pillars, I suggest targeting:

  Primary keyword: "[suggested keyword]"

  Reasoning: [1–2 sentence explanation linking it to a pillar and the content topic]
```

Use AskUserQuestion with options:
- "Use this keyword"
- "Use a different keyword — I'll type it"

Wait for confirmation before continuing.

---

## Phase 4: Delegate to keyword-researcher agent

Pass a brief to the `keyword-researcher` agent via Task:

```text
Research keyword data for: "[confirmed target keyword]"

Locale:    [default_locale]
Audience:  [target_audience]
Pillars:   [pillars list]

Return: search volume, competition, top 5 related keywords with volumes, and 3 content gap recommendations.
Credentials are in DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD environment variables.
```

Wait for the agent to return the structured KEYWORD / RELATED_KEYWORDS / CONTENT_GAPS report.

---

## Phase 5: Rewrite content

Using the keyword research data, rewrite `$ARGUMENTS` to improve:

1. **Meta description** — Include the primary keyword, stay within `meta_description_length` range from SEO rules
2. **Title** — Include the primary keyword naturally if not already present
3. **Introduction** — Use the primary keyword in the first 100 words if missing
4. **Headings** — Work related keywords into H2/H3 headings where natural
5. **Content gaps** — Add or expand sections for each of the 3 content gap topics identified by the researcher
6. **Semantic coverage** — Weave related keywords naturally throughout the body

**Constraints — do not violate these:**
- Every keyword use must read naturally — no keyword stuffing
- Preserve the existing content structure and voice as much as possible
- Do not add more than 30% net-new content unless the article is below `min_word_count`
- Only modify frontmatter fields: `title`, `description`/`excerpt`, `tags`
- Do not change `date`, `author`, `translationKey`, or any relational frontmatter fields

Edit `$ARGUMENTS` directly with the changes.

---

## Phase 6: Report

```text
## SEO Optimization: [title]

### Keyword strategy
  Primary keyword:  [keyword] — [volume] searches/mo · [low|medium|high] competition
  Related keywords: [top 5 with volumes]

### Changes made
- [specific change: "Added keyword to intro paragraph"]
- [specific change: "Updated H2 'X' to include related keyword 'Y'"]
- [specific change: "Added new section: 'Z' (content gap)"]

### Word count
  Before: ~[N] words → After: ~[M] words
```

---

## Phase 7: Commit

```
seo: optimize "[title]" for "[target keyword]"
```
