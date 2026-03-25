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
| Guidelines list | `content_types.<type>.guidelines` (must be a non-empty list) | "Run `/init style` to generate your style guides." |
| General guide exists | `.content-ops/content-styles/general.md` exists on disk | "Run `/init style` — general style guide not found." |
| Type-specific guide exists | The type-specific guide from the list exists on disk | "Run `/init style` — no structure guide found for `[type]`." |
| Reference content | `reference_content` | "Run `/init style` to configure reference content." |

## Applying Style Rules

Read the `content_types.<type>.guidelines` list from config. This is a list of file paths.

**Loading order:**

1. Ensure `.content-ops/content-styles/general.md` is in the list. If missing, add it — the general guide is always loaded regardless of what the config lists.
2. Load `general.md` first. This file is the authoritative source for cross-cutting style rules: voice, tone, jargon policy, anti-patterns, and examples.
3. Load the type-specific guide (the other file in the list, e.g., `content-styles/article.md`). This file is the authoritative source for structural rules: sentence length, paragraph density, opening/closing conventions.
4. Present both to the calling agent as a unified rule set.

Apply only the rules defined in the loaded files. Do not apply rules not present in the guidelines.

Read the files in `reference_content` to calibrate tone before writing or reviewing.

## Frontmatter

Frontmatter fields per content type come from `content_types.<type>.frontmatter` in config, set during `/init content-types`.

## Linking

Linking review and enforcement is handled by the `content-linker` agent, not by this skill.
