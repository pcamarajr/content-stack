# Skills

Skills are the commands you type inside Claude Code. content-ops provides seven user-facing skills and five internal skills that load automatically.

---

## /init

Setup wizard. Creates and verifies your `.content-ops/config.md` and bootstrap files.

**Usage:**
```
/init                    → Show setup status dashboard
/init project            → Configure author and languages
/init content-types      → Define content types, paths, word ranges
/init style              → Style guide and reference articles
/init strategy           → Content strategy and pillars
/init infra              → Create backlog, trackers, localization guides
/init images             → Configure image generation (optional)
```

**Status dashboard** — running `/init` with no arguments shows completion status per round:

```
✅ project        author + languages set
✅ content-types  1 type configured
⬜ style          no reference content set
⬜ strategy       strategy file missing
✅ infra          backlog and tracker exist
⬜ images         not configured
```

Run rounds in any order. Each round reads the current config state and asks only what's missing or needs updating.

---

## /write-content

The main skill. Runs the full pipeline: research → draft → style review → glossary → linking → commit.

**Usage:**
```
/write-content article "Getting Started with Docker"   → Interactive mode, single article
/write-content glossary "container, image, volume"     → Create multiple glossary entries
/write-content backlog 3                               → Autonomous: write next 3 backlog items
/write-content backlog #1,#3,#5                        → Write specific backlog items by number
/write-content backlog all                             → Write all pending backlog items
/write-content                                         → Ask what to create
```

**Interactive mode** — for `article` and `glossary`, Claude asks a few questions before drafting (angle, target audience, key points to cover). The rest of the pipeline runs automatically.

**Backlog mode** — runs autonomously. Each item gets its own git commit. If interrupted, completed items are preserved.

**What the pipeline does:**
1. Parse your arguments and load config
2. Plan the topic (questions in interactive mode, or parse backlog item)
3. Research with cache — check research cache, run web search if stale or missing
4. Draft the content
5. Generate images (if configured)
6. Review and enforce style
7. Scan for glossary terms that need entries
8. Add bidirectional internal links
9. Reindex and commit

---

## /translate

Localizes existing content to a target language, respecting your localization guide for that language.

**Usage:**
```
/translate es              → Translate all untranslated content to Spanish
/translate de 3            → Translate next 3 articles to German
/translate pt backlog      → Translate items flagged in the translation tracker
```

**What it does:**
- Reads the localization guide for the target language (from `localization_guides_path`)
- Translates content while preserving frontmatter structure and internal links
- Updates the translation tracker
- Links translated articles to originals via `translationKey`

---

## /fact-check

Verifies every factual claim in a content file against trusted sources.

**Usage:**
```
/fact-check src/content/articles/en/my-article.md
```

**What it does:**
- Extracts all claims from the article
- Runs web research on each claim
- Flags anything that can't be verified or appears inaccurate
- Returns a report — does not edit the file directly

---

## /review-content

Full editorial review: tone, style, structure, and linking completeness.

**Usage:**
```
/review-content src/content/articles/en/my-article.md
```

**What it checks:**
- Sentence length (hard limit: ~25 words)
- Paragraph length (target: 3-4 sentences)
- Plain language (readable by a general audience)
- H2 structure (2-4 sections, no H3)
- Glossary term coverage (first mentions linked)
- Internal link coverage (related articles linked)
- Scope — if a concept gets 2+ sentences, it should probably be its own article

Returns a structured report with specific suggestions.

---

## /suggest-content

Analyzes your content strategy, pillars, and existing index to recommend what to write next.

**Usage:**
```
/suggest-content               → 5 suggestions
/suggest-content 10            → 10 suggestions
/suggest-content 5 technical   → 5 suggestions filtered by theme
```

**What it does:**
- Reads your strategy file and pillar files
- Reads the content index (via `content-inventory` skill)
- Identifies gaps — topics in your strategy not yet covered
- Returns ranked suggestions with rationale

---

## /reindex

Rebuilds the content index by scanning your content directories.

**Usage:**
```
/reindex
```

**What it does:**
- Scans all directories defined in `content_types`
- Reads frontmatter from each file
- Writes `.content-ops/content-index.json`

Safe to run multiple times — always overwrites with the current state. Run it after adding, renaming, or deleting content files manually.

---

## Internal skills (auto-loaded)

These load automatically when needed. You don't invoke them directly.

| Skill | What it provides |
|---|---|
| `content-style` | Voice, tone, sentence rules, structure guidelines loaded by style-enforcer and draft-writer |
| `content-image-style` | Image prompt patterns, file naming, alt text conventions loaded by image-generator |
| `content-inventory` | Current snapshot of all articles and glossary entries, used by suggest-content and content-linker |
| `internal-linking` | Bidirectional linking conventions loaded by content-linker |
| `update-trackers` | Logic for updating backlog and translation tracker after write or translate |
