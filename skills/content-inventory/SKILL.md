---
name: content-inventory
description: Auto-injects current article and glossary inventory for content creation and linking tasks. Reads paths from plugin config.
user-invocable: false
disable-model-invocation: false
---

# Content Inventory

This skill auto-injects the current state of project content. Use this to know what articles and glossary entries already exist before creating or linking content.

## Config Loading

Config is pre-loaded at session start by the SessionStart hook. Use these config values:

- `content_types` (each type's `path`), `languages`, `default_language`

## Rich Metadata (content-index.json)

For rich metadata (titles, tags, excerpts, relationships), read `.content-ops/content-index.json` instead of scanning individual files. The index contains per-language entries for articles and glossary with `slug`, `title`/`term`, `excerpt`/`definition`, `tags`, `relatedGlossary`, `relatedArticles`, `relatedTerms`. Use this when you need more than just filenames — e.g., for linking, tag vocabulary, or understanding content overlap.

## Dynamic Inventory

For each content type and language from config, list existing content:

### Articles

For each language in `languages`, list files at `{content_types.article.path}/{lang}/`:

!`ls {content_types.article.path}/{lang}/ 2>/dev/null | sed 's/\.md$//' | sort`

(Run the above command for each configured language.)

### Glossary Terms

For each language in `languages`, list files at `{content_types.glossary.path}/{lang}/`:

!`ls {content_types.glossary.path}/{lang}/ 2>/dev/null | sed 's/\.md$//' | sort`

(Run the above command for each configured language.)

### Tags in Use

Scan default language content for existing tag vocabulary:

!`grep -h '^tags:' {content_types.article.path}/{default_language}/*.md {content_types.glossary.path}/{default_language}/*.md 2>/dev/null | sed 's/tags: \[//;s/\]//;s/"//g' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort -u`

## Usage

- Before creating new content: check if a glossary term or article already exists
- Before linking: verify the target exists in the inventory above
- Before choosing tags: reuse existing tags from the list above
- Reference IDs use lang prefix: `en/<slug>`, `en/<term-slug>`
