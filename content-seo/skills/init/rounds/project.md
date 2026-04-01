# Round: Project Setup

Goal: Configure site basics in `.content-seo/config.md`.

---

## Phase 1: Scan

Read silently before asking anything.

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

### Step 1b: Read existing configs

Always read (if they exist):

- `.content-seo/config.md` → parse existing config (if resuming)
- `.content-ops/config.md` → extract `default_language`, `languages`, and any site URL hints
- `package.json` → extract `name`, `description`

Then apply framework-specific extraction:

**Astro:** Read `astro.config.ts` or `astro.config.mjs` → extract `site` URL, `i18n.locales`, `i18n.defaultLocale`.

**Next.js:** Read `next.config.js` or `next.config.ts` → extract `i18n.locales`, `i18n.defaultLocale` if present.

**Nuxt:** Read `nuxt.config.ts` → extract `i18n.locales`, `i18n.defaultLocale` if present.

**Hugo:** Read `hugo.toml` or `config.toml` → extract `defaultContentLanguage`, `[languages]` table if present. Extract `baseURL` as site URL.

**Generic/unknown:** Skip framework-specific file reads.

Build a findings summary (detected framework + extracted data). Do not show it yet.

### Step 1b: Existing config check

If `.content-seo/config.md` already exists and has `site_url`, `default_locale`, and `target_audience` all set:

```text
I found an existing project config:

  Site URL:        [site_url]
  Locale:          [default_locale]
  Target audience: [target_audience]

Want to:
  A — Keep it and skip this round
  B — Review and update individual fields
  C — Start fresh
```

- If **A**: output "Project config already set. Run `/init credentials` to continue." and stop.
- If **B**: continue to Phase 2, pre-filling each question with the current value.
- If **C**: continue to Phase 2 as if the file were empty.

If no existing config: go straight to Phase 2.

---

## Phase 2: Interview

Ask each question separately using AskUserQuestion. Wait for the answer before asking the next. Use Phase 1 findings to suggest defaults.

### Question 1: Site URL

Pre-fill with the site URL detected from the framework config (e.g. `site` in Astro, `baseURL` in Hugo) if found.

```text
What is the base URL of your published site?

Examples: https://mysite.com  /  https://blog.example.com
```

Free-text.

### Question 2: Default locale

Pre-fill from content-ops `default_language` or the framework's i18n config if available.

```text
What is your site's primary locale code?

Examples: en  /  pt  /  es
```

Free-text.

### Question 3: Target audience

```text
In one or two sentences, describe your target audience and what they're looking for.

Example: "Developers building JAMstack sites who want to improve organic reach without an SEO agency."

(This is used by /audit and /optimize to evaluate content relevance.)
```

Free-text. Store exactly as written.

---

## Phase 3: Write config

**If the file already exists:**

- Parse the existing YAML frontmatter
- Update only the fields for this round: `site_url`, `default_locale`, `target_audience`
- If `content_ops_config` is missing and `.content-ops/config.md` exists on disk, add: `content_ops_config: ".content-ops/config.md"`
- Preserve all other existing fields exactly as-is

**If the file does not exist:**

Write a minimal config to `.content-seo/config.md`:

```yaml
---
# [target_audience from Q3]
site_url: "[answer]"
default_locale: "[answer]"
target_audience: "[answer]"
---
```

If `.content-ops/config.md` exists on disk, include:

```yaml
content_ops_config: ".content-ops/config.md"
```

Do not copy `docs/config.example.md`. Write only what was collected in this round.
No .gitignore changes — `.content-seo/config.md` is tracked in git.

---

## Phase 4: Confirm

```text
✅ Project config saved to .content-seo/config.md

  Site URL:   [site_url]
  Locale:     [default_locale]
  Audience:   [target_audience]

→ Next: /init credentials
  Configure your DataForSEO API credentials.
```
