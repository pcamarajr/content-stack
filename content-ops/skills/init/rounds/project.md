# Round: Project Setup

Goal: Configure project basics in `.content-ops/config.md`.

---

## Phase 1: Scan

Scan silently before asking anything.

### Step 1a: Detect framework

Check for the following config file signatures (in order):

| File(s) | Framework |
|---|---|
| `astro.config.ts` or `astro.config.mjs` | Astro |
| `next.config.js` or `next.config.ts` | Next.js |
| `nuxt.config.ts` | Nuxt |
| `hugo.toml` or (`config.toml` + `content/` directory) | Hugo |
| None found | generic/unknown |

Record the detected framework. Use it in Step 1b.

### Step 1b: Read files

Always read (if they exist):

- `package.json` → extract `name`, `description`, `author`
- `.content-ops/config.md` → parse existing config (if resuming)

Then apply framework-specific extraction:

**Astro** (first-class):
- `astro.config.ts` or `astro.config.mjs` → extract `site` URL, `i18n.locales`, `i18n.defaultLocale`
- `src/content.config.ts` → extract collection names and base paths
- Scan `src/content/` → list immediate subdirectories; for each: check for language subfolders (`en/`, `it/`, etc.) and count `.md` files

**Next.js**:
- `next.config.js` or `next.config.ts` → extract `i18n.locales`, `i18n.defaultLocale` if present
- Scan `content/` or `posts/` → list immediate subdirectories; for each: check for language subfolders and count `.md`/`.mdx` files

**Nuxt**:
- `nuxt.config.ts` → extract `i18n.locales`, `i18n.defaultLocale` if present
- Scan `content/` → list immediate subdirectories; for each: check for language subfolders and count `.md` files

**Hugo**:
- `hugo.toml` or `config.toml` → extract `defaultContentLanguage`, `[languages]` table if present
- Scan `content/` → list immediate subdirectories; for each: check for language subfolders and count `.md` files

**Generic/unknown**:
- Skip framework-specific file reads
- Scan common content directories (`content/`, `posts/`, `src/content/`) — use whichever exists

Build a findings summary (detected framework + extracted data). Do not show it yet — it will be used to inform questions.

---

## Phase 2: Existing config check

If `.content-ops/config.md` already exists and has `author`, `default_language`, and `languages` all set:

Show:

```text
I found an existing project config:

  Author:   [author]
  Languages: [languages] (default: [default_language])
  Content:  [content_base_path]

Want to:
  A — Keep it and skip this round
  B — Review and update individual fields
  C — Start fresh
```

- If **A**: output "Project config already set. Run `/init content-types` to continue." and stop.
- If **B**: continue to Phase 3, pre-filling each question with the current value (show it, ask to confirm or change).
- If **C**: continue to Phase 3 as if the file were empty.

If no existing config: go straight to Phase 3.

---

## Phase 3: Interview

Ask each question separately using AskUserQuestion. Wait for the answer before asking the next. Use findings from Phase 1 to pre-fill options and reduce what the user has to type.

### Question 1: Languages

Present what was detected, then ask:

```text
[If framework config has i18n config:]
  Detected in [config file]: [locales] (default: [defaultLocale])

[If content dirs have language subfolders:]
  Language folders found in [content_base_path]:
    en/ — [N] files
    it/ — [N] files

[If nothing detected:]
  No language configuration found.

What languages does this site publish in?
```

Options (adjust based on what was detected):

- "[Detected: en, it] — Yes, that's correct" (only if detected)
- "English only"
- "English + one more (I'll specify)"
- "Multiple languages (I'll list them)"

If they confirm detected: move to next question.
If they type a custom list: parse it and note it.

### Question 2: Default language

Only ask if multiple languages were collected in Question 1.

```text
Which is the primary / default language?
(This is the language you write in first, before translating.)
```

Show the detected languages as options. Free choice.

### Question 3: Author attribution

```text
What name should appear as the author on your content?
(Added to every article's frontmatter.)

Examples: "Jane Smith & Claude"  /  "Acme Blog Team"  /  "Anonymous"
```

Free-text. No options — this is personal.

### Question 4: Project description

```text
In one sentence: what is this site about, and who is it for?

Example: "A Bitcoin education blog for curious beginners who want
          to understand money and financial sovereignty."

(This seeds your style guide and content strategy in later steps.)
```

Free-text. This is the most important input in this round — store it.

### Question 5: Content base path

Only ask if no content directory was found during the scan.

```text
Where does your content live?
  A — src/content/  (Astro)
  B — content/      (root level — Hugo, Nuxt, Next.js)
  C — posts/        (common Next.js convention)
  D — Other (I'll specify)
```

Skip entirely if a content directory was already detected in Phase 1.

---

## Phase 4: Write config

Construct or update `.content-ops/config.md` with the collected answers.

**If the file already exists:**

- Parse the existing YAML frontmatter
- Update only the fields set in this round: `author`, `default_language`, `languages`, `content_base_path`
- Add the project description as a YAML comment above `author`: `# [description]`
- If any of `content_index_path`, `research_cache_path`, `research_cache_ttl_days` are missing, append them with their default values
- Preserve all other existing fields exactly as-is

**If the file does not exist:**

Write a minimal config from scratch — do not copy `config.example.md`:

```yaml
---
# [project description from Q4]
author: "[answer]"
default_language: "[answer]"
languages: ["[answer]"]
content_base_path: "[answer]"

content_index_path: ".content-ops/content-index.json"
research_cache_path: ".content-ops/research-cache"
research_cache_ttl_days: 30
---
```

This file contains exactly the fields owned by this round. Every subsequent `/init` round will append its own section.

No .gitignore changes needed — .content-ops/config.md is tracked.

---

## Phase 5: Confirm and guide

```text
✅ Project config saved to .content-ops/config.md

  Author:      [value]
  Languages:   [value] (default: [value])
  Content:     [content_base_path]

Project description saved — will be used in /init style and /init strategy.

→ Next: /init content-types
  Define your content types (articles, glossary, etc.) and their paths.
```
