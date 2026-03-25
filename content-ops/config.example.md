---
# content-ops plugin configuration — Reference only, not copied.
# Each /init round appends its own section to .content-ops/config.md.
# Run /init project to create a minimal starting config.

# Written by /init project
author: "your-name & claude"
default_language: "en"
languages: ["en"]
content_base_path: "src/content"
content_index_path: ".content-ops/content-index.json"
research_cache_path: ".content-ops/research-cache"
research_cache_ttl_days: 30

# Written by /init content-types
content_types:
  article:
    path: "src/content/articles"
    guidelines:
      - ".content-ops/content-styles/general.md"
      - ".content-ops/content-styles/article.md"
    word_range: [800, 1500]
    frontmatter:
      - title
      - date
      - excerpt
      - tags
      - readTime
      - author
      - translationKey
      - relatedGlossary
      - relatedArticles

  glossary:
    path: "src/content/glossary"
    guidelines:
      - ".content-ops/content-styles/general.md"
      - ".content-ops/content-styles/glossary.md"
    word_range: [50, 150]
    frontmatter:
      - term
      - definition
      - example
      - tags
      - relatedTerms
      - relatedArticles
      - translationKey

# Written by /init content-types
glossary:
  enabled: true
  content_type: "glossary"          # which content_types key acts as the glossary
  auto_stubs: true                  # Phase 7: auto-create stubs from articles
  bidirectional_linking: true       # Phase 8: link articles <-> glossary

# Written by /init infra
backlog_file: ".content-ops/backlog.md"
translation_tracker_file: ".content-ops/translation-tracker.md"
localization_guides_path: ".content-ops/localization"

# Written by /init strategy
content_strategy: ".content-ops/strategy.md"
content_pillars_path: ".content-ops/pillars"
# source_hierarchy: []  # optional — trusted sources in order of authority

# Written by /init style
# Style guides: .content-ops/content-styles/general.md + one per content type
reference_content:
  - "src/content/articles/en/example-article.md"

# Content linking caps (optional — sensible defaults)
# linking_max_candidates: 50
# linking_max_links: 10

# Written by /init images
image_generation:
  enabled: true
  provider: "google-gemini"        # google-gemini | openai-gpt-image | manual
  model: ""                        # optional — omit for provider default
  guidelines: ".content-ops/image-style-guide.md"
  output_path: "public/images"
  hero_dimensions: [1200, 630]
  inline_dimensions: [800, 450]
  placement: "ai-driven"           # ai-driven | hero-plus-sections | hero-only
  max_inline_images: 3             # optional — omit for no cap
  min_word_count: 300
  skip_types: ["glossary"]

# Written by /init link-building
link_building:
  guide: ".content-ops/link-building-guide.md"
---

# content-ops Configuration Reference

This file documents every config field and which `/init` round writes it. Skills and agents read `.content-ops/config.md` (not this file) to resolve project-specific values like content paths, languages, tracker locations, and reference content.

**To create your config:** Run `/init project` — it writes a minimal config from scratch. Each subsequent `/init` round appends its section.

**Important:** If `.content-ops/config.md` doesn't exist, skills will stop and tell you to run `/init project`.

## Schema Reference

| Key | Type | Description |
| ---- | ----- | ----- |
| `author` | string | Attribution line for all content |
| `default_language` | string | Primary language code |
| `languages` | string[] | All supported language codes |
| `content_base_path` | string | Root directory for content collections |
| `content_types` | object | Per-type config (path, guidelines, word_range, frontmatter) |
| `content_types.<type>.guidelines` | string[] | List of style guide file paths for this type (general + type-specific) |
| `glossary.enabled` | boolean | Whether the glossary pipeline is active |
| `glossary.content_type` | string | Which `content_types` key acts as the glossary |
| `glossary.auto_stubs` | boolean | Auto-create glossary stubs from articles (Phase 7) |
| `glossary.bidirectional_linking` | boolean | Link articles to glossary entries and vice versa (Phase 8) |
| `backlog_file` | string | Path to content backlog tracker (default `.content-ops/backlog.md`) |
| `translation_tracker_file` | string | Path to translation status tracker (default `.content-ops/translation-tracker.md`) |
| `content_strategy` | string | Path to content strategy file (default `.content-ops/strategy.md`) |
| `content_pillars_path` | string | Directory containing content pillar files (default `.content-ops/pillars`) |
| `localization_guides_path` | string | Directory for per-language localization guides (default `.content-ops/localization`) |
| `reference_content` | string[] | Files to read for tone calibration |
| `content_index_path` | string | Path to content index JSON (default `.content-ops/content-index.json`) |
| `research_cache_path` | string | Path to research cache directory (default `.content-ops/research-cache`) |
| `research_cache_ttl_days` | number | Days before cached research expires (default 30) |
| `linking_max_candidates` | number | Max candidates before LLM ranking (default 50) |
| `linking_max_links` | number | Max links per article (default 10) |
| `image_generation.enabled` | boolean | Whether to generate images during `/write-content` |
| `image_generation.provider` | string | API provider: `google-gemini`, `openai-gpt-image`, or `manual` |
| `image_generation.model` | string | Model override (optional — omit for provider default) |
| `image_generation.guidelines` | string | Path to image style guide (created by `/init images`) |
| `image_generation.output_path` | string | Root folder for generated images (default `public/images`) |
| `image_generation.hero_dimensions` | number[] | Hero image size `[width, height]` (default `[1200, 630]`) |
| `image_generation.inline_dimensions` | number[] | Inline image size `[width, height]` (default `[800, 450]`) |
| `image_generation.placement` | string | `ai-driven`, `hero-plus-sections`, or `hero-only` |
| `image_generation.max_inline_images` | number | Max inline images per article (optional — omit for no cap) |
| `image_generation.min_word_count` | number | Skip images for articles shorter than this (default 300) |
| `image_generation.skip_types` | string[] | Content types that never get images (default `["glossary"]`) |
| `link_building.guide` | string | Path to the link building strategy guide (created by `/init link-building`) |

## .content-ops/ Layout

All configurable files live under `.content-ops/` by default. The entire directory is tracked in git for cloud-friendly runs.

| File/Dir | Purpose |
| ---- | ----- |
| `config.md` | Plugin configuration (this file) |
| `backlog.md` | Content backlog tracker |
| `translation-tracker.md` | Translation status tracker |
| `strategy.md` | Content strategy / editorial plan |
| `pillars/` | Content pillar files |
| `localization/` | Per-language localization guides |
| `content-index.json` | Generated by `/reindex` |
| `research-cache/` | Cached research per topic |
| `content-styles/` | Style guides — general.md + one per content type (created by `/init style`) |
| `link-building-guide.md` | Link building strategy guide (created by `/init link-building`) |

Generated images are saved outside `.content-ops/` under `public/images/articles/{slug}/` (or the path set in `image_generation.output_path`). These are committed alongside the article.
