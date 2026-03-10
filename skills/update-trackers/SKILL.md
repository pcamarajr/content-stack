---
name: update-trackers
description: Logic for updating content backlog and translation tracker after creating or translating content. Reads tracker paths from plugin config.
user-invocable: false
disable-model-invocation: false
---

# Tracker Update Rules

This skill defines how to update the content backlog and translation tracker. Referenced by content creation and translation skills.

## Config

The plugin config is pre-loaded at session start by the SessionStart hook. Use the following values from config:

- `backlog_file` — path to content backlog (e.g., `.content-ops/backlog.md`)
- `translation_tracker_file` — path to translation tracker (e.g., `.content-ops/translation-tracker.md`)
- `languages` — list of language codes (e.g., `["en", "it"]`)

## Content Backlog (from config `backlog_file`)

### After Writing an Article

1. If the article was in the backlog, change its status from `pending` to `done`
2. If glossary terms from the backlog were created, mark them as `done` too
3. **Discover new topics:** While writing, identify:
   - Concepts mentioned but not fully explained (they deserve their own article)
   - Glossary terms that could have a deeper explainer article
   - Natural "next reading" topics that don't exist yet
4. Add discovered topics as new `pending` entries in the backlog table

### After Writing a Glossary Entry

1. If the term was in the backlog, mark it as `done`
2. Note any related articles that should be written

## Translation Tracker (from config `translation_tracker_file`)

### After Writing Default Language Content

Add new rows to the appropriate table (Articles or Glossary):

- Default language column: `done`
- All other language columns (from config `languages`): `pending`

### After Translating Content

Change the status for the translated item from `pending` to `done` in the target language column.

### Tracker Table Format

```markdown
| # | translationKey | EN | IT | DE | FR |
|---|---|---|---|---|---|
| 1 | getting-started | done | done | pending | pending |
| 2 | new-article | done | pending | pending | pending |
```

## Editing Rules

- **Only change status cells** — don't reformat the table
- **Append new rows** at the bottom of the appropriate table
- **Use sequential numbering** for new `#` values
- **Match `translationKey`** exactly as defined in the content frontmatter
