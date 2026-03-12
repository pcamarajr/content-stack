# Knowledge layer

content-ops uses a fully file-based knowledge layer — no database, no embeddings, no vector search, no external APIs. Everything is plain JSON files committed to git.

This means it works offline, it's portable across machines, and it's transparent — you can open any file and see exactly what Claude knows about your content.

---

## Content index

**Location:** `.content-ops/content-index.json` (configurable via `content_index_path`)
**Written by:** `/reindex`
**Read by:** `content-linker` agent, `content-inventory` skill, `/suggest-content`

The content index is a JSON file containing metadata for every article and glossary entry in your site, organized by language.

### Structure

```json
{
  "en": {
    "articles": [
      {
        "slug": "getting-started-with-bitcoin",
        "path": "src/content/articles/en/getting-started-with-bitcoin.md",
        "type": "article",
        "lang": "en",
        "title": "Getting Started with Bitcoin",
        "excerpt": "A beginner's guide to understanding Bitcoin...",
        "tags": ["bitcoin", "beginner", "crypto"],
        "translationKey": "getting-started-with-bitcoin"
      }
    ],
    "glossary": [
      {
        "slug": "proof-of-work",
        "path": "src/content/glossary/en/proof-of-work.md",
        "type": "glossary",
        "lang": "en",
        "title": "Proof of Work",
        "excerpt": "A consensus mechanism used to validate transactions...",
        "tags": ["consensus", "mining"],
        "translationKey": "proof-of-work"
      }
    ]
  },
  "es": {
    "articles": [...],
    "glossary": [...]
  }
}
```

### How linking uses it

The `content-linker` agent uses a two-step approach:

1. **Filter** — load the index, filter by language and type, cap at `linking_max_candidates` (default 50)
2. **Rank** — single LLM pass over filtered candidates, select top `linking_max_links` (default 10)
3. **Read** — only open the files that were selected in step 2
4. **Link** — edit those files to add bidirectional links

This scales to large sites. The agent never reads every file — it reads the index (one file), ranks candidates (one LLM call), then reads only the matched files.

### Keeping it current

Run `/reindex` after:
- Adding content files manually
- Renaming or deleting articles
- Updating article titles or tags
- Bulk imports

After `/write-content` runs, reindex happens automatically as the last phase.

---

## Research cache

**Location:** `.content-ops/research-cache/` (configurable via `research_cache_path`)
**Written by:** `content-researcher` agent
**Read by:** `content-researcher` agent

One JSON file per researched topic. The file name is derived from the topic slug.

### Structure

```json
{
  "topic": "proof-of-work",
  "cached_at": "2025-01-15T10:30:00Z",
  "ttl_days": 30,
  "findings": {
    "summary": "Proof of Work is a consensus mechanism...",
    "key_facts": [
      "Bitcoin uses SHA-256 for its PoW algorithm",
      "Difficulty adjusts every 2016 blocks (~2 weeks)",
      "The first PoW system was Hashcash, created by Adam Back in 1997"
    ],
    "sources": [
      "https://bitcoin.org/bitcoin.pdf",
      "https://en.bitcoin.it/wiki/Proof_of_work"
    ],
    "claims_verified": true
  }
}
```

### TTL behavior

When `content-researcher` starts:
1. Check if `research-cache/<topic>.json` exists
2. If it exists, check `cached_at` + `ttl_days` against today
3. If fresh → use cached findings, skip web search
4. If stale or missing → run web research, write new cache file

The default TTL is 30 days, configurable via `research_cache_ttl_days` in config. Set it lower for fast-moving topics, higher for evergreen content.

### Cross-session portability

Cache files are committed to git. This means:
- Research done on your laptop is available in a Claude Code web session
- Team members benefit from each other's research
- Restarting Claude Code never loses cached findings

---

## Translation keys

Content in multiple languages is connected via the `translationKey` frontmatter field.

```yaml
---
title: "Getting Started with Bitcoin"
translationKey: "getting-started-with-bitcoin"
lang: en
---
```

```yaml
---
title: "Comenzando con Bitcoin"
translationKey: "getting-started-with-bitcoin"
lang: es
---
```

The `content-linker` agent uses this to avoid linking a Spanish article to an English one when a Spanish version exists. The `/translate` skill sets `translationKey` automatically.

---

## Why file-based?

Most RAG systems use embeddings and vector search for content discovery. content-ops deliberately avoids this because:

- **No setup friction** — no vector DB to install or manage
- **No API dependency** — the knowledge layer works offline and without external services
- **Transparent** — every piece of knowledge Claude uses is a file you can read and edit
- **Git-native** — the entire knowledge layer is version-controlled alongside your content
- **Fast enough** — for typical blog-scale content (hundreds of articles), filtering + a single LLM ranking pass is faster than a round-trip to an embedding service

The trade-off: at very large scale (thousands of articles), a more sophisticated retrieval system would outperform. For a blog, this approach is simpler, cheaper, and easier to debug.
