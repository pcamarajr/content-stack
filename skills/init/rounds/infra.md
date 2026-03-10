# Round: Infrastructure & Bootstrap

Goal: Create tracker files and localization guides, and ensure the file-based content index can be built (via /reindex).

---

## Phase 1: Read config

Read `.content-ops/config.md`. Extract:

- `languages`, `default_language`
- `backlog_file`, `translation_tracker_file`
- `localization_guides_path`
- `content_index_path`, `research_cache_path` (for explaining where index and cache live; defaults in example)
- `content_types` (all paths, for pre-populating trackers)

---

## Phase 2: Inventory check

Check the status of each infrastructure item:

| Item | Check |
| ---- | ----- |
| Backlog file | Does the `backlog_file` path exist on disk? |
| Translation tracker | Does the `translation_tracker_file` path exist on disk? |
| Localization guides | Does `{localization_guides_path}/{lang}.md` exist for each non-default language? |
| Content index | Does `content_index_path` file exist, or will it be created by /reindex? |
| .gitignore entries | Are the required content-ops entries present in `.gitignore`? |

Present the checklist before doing anything:

```text
Infrastructure status:

  [✅|⬜] Backlog file          — [path] ([exists: N entries | missing])
  [✅|⬜] Translation tracker   — [path] ([exists | missing])
  [✅|⬜] Localization guide    — [path] ([exists | missing]) (one line per non-default language)
  [✅|⬜] Content index         — [path] ([exists | will be created by /reindex])
  [✅|⬜] .gitignore entries    — [present | missing]

I'll handle the missing items. Let's go through each one.
```

If everything is already in place: confirm it and guide to the final summary.

---

## Phase 3: Handle each missing item

Work through missing items in order. Ask before acting on anything that creates or modifies files.

### Backlog file (if missing)

```text
Create [backlog_file] — the content backlog tracker?

  A — Yes, create it with example structure
  B — My backlog is at a different path (I'll specify)
  C — Skip — I don't use a backlog
```

- If **A**: create the file with headers and 2–3 example pending entries. Use this structure:

  ```markdown
  # Content Backlog

  | # | Title / Topic | Type | Tags | Priority | Status | Notes |
  |---|---------------|------|------|----------|--------|-------|
  | 1 | Example topic | article | example, intro | high | pending | — |
  ```

- If **B**: ask for the path; update `backlog_file` in config.
- If **C**: note it and continue.

### Translation tracker (if missing)

```text
Create [translation_tracker_file] — tracks which content has been translated?

  A — Yes, create it and pre-populate with existing articles
  B — Different path (I'll specify)
  C — Skip — this is a single-language site
```

- If **A**: scan all content paths in `content_types` for the default language. For each file found, add a row with `done` for the default language and `pending` for every other language in `languages`. Use this structure:

  ```markdown
  # Translation Tracker

  | File | [lang1] | [lang2] | Notes |
  |------|---------|---------|-------|
  | articles/en/example.md | done | pending | — |
  ```

- If **B**: update `translation_tracker_file` in config.
- If **C**: skip.

### Localization guides (one question per missing language)

For each non-default language without a guide at `{localization_guides_path}/{lang}.md`:

```text
Create a starter localization guide for [lang]?

This guide helps Claude translate content naturally — covering
URL slug conventions, tone adjustments, and formatting rules.

  A — Yes, create a starter guide
  B — I already have one (specify the path)
  C — Skip
```

- If **A**: generate a starter guide at `{localization_guides_path}/{lang}.md` with sections:
  - Language name and locale code
  - URL conventions (slug style for this language — leave blank with a comment to fill in)
  - Tone adaptation notes (leave blank)
  - Vocabulary notes (leave blank)
  - Formatting conventions (date format, number separators, quotation marks)
- If **B**: note the path; no file creation needed.
- If **C**: skip.

### Content index (optional)

If the content index file does not yet exist at `content_index_path`:

```text
The content index is file-based at [content_index_path]. It powers content linking
and is created/updated by running /reindex. No API keys or server build required.

Run /reindex now to build the content index?

  A — Yes, run /reindex
  B — I'll run /reindex later
```

- If **A**: invoke the `reindex` skill.
- If **B**: show: "When ready, run `/reindex`."

### .gitignore entries

No content-ops entries in .gitignore — the entire .content-ops/ directory is tracked for cloud-friendly runs.

---

## Phase 4: Final config update

Review `.content-ops/config.md`. Update any paths that changed during this round (e.g., if the user specified different tracker paths). Preserve all other fields.

---

## Phase 5: Completion summary

```text
✅ content-ops is fully configured

  ✅ /init project        — [author], [languages]
  ✅ /init content-types  — [N] types configured
  ✅ /init style          — style guide at [path]
  ✅ /init strategy       — [N] pillars defined
  ✅ /init infra          — trackers, guides, [content index ready via /reindex | run /reindex when ready]

Created in this round:
  [list each file created or updated]

You're ready:
  /write-content article "Your Topic"   — write new content
  /suggest-content                      — get next article ideas
  /translate [lang]                     — translate existing content
  /fact-check [file]                    — verify claims in an article

Config: .content-ops/config.md
Docs:    docs/content-style-guide.md
         .content-ops/strategy.md
         .content-ops/pillars/
```
