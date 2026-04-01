# Round: Strategy

Goal: Define SEO content pillars and per-content-type SEO rules in `.content-seo/config.md`.

---

## Phase 1: Load context

Read silently:

- `.content-seo/config.md` → get `target_audience`, `default_locale`, `content_ops_config`, existing `pillars` and `seo_rules` if present
- If `content_ops_config` is set, read that file → get `content_types` keys and paths
- `package.json` → site name/description for additional context

**Hard stop:** If `.content-seo/config.md` does not exist or `site_url` is not set → tell the user to run `/init project` first and stop.

---

## Phase 2: Existing strategy check

If `pillars` and `seo_rules` are already set:

```text
I found an existing strategy config:

  Pillars: [list of pillars]
  SEO rules: [list of content types configured]

Want to:
  A — Keep it and skip this round
  B — Review and update
```

- If **A**: output "Strategy already set. Setup is complete — run `/audit` or `/optimize` to get started." and stop.
- If **B**: continue to Phase 3.

---

## Phase 3: Interview

### Question 1: Content pillars

Using the `target_audience` from config as context, suggest 3–5 pillar candidates before asking.

```text
What are the 2–5 main topic pillars for your site's SEO strategy?

These are the broad themes you want to own in search. Every piece of content should connect to one of them.

[Show suggested pillars based on target_audience]

Confirm these, adjust them, or provide your own.
```

Use AskUserQuestion with the suggested pillars as options plus "I'll define my own".

### Question 2: Per-content-type word count targets

**Determine which content types to configure:**

- **If content-ops is configured** (`content_ops_config` is set and the file exists): read `content_types` from it. Use only the keys actually defined there. If the content-ops config has a `glossary` block with `enabled: true`, include the glossary content type; otherwise do not assume a glossary exists.
- **If content-ops is not configured**: ask the user to list their content types before proceeding.

  ```text
  What content types does your site publish?
  (e.g. articles, posts, guides — one per line or comma-separated)
  ```

  Use their answer as the list of types to configure.

For each confirmed content type, ask once using AskUserQuestion:

```text
For [content type]: what's your minimum target word count for SEO?
```

Options:
- Short (50–300 words)
- Medium (600–1,000 words)
- Long (1,200–2,000 words) — in-depth guides and pillar pages

---

## Phase 4: Write config

Update `.content-seo/config.md` — append the strategy section. Preserve all existing fields exactly.

```yaml
# Written by /init strategy
pillars:
  - "[pillar 1]"
  - "[pillar 2]"

seo_rules:
  [content_type]:
    min_word_count: [answer]
    meta_description_length: [150, 160]
    h1_includes_keyword: true
    target_keywords_per_article: 1
```

Add one `seo_rules` entry per content type collected.

---

## Phase 5: Confirm

```text
✅ Strategy saved to .content-seo/config.md

  Pillars: [list]
  SEO rules: [content types configured]

Setup complete. You can now use:
  /audit <file-path>    — Fetch the live page and fix technical SEO issues
  /optimize <file-path> — Rewrite content using DataForSEO keyword data
```
