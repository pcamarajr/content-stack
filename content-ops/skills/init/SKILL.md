---
name: init
description: content-ops setup wizard. Run /init to see status, or /init [round] to run a setup step. Rounds: project, content-types, style, strategy, infra, images, link-building.
argument-hint: "[project|content-types|style|strategy|infra|images|link-building]"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Interactive setup wizard for content-ops. Configures the plugin for your project through a guided conversation.

**Arguments:** $ARGUMENTS

---

## Step 0: Route

Parse $ARGUMENTS:

- **Empty** → Run the Status Dashboard (below)
- **`project`** → Read `skills/init/rounds/project.md` (relative to plugin root) and follow its instructions completely
- **`content-types`** → Read `skills/init/rounds/content-types.md` (relative to plugin root) and follow its instructions completely
- **`style`** → Read `skills/init/rounds/style.md` (relative to plugin root) and follow its instructions completely
- **`strategy`** → Read `skills/init/rounds/strategy.md` (relative to plugin root) and follow its instructions completely
- **`infra`** → Read `skills/init/rounds/infra.md` (relative to plugin root) and follow its instructions completely
- **`images`** → Read `skills/init/rounds/images.md` (relative to plugin root) and follow its instructions completely
- **`link-building`** → Read `skills/init/rounds/link-building.md` (relative to plugin root) and follow its instructions completely
- **`backlog-suggester`** → Read `skills/init/rounds/backlog-suggester.md` (relative to plugin root) and follow its instructions completely
- **Unknown argument** → Tell the user the valid options: `project`, `content-types`, `style`, `strategy`, `infra`, `images`, `link-building`, `backlog-suggester`

After completing any round, always end with a short "What's next?" line pointing to the next incomplete round.

---

## Status Dashboard

Only runs when $ARGUMENTS is empty.

### 1. Detect project basics

Try to read `package.json` → extract `name`.
Try to read `.content-ops/config.md` → parse YAML frontmatter.

### 2. Determine round completion

| Round | Complete when |
| ---- | ----- |
| project | `author`, `default_language`, and `languages` are all set |
| content-types | `content_types` has at least one entry with a `path` |
| style | `reference_content` has at least one entry AND at least one `guidelines` path in `content_types` resolves to an existing file |
| strategy | `content_strategy` is set AND that file exists on disk |
| infra | the `backlog_file` path exists AND the `translation_tracker_file` path exists |
| images | `image_generation` key is present and uncommented in config AND `image_generation.guidelines` file exists on disk |
| link-building | `link_building` key is present and uncommented in config AND `link_building.guide` file exists on disk |
| backlog-suggester | `backlog_suggester` key is present and uncommented in config |

If `.content-ops/config.md` does not exist: all rounds are incomplete.

**Commented-out sections = not started.** When checking `images`, `link-building`, and `backlog-suggester`, read the raw file content (not just the parsed YAML). If every line of the section is prefixed with `#`, treat it as not started (⬜). Only mark it started (🔄) or complete (✅) once at least one line is uncommented.

Use 🔄 (started) when the config file exists but only some required fields for that round are set.

### 3. Output

```text
## content-ops — Setup Status

Site:   [name from package.json, or "—"]
Config: .content-ops/config.md ([found | not found])

✅ /init project           — [one-line summary, e.g. "en + it, author set"]
🔄 /init content-types     — [what's done and what's missing]
⬜ /init style             — not started
⬜ /init strategy          — not started
⬜ /init infra             — not started
⬜ /init images            — not started
⬜ /init link-building     — not started
⬜ /init backlog-suggester — not started

→ Next: /init [first incomplete round]

What each step does:
  project           — Set author, languages, and project description
  content-types     — Define content types (articles, glossary, etc.)
  style             — Build your voice, tone, and style guide
  strategy          — Define content pillars and editorial plan
  infra             — Set up trackers, localization guides, and file-based content index (via /reindex)
  images            — Configure image generation: style, color palette, placement rules
  link-building     — Define your internal and external linking strategy and conventions
  backlog-suggester — Configure the automated content gap detector and /suggest-content
```
