# Round: Project Setup

Goal: Configure GSC connection in `.content-seo/config.md`. Site basics (URL, locale, audience) are read from content-ops — this round only asks for what's SEO-specific.

---

## Phase 1: Scan

Read silently before asking anything.

### Step 1a: Hard stop — content-ops required

Check if `.content-ops/config.md` exists:

```bash
[ -f ".content-ops/config.md" ] && echo "found" || echo "missing"
```

**If missing:** stop immediately with:

```text
content-seo requires content-ops to be initialized first.

Run /init in the content-ops plugin to set up your project, then return here.
```

### Step 1b: Read existing configs

Always read (if they exist):

- `.content-seo/config.md` → parse existing config (if resuming)
- `.content-ops/config.md` → extract `site_url`, `default_language`, `content_types`, `content_pillars_path`, `content_strategy`, `research_cache_ttl_days`
- `package.json` → extract `name`, `description`

Then detect framework for GSC property pre-fill:

| File(s) | Framework | Site URL source |
|---|---|---|
| `astro.config.ts` or `astro.config.mjs` | Astro | `site` field |
| `next.config.js` or `next.config.ts` | Next.js | meta only |
| `nuxt.config.ts` | Nuxt | meta only |
| `hugo.toml` or `config.toml` | Hugo | `baseURL` field |
| None found | generic | content-ops `site_url` |

Build a findings summary. Do not show it yet.

### Step 1c: Existing config check

If `.content-seo/config.md` already exists and has `gsc_property` set:

```text
I found an existing project config:

  GSC property:      [gsc_property]
  Credentials path:  [gsc_credentials_path, or "using GOOGLE_APPLICATION_CREDENTIALS"]
  content-ops config: [content_ops_config]

Want to:
  A — Keep it and skip this round
  B — Review and update
  C — Start fresh
```

- If **A**: output "Project config already set. Run `/seo init credentials` to continue." and stop.
- If **B**: continue to Phase 2, pre-filling each question with the current value.
- If **C**: continue to Phase 2 as if the file were empty.

If no existing config with `gsc_property`: go straight to Phase 2.

---

## Phase 2: Interview

Ask each question separately using AskUserQuestion. Wait for the answer before asking the next. Use Phase 1 findings to suggest defaults.

### Question 1: GSC property URL

Pre-fill with `sc-domain:[domain]` derived from content-ops `site_url` or framework-detected URL. Example: `site_url = "https://bitcoin101.org"` → suggest `sc-domain:bitcoin101.org`.

```text
What is your Google Search Console property URL?

This is the property identifier from GSC — not your site URL.

Examples:
  sc-domain:yoursite.com          (domain property — covers all subdomains and protocols)
  https://yoursite.com/           (URL-prefix property — exact match)

Tip: Use a domain property (sc-domain:) if available — it captures more data.
```

Free-text.

### Question 2: GSC service account credentials

```text
How will GSC credentials be provided?

  A — I have a service account JSON key file
      → Enter the path (e.g., /home/user/.secrets/gsc-sa.json)
  B — I'll set GOOGLE_APPLICATION_CREDENTIALS environment variable
      → The path will be read from that env var at runtime
```

Use AskUserQuestion with options A and B.

- If **A**: ask for the file path. Store as `gsc_credentials_path`.
- If **B**: store nothing for `gsc_credentials_path` (leave it out of config or set to `""` — the agent will fall back to the env var).

---

## Phase 3: Write config

**If the file already exists:**

- Parse the existing YAML frontmatter
- Update only the fields for this round: `content_ops_config`, `gsc_property`, and (if provided) `gsc_credentials_path`
- Preserve all other existing fields exactly as-is

**If the file does not exist:**

Write a minimal config to `.content-seo/config.md`:

```yaml
---
content_ops_config: ".content-ops/config.md"
gsc_property: "[answer from Q1]"
gsc_credentials_path: "[answer from Q2, or omit if using env var]"
---
```

`content_ops_config` always points to `.content-ops/config.md` (already verified to exist in Phase 1).

No `.gitignore` changes — `.content-seo/config.md` is tracked in git. The service account JSON key file lives outside the repo.

---

## Phase 4: Confirm

```text
✅ Project config saved to .content-seo/config.md

  GSC property:   [gsc_property]
  Credentials:    [gsc_credentials_path, or "from GOOGLE_APPLICATION_CREDENTIALS"]
  content-ops:    .content-ops/config.md

→ Next: /seo init credentials
  Verify your GSC service account can access the property.
```
