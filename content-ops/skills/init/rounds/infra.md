# Round: Infrastructure & Bootstrap

Goal: Create tracker files and localization guides, and ensure the file-based content index can be built (via /reindex).

---

## Phase 1: Read config

Read `.content-ops/config.md`. Extract:

- `languages`, `default_language`
- `backlog_file`, `translation_tracker_file`
- `localization_guides_path`
- `content_index_path`, `research_cache_path` (for explaining where index and cache live)
- `content_types` (all paths, for pre-populating trackers)

---

## Phase 1b: Detection

If `backlog_file`, `translation_tracker_file`, and `localization_guides_path` are all present in config, this round has already run. Show the existing values and ask using `AskUserQuestion`:

```text
question: "I found existing infrastructure config:

  Backlog:            [backlog_file]
  Translation tracker: [translation_tracker_file]
  Localization guides: [localization_guides_path]

What would you like to do?"
header: "Phase 1b: Existing infrastructure config"
options:
  - label: "Keep as-is"
    description: "Skip this round — current settings are fine"
  - label: "Review and update"
    description: "Review values and continue to Phase 2"
  - label: "Other — specify overrides"
    description: "Type what to change (e.g. updated paths) in the Other free-text field"
```

If **Keep as-is**: stop and guide to the next round.
If **Review and update**: continue to Phase 2.
If **Other — specify overrides**: use the provided free text as override instructions for the config paths (e.g. `backlog_file`, `translation_tracker_file`, `localization_guides_path`), then continue to Phase 2 using those overrides.

If the fields are absent: continue to Phase 2.

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

If everything is already in place: confirm it with `AskUserQuestion`:

```text
question: "Infrastructure status looks complete. Continue to the final summary?"
header: "Infra complete"
options:
  - label: "Yes — continue to Phase 5"
    description: "Proceed to completion summary"
  - label: "Re-check inventory"
    description: "Re-run the Phase 2 checklist and re-evaluate"
  - label: "Other — specify details"
    description: "Type any last tweaks in the Other free-text field"
```

- If **Yes — continue to Phase 5**: guide to the final summary.
- If **Re-check inventory**: repeat the Phase 2 checklist, then continue to Phase 5.
- If **Other — specify details**: use the free text as last-tweak instructions, then continue to Phase 5.

---

## Phase 3: Handle each missing item

Work through missing items in order. Ask before acting on anything that creates or modifies files.

### Backlog file (if missing)

```text
question: "Backlog file is missing. Create [backlog_file] — the content backlog tracker?"
header: "Backlog file"
options:
  - label: "Create with example structure"
    description: "Create [backlog_file] with headers and 2–3 example pending entries"
  - label: "Other — specify existing backlog path"
    description: "Provide the path to an existing backlog file; I'll scan it and generate [backlog_file] in the expected content-ops format"
```

- If **Create with example structure**: create the file with headers and 2–3 example pending entries. Use this structure:

  ```markdown
  # Content Backlog

  | # | Title / Topic | Type | Tags | Priority | Status | Notes |
  |---|---------------|------|------|----------|--------|-------|
  | 1 | Example topic | article | example, intro | high | pending | — |
  ```

- If **Other — specify existing backlog path**: use the free text as a path to the existing backlog file; scan it, then generate `[backlog_file]` in the expected content-ops format (mandatory for consistency).

### Translation tracker (if missing)

```text
question: "Translation tracker file is missing. Create [translation_tracker_file] — tracks which content has been translated?"
header: "Translation tracker"
options:
  - label: "Create and pre-populate"
    description: "Create [translation_tracker_file] and pre-fill default-language rows from `content_types`"
  - label: "Other — specify existing tracker path"
    description: "Provide the path to an existing translation tracker; I'll scan it and generate [translation_tracker_file] in the expected content-ops format"
```

- If **Create and pre-populate**: scan all content paths in `content_types` for the default language. For each file found, add a row with `done` for the default language and `pending` for every other language in `languages`. Use this structure:

  ```markdown
  # Translation Tracker

  | File | [lang1] | [lang2] | Notes |
  |------|---------|---------|-------|
  | articles/en/example.md | done | pending | — |
  ```

- If **Other — specify existing tracker path**: use the free text as a path to the existing translation tracker; scan it, then generate `[translation_tracker_file]` in the expected content-ops format (mandatory for consistency).

### Localization guides (one question per missing language)

For each non-default language without a guide at `{localization_guides_path}/{lang}.md`:

```text
question: "Localization guide for [lang] is missing. Create a starter localization guide?

This guide helps Claude translate content naturally — covering
URL slug conventions, tone adjustments, and formatting rules."
header: "Localization guide ([lang])"
options:
  - label: "Yes — create a starter guide"
    description: "Generate `{localization_guides_path}/{lang}.md` with the required sections"
  - label: "Other — specify existing guide path"
    description: "Provide the path to an existing guide for [lang]; I'll scan it and generate `{localization_guides_path}/{lang}.md` in the required content-ops format"
```

- If **Yes — create a starter guide**: generate a starter guide at `{localization_guides_path}/{lang}.md` with sections:
  - Language name and locale code
  - URL conventions (slug style for this language — leave blank with a comment to fill in)
  - Tone adaptation notes (leave blank)
  - Vocabulary notes (leave blank)
  - Formatting conventions (date format, number separators, quotation marks)
- If **Other — specify existing guide path**: use the free text as a path to the existing guide; scan it and generate `{localization_guides_path}/{lang}.md` with the required sections (mandatory for consistency).

### Content index (optional)

If the content index file does not yet exist at `content_index_path`:

```text
question: "Content index is file-based at [content_index_path]. It powers content linking and is created/updated by running /reindex.

No API keys or server build required.

Run /reindex now to build the content index?"
header: "Content index"
options:
  - label: "Run /reindex now"
    description: "Invoke the `reindex` skill immediately"
  - label: "I'll run /reindex later"
    description: "Show a reminder to run /reindex later"
```

- If **Run /reindex now**: invoke the `reindex` skill.
- If **I'll run /reindex later**: show: "When ready, run `/reindex`."

### .gitignore entries

No content-ops entries in .gitignore — the entire .content-ops/ directory is tracked for cloud-friendly runs.

---

## Phase 4: Final config update

Append `backlog_file`, `translation_tracker_file`, and `localization_guides_path` as new fields to `.content-ops/config.md` (if not already present). If any paths changed during this round (e.g., the user specified a different tracker path), update them. Preserve all other fields.

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
Docs:    .content-ops/content-style-guide.md
         .content-ops/strategy.md
         .content-ops/pillars/
```
