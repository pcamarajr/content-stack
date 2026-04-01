---
# content-seo plugin configuration — Reference only, not copied.
# Each /init round appends its own section to .content-seo/config.md.
# Run /init project to create a minimal starting config.

# Written by /init project
site_url: "https://yoursite.com"
default_locale: "en"
target_audience: "Developers building static content sites who want better organic reach without an SEO agency."
content_ops_config: ".content-ops/config.md"   # optional — omit if not using content-ops

# Written by /init strategy
pillars:
  - "static site generators"
  - "content management"
  - "developer tooling"

seo_rules:
  article:
    min_word_count: 800
    meta_description_length: [150, 160]
    h1_includes_keyword: true
    target_keywords_per_article: 1
  glossary:
    min_word_count: 50
    meta_description_length: [100, 160]
    h1_includes_keyword: true
    target_keywords_per_article: 1
---

# content-seo Configuration Reference

This file documents every config field and which `/init` round writes it. Skills and agents read `.content-seo/config.md` (not this file).

**To create your config:** Run `/init project` — it writes a minimal config. Each subsequent `/init` round appends its section.

**Important:** If `.content-seo/config.md` doesn't exist, skills will stop and tell you to run `/init project`.

## Schema Reference

| Key | Type | Description |
|---|---|---|
| `site_url` | string | Base URL of your published site (e.g. `https://mysite.com`) |
| `default_locale` | string | Primary locale code (e.g. `en`, `pt`) |
| `target_audience` | string | 1–2 sentence description of who you're writing for |
| `content_ops_config` | string | Path to content-ops config (optional — enriches context) |
| `pillars` | string[] | Main topic themes to own in search (2–5 pillars) |
| `seo_rules.<type>.min_word_count` | number | Minimum words for this content type to rank |
| `seo_rules.<type>.meta_description_length` | number[] | Target `[min, max]` char range for meta descriptions |
| `seo_rules.<type>.h1_includes_keyword` | boolean | Whether H1 must include the target keyword |
| `seo_rules.<type>.target_keywords_per_article` | number | How many primary keywords to optimize for |

## Environment Variables

These are **never written to files**. Set them in your shell:

| Variable | Description |
|---|---|
| `DATAFORSEO_LOGIN` | Your DataForSEO account email |
| `DATAFORSEO_PASSWORD` | Your DataForSEO API password (not your login password) |

Get credentials at [app.dataforseo.com/api-access](https://app.dataforseo.com/api-access).

## .content-seo/ Layout

| File | Purpose |
|---|---|
| `config.md` | Plugin configuration (created by `/init`) |
