---
# content-seo plugin configuration — Reference only, not copied.
# Each /seo init round appends its own section to .content-seo/config.md.
# Run /seo init project to create a minimal starting config.

# Written by /seo init project
content_ops_config: ".content-ops/config.md"   # required — hard stop if absent
gsc_property: "sc-domain:yoursite.com"          # GSC property URL
gsc_credentials_path: "/path/to/sa.json"        # omit to use GOOGLE_APPLICATION_CREDENTIALS

# Written by /seo init strategy
seo_rules:
  article:
    meta_description_length: [150, 160]
    h1_includes_keyword: true
  glossary:
    meta_description_length: [100, 160]
    h1_includes_keyword: true
---

# content-seo Configuration Reference

This file documents every config field and which `/seo init` round writes it. Skills and agents read `.content-seo/config.md` (not this file).

**To create your config:** Run `/seo init project` — it writes a minimal config. Each subsequent round appends its section.

**Important:** If `.content-seo/config.md` doesn't exist, skills will stop and tell you to run `/seo init project`.

**Important:** `content-seo` requires `content-ops` to be initialized first. Fields like `site_url`, `default_language`, `content_types`, `content_pillars_path`, and `word_range` are read from `.content-ops/config.md` at runtime — not stored in this config.

## Schema Reference

| Key | Type | Description |
|---|---|---|
| `content_ops_config` | string | Path to content-ops config — **required**. Hard stop if absent or file missing. |
| `gsc_property` | string | GSC property URL (e.g. `sc-domain:yoursite.com` or `https://yoursite.com/`) |
| `gsc_credentials_path` | string | Path to service account JSON key. Omit to use `GOOGLE_APPLICATION_CREDENTIALS` env var. |
| `seo_rules.<type>.meta_description_length` | number[] | Target `[min, max]` char range for meta descriptions |
| `seo_rules.<type>.h1_includes_keyword` | boolean | Whether H1 must include the target keyword |

## Fields Read from content-ops at Runtime

These are NOT stored in `.content-seo/config.md`:

| Field | Source in content-ops config |
|---|---|
| Site URL | `site_url` (or detected from framework) |
| Default language | `default_language` |
| Target audience | `content_strategy` file |
| Content pillars | `content_pillars_path` |
| Min word count | `content_types.<type>.word_range[0]` |
| Research cache TTL | `research_cache_ttl_days` |

## Environment Variables

| Variable | Description | Required for |
|---|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to GSC service account JSON | GSC (if `gsc_credentials_path` not set) |
| `DATAFORSEO_LOGIN` | DataForSEO account email | `/seo brief` only |
| `DATAFORSEO_PASSWORD` | DataForSEO API password (not login password) | `/seo brief` only |

## .content-seo/ Layout

| File / Directory | Purpose |
|---|---|
| `config.md` | Plugin configuration (created by `/seo init`) |
| `keyword-cache/[slug].json` | Per-keyword DataForSEO cache. TTL from content-ops `research_cache_ttl_days` (default 30 days). |
