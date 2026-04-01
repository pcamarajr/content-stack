---
name: init
description: content-seo setup wizard. Run /init to see status, or /init [round] to run a setup step. Rounds: project, credentials, strategy.
argument-hint: "[project|credentials|strategy]"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Interactive setup wizard for content-seo. Configures the plugin for your project through a guided conversation.

**Arguments:** $ARGUMENTS

---

## Step 0: Route

Parse $ARGUMENTS:

- **Empty** → Run the Status Dashboard (below)
- **`project`** → Read `skills/init/rounds/project.md` (relative to plugin root) and follow its instructions completely
- **`credentials`** → Read `skills/init/rounds/credentials.md` (relative to plugin root) and follow its instructions completely
- **`strategy`** → Read `skills/init/rounds/strategy.md` (relative to plugin root) and follow its instructions completely
- **Unknown argument** → Tell the user the valid options: `project`, `credentials`, `strategy`

After completing any round, always end with a short "What's next?" line pointing to the next incomplete round.

---

## Status Dashboard

Only runs when $ARGUMENTS is empty.

### 1. Detect project basics

Try to read `.content-seo/config.md` → parse YAML frontmatter.
Try to read `.content-ops/config.md` → note if content-ops is present (display as info, not a requirement).

### 2. Determine round completion

| Round | Complete when |
| ---- | ----- |
| project | `site_url`, `default_locale`, and `target_audience` are all set in `.content-seo/config.md` |
| credentials | `$DATAFORSEO_LOGIN` and `$DATAFORSEO_PASSWORD` environment variables are both non-empty (check with Bash: `[ -n "$DATAFORSEO_LOGIN" ] && [ -n "$DATAFORSEO_PASSWORD" ] && echo "set" || echo "missing"`) |
| strategy | `pillars` has at least one entry AND `seo_rules` has at least one content type key in `.content-seo/config.md` |

If `.content-seo/config.md` does not exist: `project` and `strategy` rounds are incomplete. Credentials are always checked live from the environment.

Use 🔄 (started) when the config file exists but only some required fields for that round are set.

### 3. Output

```text
## content-seo — Setup Status

Site:        [site_url from config, or "—"]
Config:      .content-seo/config.md ([found | not found])
content-ops: [found | not found]

✅ /init project      — [one-line summary, e.g. "https://mysite.com · en · audience set"]
⬜ /init credentials  — not started
⬜ /init strategy     — not started

→ Next: /init [first incomplete round]

What each step does:
  project      — Set site URL, locale, and target audience description
  credentials  — Configure DataForSEO API credentials via environment variables
  strategy     — Define SEO content pillars and per-content-type SEO rules
```
