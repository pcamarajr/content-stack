# Configuration

All configuration lives in `.content-ops/config.md` — a YAML frontmatter file tracked in git. Skills read it at runtime. If it doesn't exist, any skill will stop and tell you to run `/init` or copy the example.

The easiest way to create it is the init wizard:

```
/init
```

To create it manually, copy the example:

```bash
cp .claude/plugins/content-ops/config.example.md .content-ops/config.md
```

---

## Full schema

```yaml
---
author: "Your Name"                          # Attribution line for all content
default_language: "en"                       # Primary language code
languages:                                   # All supported language codes
  - en
  - es

content_types:
  article:
    path: src/content/articles               # Directory for article files
    guidelines:                              # Style guides for this type
      - .content-ops/content-styles/general.md
      - .content-ops/content-styles/article.md
    word_range: [800, 1200]                  # Target word count range
    frontmatter:                             # Fields Claude writes to frontmatter
      - title
      - description
      - pubDate
      - author
      - tags
      - translationKey
  glossary:
    path: src/content/glossary
    guidelines:
      - .content-ops/content-styles/general.md
      - .content-ops/content-styles/glossary.md
    word_range: [150, 300]
    frontmatter:
      - term
      - definition
      - relatedTerms
      - translationKey

glossary:
  enabled: true
  content_type: glossary
  auto_stubs: true
  bidirectional_linking: true

backlog_file: .content-ops/backlog.md
translation_tracker_file: .content-ops/translation-tracker.md
content_strategy: .content-ops/strategy.md
content_pillars_path: .content-ops/pillars
localization_guides_path: .content-ops/localization

reference_content:                           # Example articles for tone calibration
  - src/content/articles/en/my-best-article.md

content_index_path: .content-ops/content-index.json
research_cache_path: .content-ops/research-cache
research_cache_ttl_days: 30                  # How long cached research stays fresh

linking_max_candidates: 50                   # Max articles considered before LLM ranking
linking_max_links: 10                        # Max links added per article

image_generation:                            # Optional — configure via /init images
  provider: gemini                           # gemini or openai
  model: gemini-2.0-flash-preview-image-generation
  placement: hero-only                       # hero-only | hero-plus-sections | ai-driven
  output_path: public/images/articles
  dimensions:
    width: 1200
    height: 630
---
```

---

## Field reference

### Core

| Field | Required | Description |
|---|---|---|
| `author` | Yes | Attribution written to all content frontmatter |
| `default_language` | Yes | Primary language for new content |
| `languages` | Yes | All languages the site supports |

### Content types

Each key under `content_types` defines a type (e.g., `article`, `glossary`). You can add custom types.

| Field | Required | Description |
|---|---|---|
| `path` | Yes | Directory where files of this type live |
| `guidelines` | Yes | List of style guide file paths for this type (general + type-specific) |
| `word_range` | No | `[min, max]` target word count |
| `frontmatter` | No | List of frontmatter fields to write |

### Glossary (optional)

| Field | Default | Description |
|---|---|---|
| `glossary.enabled` | `false` | Enable glossary auto-stubs and bidirectional linking |
| `glossary.content_type` | — | Which `content_types` key acts as the glossary |
| `glossary.auto_stubs` | `true` | Auto-create glossary stubs from articles (Phase 7) |
| `glossary.bidirectional_linking` | `true` | Bidirectional article-glossary linking (Phase 8) |

### Trackers and strategy

| Field | Default | Description |
|---|---|---|
| `backlog_file` | `.content-ops/backlog.md` | Content backlog tracker |
| `translation_tracker_file` | `.content-ops/translation-tracker.md` | Translation status tracker |
| `content_strategy` | `.content-ops/strategy.md` | High-level editorial plan |
| `content_pillars_path` | `.content-ops/pillars` | Directory of content pillar files |
| `localization_guides_path` | `.content-ops/localization` | Per-language localization guides |

### Knowledge layer

| Field | Default | Description |
|---|---|---|
| `content_index_path` | `.content-ops/content-index.json` | Generated content index (written by `/reindex`) |
| `research_cache_path` | `.content-ops/research-cache` | Cached research findings |
| `research_cache_ttl_days` | `30` | Days before cached research expires |
| `reference_content` | — | Files read for tone and style calibration |
| `linking_max_candidates` | `50` | Max candidates before LLM ranking pass |
| `linking_max_links` | `10` | Max links added per article |

### Image generation (optional)

| Field | Description |
|---|---|
| `provider` | `gemini` or `openai` |
| `model` | Model ID to use for generation |
| `placement` | `hero-only`, `hero-plus-sections`, or `ai-driven` |
| `output_path` | Where to save generated image files |
| `dimensions` | `width` and `height` in pixels |

Requires `GEMINI_API_KEY` or `OPENAI_API_KEY` environment variable. Configure with `/init images`.

---

## The .content-ops/ directory

Everything content-ops manages lives here. The full directory is tracked in git — making it portable across machines and sessions (including Claude Code on the web).

```
.content-ops/
├── config.md                 ← Main configuration (edit this)
├── backlog.md                ← Your content queue
├── translation-tracker.md    ← Translation status per article
├── strategy.md               ← High-level editorial plan
├── pillars/                  ← One file per content theme/pillar
│   ├── bitcoin-basics.md
│   └── lightning-network.md
├── localization/             ← Per-language guides
│   ├── es.md
│   └── pt.md
├── content-styles/              ← Style guides per content type
│   ├── general.md               ← Voice, tone, jargon (shared)
│   ├── article.md               ← Structure rules for articles
│   └── glossary.md              ← Structure rules for glossary
├── content-index.json        ← Generated by /reindex (don't edit manually)
└── research-cache/           ← Cached research per topic
    ├── proof-of-work.json
    └── lightning-channels.json
```

---

## Config Loading Patterns

Config is always read from `.content-ops/config.md` at runtime — never injected automatically into agent context. There is one standard pattern for how config values flow through the system:

### Orchestrator Pass-Through

Orchestrator skills (`write-content`, `translate`, `suggest-content`) read config directly in their first phase, then pass the relevant values explicitly to each subagent via prompt. Subagents (and the auto-loaded skills they use) are **config-agnostic** — they receive all needed values from the orchestrator and never read config themselves.

Example flow for `write-content`:

```
write-content (skill, Phase 2)
  └─ reads .content-ops/config.md
  └─ passes source_hierarchy, research_cache_path, research_cache_ttl_days → content-researcher
  └─ passes author, default_language                                        → draft-writer
  └─ passes all image_generation fields                                     → image-generator
  └─ passes content type, word_range, guidelines, reference_content         → style-enforcer
  └─ passes content_index_path, linking_max_candidates, linking_max_links   → content-linker
```

Non-orchestrator skills (`reindex`, `content-inventory`, `update-trackers`, `content-style`, `content-image-style`) read config directly when invoked standalone, or receive values from the orchestrator when loaded as part of a pipeline.

### Why not inject config at session start?

The `PostToolUse` hooks run shell commands in response to file or commit events. They do not inject config into agent context, and agent subprocesses do not inherit terminal output. Each agent starts fresh — config values must be explicitly passed in the task prompt to be available.

---

### Strategy vs. Pillars

The plugin uses a two-level planning system:

- **`strategy.md`** — Your high-level editorial plan. What topics to cover, goals, gaps to fill.
- **`pillars/`** — One file per content theme with detailed topic progression and objectives. Optional — `/suggest-content` works without them, just from the strategy file.

The `/suggest-content` skill reads both to identify gaps. The `/write-content` skill reads them for topic context when drafting.
