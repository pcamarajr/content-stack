---
name: content-style
description: Loads and applies the project's configured style guide. Hard stops if config or any required piece is missing. All style rules come from the guidelines file set during /init style.
user-invocable: false
disable-model-invocation: false
---

# Content Style Reference

This skill provides style rules for content creation and review. All rules come from the project's configured guidelines file — nothing is hardcoded here.

## Config Loading

**Before applying any style rules**, verify the following are present in `.content-ops/config.md`. **Stop immediately if any are missing**:

| Required | Config key | If missing |
|---|---|---|
| Config file | `.content-ops/config.md` exists | "Run `cp .claude/plugins/content-ops/config.example.md .content-ops/config.md` then `/init`." |
| Word range | `content_types.<type>.word_range` | "Run `/init content-types` to configure content types." |
| Guidelines path | `content_types.<type>.guidelines` | "Run `/init style` to generate your style guide." |
| Guidelines file exists | _(read the file at that path)_ | "Run `/init style` — style guide file not found at `[path]`." |
| Reference content | `reference_content` | "Run `/init style` to configure reference content." |

## Applying Style Rules

Read the guidelines file from `content_types.<type>.guidelines`. This file is the authoritative source for all style rules for this project, including:

- Voice and tone
- Sentence and paragraph rules
- Structure conventions (headings, sections, openings, closings)
- Jargon policy
- Anti-patterns to avoid
- Examples of good and bad writing

Apply only the rules defined in that file. Do not apply rules not present in the guidelines.

Read the files in `reference_content` to calibrate tone before writing or reviewing. These are the gold standard for voice and sentence length for this project.

## Frontmatter

Frontmatter fields per content type come from `content_types.<type>.frontmatter` in config, set during `/init content-types`.

## Linking

Linking review and enforcement is handled by the `content-linker` agent, not by this skill.
