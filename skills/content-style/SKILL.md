---
name: content-style
description: Content style guide — voice, tone, structure, and linking rules for all content creation and review tasks. Reads project-specific values from plugin config.
user-invocable: false
disable-model-invocation: false
---

# Content Style Reference

This skill provides the style rules for content creation. It is auto-loaded during content tasks.

## Config Loading

Config is pre-loaded at session start by the SessionStart hook. Use these config values:

- `author`, `content_types` (including `guidelines`, `word_range`, `frontmatter`), `reference_content`

For the full style guide, read the guidelines file from config (e.g., `content_types.article.guidelines`). Below is the condensed reference for quick access.

## Voice: Core Principles

1. **Plain English** — Write for a smart 15-year-old. No jargon without glossary links.
2. **Direct and concise** — Short sentences. Say what you mean.
3. **One topic per article** — Link to related concepts, don't explain them.
4. **Trust through linking** — Every technical term links to its glossary entry on first use.
5. **Factually rigorous** — Every claim should be verifiable.

## Sentence & Paragraph Rules

- **Under 20 words per sentence.** Hard limit ~25 words.
- **Max 3-4 sentences per paragraph.**
- **One idea per sentence.** No chaining with semicolons or em dashes.

## The Scope Rule (Most Important)

When a related concept comes up:

1. Mention it in one sentence
2. Link to its article or glossary entry
3. Move on

If you write more than 2 sentences about a concept that has its own content, you've gone too far. Cut it.

## Article Structure

- 2-4 H2 sections (no H3)
- Intro paragraph: answer "what is this?" in 1-2 sentences
- Closing section: link to related content
- Target word count: use `content_types.article.word_range` from config (default: 800-1500 words, 5-10 min read)
- No emojis

### Article Slug Rules

Lowercase, hyphenated (`getting-started`, `what-is-a-widget`). The slug must match the `translationKey`.

### Article Frontmatter Template

```yaml
---
title: "Clear, Beginner-Friendly Title"
date: <today's date YYYY-MM-DD>
excerpt: "1-2 sentence summary for cards and SEO."
tags: [<reuse existing tags when possible>]
readTime: "<N> min read"
author: <from config `author` field>
translationKey: "<slug>"
relatedGlossary: [<"en/<term>" for glossary terms linked in body or relevant to topic>]
relatedArticles: [<"en/<slug>" for related existing articles>]
---
```

### Article Body Rules

- Flexible structure: intro → 2-4 H2 sections → next steps
- Plain English, no jargon without glossary links
- **Sentences under 20 words.** Never over ~25.
- **Max 3-4 sentences per paragraph.**
- Link glossary terms on first mention: `[term](/en/glossary/<term>)`
- Link related articles naturally: `[title](/en/articles/<slug>)`
- **One topic only.** Related concepts get 1 sentence + link. No more.
- Target word count: use `content_types.article.word_range` from config. Shorter is better.
- No H3 headings, no emojis

## Glossary Structure

- `definition`: 1 short sentence (cards/SEO)
- `example`: optional, 1 concrete sentence
- Markdown body: 1-2 dictionary-style sentences for the detail page
- Target word count: use `content_types.glossary.word_range` from config (default: 50-150 words)
- No jargon in definitions

### Glossary Entry Template

```yaml
---
term: "Term Name"
definition: "1 short sentence for cards and SEO. Plain English."
example: "One concrete, real-world example sentence."
tags: [<relevant tags, reuse existing vocabulary>]
relatedTerms: [<"en/<term>" for connected glossary entries>]
relatedArticles: [<"en/<slug>" for articles that discuss this term>]
translationKey: "<term-slug>"
---
```

Markdown body: 1-2 simple dictionary-style sentences. More context than the definition but still concise.

### Glossary Rules

- `definition` — 1 short sentence. Cards/SEO only. Not shown on detail page.
- `example` — Optional but preferred. One sentence. Concrete and relatable.
- **Markdown body** — 1-2 sentences. Dictionary-style. A smart 15-year-old should understand it.
- `term` — Most common form in the default language. Capitalize proper nouns only.
- `term-slug` — Lowercase, hyphenated: `load-balancer`, `rate-limiting`.

## Linking Conventions

- Glossary inline: `[display text](/en/glossary/<term-slug>)` — first mention only
- Article inline: `[display text](/en/articles/<article-slug>)`
- Frontmatter refs use lang prefix: `relatedGlossary: ["en/some-term"]`

## Reference Articles

Read the files listed in `reference_content` from config to calibrate tone before writing. These are the gold standard for voice, scope, and sentence length. New content should feel like it belongs alongside them.

## Do / Don't Quick Reference

**Do:** active voice, "you" addressing reader, concrete examples, bullet lists for processes, glossary links on first mention only

**Don't:** jargon without links, inline explanations of other topics, complete histories, marketing language, hedging, emojis, paragraphs over 4 sentences
