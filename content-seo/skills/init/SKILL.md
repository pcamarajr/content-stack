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
| project | `gsc_property` and `content_ops_config` are both set in `.content-seo/config.md` |
| credentials | GSC: `gsc_credentials_path` points to a readable file OR `$GOOGLE_APPLICATION_CREDENTIALS` is set and file exists. DataForSEO: `$DATAFORSEO_LOGIN` and `$DATAFORSEO_PASSWORD` both non-empty (check with Bash). GSC is required; DataForSEO is optional. |
| strategy | `seo_rules` has at least one content type key in `.content-seo/config.md` |

If `.content-seo/config.md` does not exist: all rounds are incomplete. Credentials are always checked live from the environment.

Use 🔄 (started) when the config file exists but only some required fields for that round are set.

### 3. Output

```text
## content-seo — Setup Status

GSC property: [gsc_property from config, or "—"]
Config:        .content-seo/config.md ([found | not found])
content-ops:   [found | not found]

✅ /seo init project      — [one-line summary, e.g. "sc-domain:mysite.com · content-ops linked"]
⬜ /seo init credentials  — not started
⬜ /seo init strategy     — not started

→ Next: /seo init [first incomplete round]

What each step does:
  project      — Link content-ops config and set GSC property + credentials path
  credentials  — Verify GSC service account access and optional DataForSEO credentials
  strategy     — Define per-content-type SEO rules (meta description length, H1 keyword)
```
