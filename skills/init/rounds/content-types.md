# Round: Content Types

Goal: Define `content_types` in `.content-ops/config.md` — what kinds of content this project publishes, where they live, and their configuration.

---

## Phase 1: Scan

Read `.content-ops/config.md` and parse:

- `content_base_path` (default: `src/content`)
- `languages`, `default_language`
- `content_types` (existing entries, if any)

Scan `{content_base_path}/`:

- List immediate subdirectories — each is a candidate content type
- For each subdirectory:
  - Check for language subfolders (`en/`, `it/`, etc.) or direct files
  - Count `.md` files per language
  - Read frontmatter from 1–2 existing files to detect field patterns

Build a per-type findings map. Example:

```text
articles/
  en/ — 24 files
  it/ — 18 files
  frontmatter detected: title, date, excerpt, tags, readTime, author, translationKey

glossary/
  en/ — 31 files
  it/ — 22 files
  frontmatter detected: term, definition, example, tags, relatedTerms
```

---

## Phase 2: Existing config check

If `content_types` is already set in the config with at least one entry:

Show a summary of the existing types:

```text
I found existing content type configuration:

  articles  → src/content/articles  (800–1500 words)
  glossary  → src/content/glossary  (50–150 words)

Want to:
  A — Keep as-is (skip this round)
  B — Update one or more types
  C — Start fresh (reconfigure all types)
```

- If **A**: stop and guide to `/init style`.
- If **B**: ask which type(s) to update; run the Phase 3 questions only for those types.
- If **C**: continue as if no `content_types` exist.

---

## Phase 3: Interview per detected type

Handle one content type at a time. Complete all questions for one type before moving to the next.

For each detected directory (from Phase 1 scan):

### Q1 — Confirm this is a real content type

```text
I found: [type name]/
  [N] files in [default_language]/
  [N] files in [other langs]/

Is this a real content type you want to configure?
  A — Yes
  B — No, ignore this directory
```

If No: skip remaining questions for this type.

### Q2 — Word range

```text
What's the typical length for a [type name]?
  A — Short     50–300 words    (glossary entries, quick facts)
  B — Medium    800–1500 words  (standard posts, articles)
  C — Long      2000–4000 words (deep dives, guides)
  D — Custom range
```

If D: ask for min and max as free text.

### Q3 — Guidelines file

```text
Which style guide covers [type name] content?
  A — Shared project style guide (docs/content-style-guide.md)
  B — Its own separate guidelines file (I'll specify the path)
  C — No guidelines file yet — set up in /init style
```

### Q4 — Frontmatter fields

Only ask if the scan detected fields to confirm.

```text
I detected these frontmatter fields in your [type name] files:
  [detected field list]

Are these the fields for this type?
  A — Yes, that looks right
  B — I want to add some
  C — I want to remove some
```

If B: ask "Which fields to add?" (free text, comma-separated).
If C: ask "Which to remove?" (free text).

Keep it conversational — don't show a long list of checkboxes.

### After all detected types — new types

```text
Are there any other content types not yet in your repo that you want to configure?
(e.g., a "tutorials" or "case-studies" section you're planning)

  A — No, that's everything
  B — Yes, add one more
```

If B: collect name, path (suggest `src/content/[name]`), word range, guidelines path.
Repeat until they say A.

---

## Phase 4: Write config

Update the `content_types` block in `.content-ops/config.md`.

For each confirmed type, write:

```yaml
content_types:
  [type]:
    path: "[path]"
    guidelines: "[guidelines file path]"
    word_range: [[min], [max]]
    frontmatter:
      - [field1]
      - [field2]
```

Preserve all other fields in the file.

---

## Phase 5: Confirm and guide

```text
✅ Content types configured in .content-ops/config.md

  [type1]  → [path]  ([min]–[max] words, [N] frontmatter fields)
  [type2]  → [path]  ([min]–[max] words, [N] frontmatter fields)

→ Next: /init style
  Define your brand voice, writing tone, and generate a style guide.
```
