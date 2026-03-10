---
name: translate
description: Translate content to a target language using localization (not direct translation). Handles batch translation with glossary, linking, and tracker updates. Reads paths from plugin config.
argument-hint: "<lang> [selection]"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, Task, TodoWrite
---

Translate content to a target language using localization (not direct translation).

<!-- TODO (WS4 follow-up): Decompose this skill into an orchestrator that spawns focused sub-agents per phase, following the same pattern as write-content. -->

**Arguments:** $ARGUMENTS

## Phase 0: Config (Pre-loaded)

Config is pre-loaded at session start by the SessionStart hook. Use these config values:

- `languages`, `default_language`, `content_types`, `localization_guides_path`, `translation_tracker_file`, `author`

## Argument Syntax

Parse `$ARGUMENTS` as: `<language> [selection]`

**Language** (required): any non-default language from config `languages`

**Selection** (optional):

- _(empty)_ → Translate all pending articles + glossary for that language
- `3` or `first 3` → First 3 pending articles
- `last 2` → Last 2 pending articles
- `#1,#3,#5` → Specific articles by their `#` number in the translation tracker
- `glossary` → Only pending glossary entries
- `glossary #1,#3` → Specific glossary entries by tracker number

**Examples:** `/translate es`, `/translate de 3`, `/translate fr #1,#5`, `/translate es glossary`

## Localization, Not Translation

This produces **localized** content — text that reads as if a native speaker wrote it:

- Adapt idioms to what's natural in the target language
- Adapt examples to local context (EUR vs USD, local references)
- Keep domain-specific terms the local community uses in English (check localization guide)
- Restructure sentences for natural flow
- Maintain same meaning, tone, and educational quality

## Phase 1: Load Context

The `content-style` and `content-inventory` skills auto-load. Additionally read:

1. `{localization_guides_path}/<lang>.md` (from config) — Target language localization guide
2. The translation tracker from config (`translation_tracker_file`) — Determine pending content

## Phase 2: Plan the Batch

1. Parse selection to determine items to translate
2. List selected items with tracker numbers
3. Read each English source file
4. Present plan to user and confirm

## Phase 3: Research Local Context

For each article topic, use WebSearch in the target language:

- Search for the topic in the target language
- Note local terminology, common phrasings, native educator approaches
- Check for local analogies or examples that work better

## Phase 4: Translate Each Article (loop)

### 4a. Read English Source

Read and understand structure, key points, and linking.

### 4b. Localize Content

Create `{content_types.article.path}/<lang>/<localized-slug>.md` (path from config).

**Slug:** natural target-language slug, URL-friendly (lowercase, hyphenated, no accents).

**Frontmatter:**

```yaml
---
title: "<Localized title — natural, not literal>"
date: <same date as English original>
excerpt: "<Localized excerpt>"
tags: [<same tags as English — tags stay in English>]
readTime: "<N> min read"
author: <from config `author` field>
translationKey: "<same translationKey as English>"
relatedGlossary: ["<lang>/<term>" for glossary terms linked in body]
relatedArticles: ["<lang>/<slug>" for related articles in this language]
---
```

**Body:** same structure, adapted language, localized examples, links to localized content.

### 4c. Translate Glossary Entries

For each referenced glossary term not in the target language yet:

1. Read English glossary entry
2. Create `{content_types.glossary.path}/<lang>/<term-slug>.md` (path from config)
3. Localize definition and example
4. Match `translationKey` to English entry

### 4d. Bidirectional Linking via content-linker Agent

Delegate to the `content-linker` agent for the target language content.

### 4e. Build Check

Run `pnpm build`. Fix any reference issues.

### 4f. Update Trackers

Follow `update-trackers` skill: change status from `pending` to `done` for translated items.

### 4g. Commit

```text
content(<lang>): translate "<title>"

- New article: src/content/articles/<lang>/<slug>.md
- New glossary: <list any created>
- Tracker: updated <lang> status

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 4h. Continue

Update in-memory context, proceed to next article.

## Phase 5: Batch Summary

```text
## Translation Batch Complete (<lang>)

### Articles translated
- #1 "Source Title" → "<Localized title>" (src/content/articles/<lang>/<slug>.md)

### Glossary entries translated
- term1, term2, ...

### Commits
- <list of commit hashes>

### Notes
- <uncertain localization choices>
- <articles referencing untranslated content>
```
