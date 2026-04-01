# content-seo

SEO audit and optimization plugin for [content-stack](../README.md). Analyzes live published pages for technical SEO issues, fixes them in the source markdown, and rewrites content using DataForSEO keyword intelligence.

## What it does

| Skill | What it does |
|---|---|
| `/init` | Setup wizard — configure site URL, credentials, and SEO strategy |
| `/audit <file>` | Fetch live page, fix technical issues (title, meta, alt text), report content gaps |
| `/optimize <file>` | Rewrite content using DataForSEO keyword data for better search coverage |

## Quick start

### 1. Install

```bash
claude plugin add pcamarajr/content-stack/content-seo
```

### 2. Set credentials

```bash
export DATAFORSEO_LOGIN="your@email.com"
export DATAFORSEO_PASSWORD="your_api_password"
```

Credentials are **never written to files**. Get your API password at [app.dataforseo.com/api-access](https://app.dataforseo.com/api-access).

### 3. Run setup

```
/init
```

Runs in three rounds: `project` (site URL + audience), `credentials` (verify API keys), `strategy` (pillars + per-content-type rules).

### 4. Audit a page

```
/audit src/content/articles/en/my-article.md
```

Fetches the live page, fixes technical SEO issues in the source file, and reports what `/optimize` can improve.

### 5. Optimize content

```
/optimize src/content/articles/en/my-article.md
```

Researches the target keyword via DataForSEO and rewrites the content for better search coverage.

## Requirements

- DataForSEO account — [sign up](https://app.dataforseo.com/register)
- Published site with accessible live URLs
- (Optional) [content-ops](../content-ops) for richer context

## Configuration

Config lives in `.content-seo/config.md` (created by `/init`). Sensitive credentials live in environment variables only — never in files.

See [config.example.md](./config.example.md) for the full schema.

## Roadmap

- GEO/AEO optimization (Generative Engine + Answer Engine Optimization)
- Automated hooks for post-publish SEO checks
- content-ops integration (auto-audit after `/write-content`)
