# content-seo

Site-level SEO intelligence layer for [content-stack](../README.md). Built on top of content-ops and powered by Google Search Console as the primary data source. Tracks what's performing, surfaces ranking opportunities, diagnoses individual pages with live GSC data, and injects keyword briefs into the content creation pipeline.

## What it does

| Skill | What it does |
|---|---|
| `/seo status` | Site-wide GSC performance: top pages by clicks, position movers, CTR outliers |
| `/seo opportunities` | Pages ranking 4–20 with the most untapped traffic, scored by missed clicks |
| `/seo diagnose <file>` | Deep-dive a page: live GSC data + technical audit + automatic content fixes |
| `/seo brief <topic>` | Keyword research brief before writing (uses DataForSEO, results cached) |
| `/seo init` | Setup wizard — configure GSC connection and per-content-type SEO rules |

## Quick start

### 1. Initialize content-ops first

content-seo requires content-ops to be set up. Run `/init` in content-ops before continuing.

### 2. Install

```bash
claude plugin add pcamarajr/content-stack/content-seo
```

### 3. Set up GSC service account

1. Create a service account in Google Cloud Console
2. Add it as a user in your GSC property settings
3. Download the JSON key and save it outside your repo (e.g. `~/.secrets/gsc-sa.json`)

```bash
# Option A: path in config (set during /seo init project)
# Option B: env var
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa.json"
```

### 4. Run setup

```
/seo init
```

Three rounds: `project` (GSC property + credentials path), `credentials` (verify access), `strategy` (SEO rules per content type).

### 5. Check your site's performance

```
/seo status
```

### 6. Find opportunities

```
/seo opportunities
```

### 7. Diagnose a page

```
/seo diagnose src/content/articles/en/my-article.md
```

## Requirements

- Google Search Console property (domain or URL-prefix)
- GSC service account with read access to the property
- [content-ops](../content-ops) initialized in the same project
- (Optional) DataForSEO account for `/seo brief` — [sign up](https://app.dataforseo.com/register)

## Configuration

Config lives in `.content-seo/config.md` (created by `/seo init`). Fields like `site_url`, `content_types`, and `content_pillars_path` are read from content-ops at runtime — not duplicated here.

See [config.example.md](./docs/config.example.md) for the full schema.

## content-ops integration

When content-ops is set up with DataForSEO credentials, `/write-content` automatically runs a keyword research phase (Phase 2.5) before drafting. The resulting `seo_keyword` is injected into the article frontmatter and used to guide the draft-writer agent.

## Roadmap

- GEO/AEO optimization (Generative Engine + Answer Engine Optimization)
- Automated hooks for post-publish SEO checks
