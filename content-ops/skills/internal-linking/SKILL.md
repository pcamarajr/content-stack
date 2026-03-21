---
name: internal-linking
description: Bidirectional linking rules and conventions for content cross-references
user-invocable: false
disable-model-invocation: false
---

# Internal Linking

This skill defines how content cross-referencing works. All rules — link syntax, URL patterns, frontmatter field names, bidirectional policy, first-mention policy, anchor text, scope, and exclusions — come from the project's configured link building guide. Nothing is hardcoded here.

## Config Loading

**Before applying any linking rules**, verify the following are present. **Stop immediately if any are missing**:

| Required | Config key | If missing |
|---|---|---|
| Config file | `.content-ops/config.md` exists | "Run `/init` first." |
| Link building section | `link_building` | "Run `/init link-building` to configure your link building strategy." |
| Guide path | `link_building.guide` | "Run `/init link-building` — guide path not set." |
| Guide file exists | _(read the file at that path)_ | "Run `/init link-building` — link building guide not found at `[path]`." |

## Applying Linking Rules

Read the guide file from `link_building.guide`. This file is the authoritative source for all linking rules for this project, including:

- Strategic goal (SEO-first, relevance-first, or hybrid)
- Scope (internal, external, or both)
- URL patterns for each content type and language
- Frontmatter field names for cross-references
- First-mention and link density policies
- Bidirectional linking policy
- Anchor text policy
- External source quality bar and nofollow rules (if external scope is enabled)
- Exclusions

Apply only the rules defined in that file. Do not apply rules not present in the guide.
