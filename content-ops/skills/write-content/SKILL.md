---
name: write-content
description: Create content of any configured type from a topic or from the content backlog. Orchestrates research, writing, style review, glossary creation, linking, and reindexing as focused sub-agents. Hooks handle tracker updates and build verification automatically.
argument-hint: "[<content-type>|backlog] <topic|terms|count|#ids|all>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, Task, TodoWrite
---

Unified content creation skill. Orchestrates focused sub-agents for each phase. Reindex runs in Phase 9 before commit. Hooks handle tracker updates and build verification after commits.

**Arguments:** $ARGUMENTS

---

## Phase 1: Parse Arguments

Determine **content type**, **source**, and **mode** from `$ARGUMENTS`.

First, read the `content_types` keys from `.content-ops/config.md` to get the list of valid content types. Then match the first word of `$ARGUMENTS` against those keys:

| Argument | Content Type | Source | Mode |
| ---- | ----- | ----- | ----- |
| `"Docker Containers"` | ask user (list all types) | user prompt | interactive |
| `article "Docker Containers"` | article | user prompt | interactive |
| `glossary "container, image"` | glossary | user prompt | interactive |
| `case-study "Project X"` | case-study | user prompt | interactive |
| `backlog 3` | from backlog | backlog | autonomous |
| _(empty)_ | ask user (list all types) | ask user | interactive |

**Rules:**

- If the first word matches a key in `content_types` → that is the content type; the rest is the topic or terms.
- If the first word is `backlog` → type comes from backlog entries, rest is the selection (count, `#ids`, `all`, `first N`, `last N`). If rest is empty, treat as `all`.
- If the first word does not match any configured type and is not `backlog` → treat the entire argument as a topic and ask the user which content type to use, listing all configured types.
- If arguments are empty → ask the user what they want to create, listing all configured content types.

**Source determines mode automatically:**

- `source: user prompt` → **interactive mode** — ask 3-5 interview questions before writing
- `source: backlog` → **autonomous mode** — context comes from the backlog entry, no interview

---

## Phase 2: Load Context

Read `.content-ops/config.md` in this phase. Extract and hold these values — they are used throughout all phases and passed explicitly to each subagent that needs them:

- `author`, `content_types`, `content_strategy`, `content_pillars_path`, `backlog_file`, `translation_tracker_file`, `reference_content`, `languages`, `default_language`, `source_hierarchy`, `research_cache_path`, `research_cache_ttl_days`, `content_index_path`, `linking_max_candidates`, `linking_max_links`, `image_generation`

**Also extract and hold:**

- The `glossary` config block (if present) — needed for Phase 7/8 conditional logic. Key fields: `glossary.enabled`, `glossary.auto_stubs`, `glossary.content_type`, `glossary.bidirectional_linking`.
- The `guidelines` value for the relevant content type. Note that `guidelines` is a **list of paths** per content type (not a single path).

**Also read (always):**

1. The backlog file (`backlog_file`) if mode is autonomous

**Also read (non-glossary content types):**

1. The content strategy (`content_strategy`) — understand topic context
2. If `content_pillars_path` is configured: find the matching pillar file for this topic

---

## Phase 3: Plan

Behavior depends on mode:

### Interactive mode (single article or glossary)

**For articles:** Ask the user 3-5 quick questions using a single AskUserQuestion call:

1. **Audience level** — Beginners or readers who know the basics?
2. **Key angle** — Main perspective or focus?
3. **Must-cover points** — Specific aspects, examples, or facts to include?
4. **Exclusions** — Anything to leave out?

**For glossary:** Check for duplicates using Glob on the glossary content path from config:

- If a term already exists: show it and ask to update or skip.
- For terms created as part of another workflow: skip duplicates silently.

### Autonomous mode (backlog)

1. Parse the selection argument:
   - `all` or _(empty)_ → all pending articles in order
   - `3` or `first 3` → first 3 pending articles
   - `last 2` → last 2 pending articles
   - `#1,#3,#5` → specific articles by their `#` number in the backlog
2. List selected articles in order with backlog numbers
3. For each article, find matching topic in the content strategy / pillar files and note context
4. Present the batch plan and **confirm with the user before proceeding**. After confirmation, work autonomously through all phases.

---

## Phase 4: Research

Spawn the `content-researcher` agent via the Task tool with a focused prompt. Pass only what the agent needs:

**For articles:**

```text
Use the content-researcher agent.

Topic: [topic]
Task: Research key facts — dates, numbers, technical details, historical context.
Config:
  source_hierarchy=[from config, or "not configured"]
  research_cache_ttl_days=[from config]
  research_cache_path=[from config]

Check the research cache first. Only do web searches for uncached or stale topics.
Return a structured research report.
```

**For glossary:**

```text
Use the content-researcher agent.

Terms: [comma-separated terms]
Task: Verify precise definitions, accurate examples, and correct technical details for each term.
Config:
  source_hierarchy=[from config, or "not configured"]
  research_cache_ttl_days=[from config]
  research_cache_path=[from config]

Check the research cache first. Return a structured research report per term.
```

**Store the agent's research report** — it is passed as input to Phase 5.

---

## Phase 5: Write

Spawn the `draft-writer` agent via the Task tool. Pass the research report from Phase 4 and focused context using this generic prompt:

```text
Use the draft-writer agent.

Content type: [content type name]
Topic: [topic or terms]
Output path: [content_types.<type>.path]/[default_language]/[slug].md
Author: [from config]
Frontmatter fields: [content_types.<type>.frontmatter from config]
[If interactive: Audience level, Key angle, Must-cover points, Exclusions from Phase 3]
[If backlog: Pillar context and objectives from the matching pillar file]

Research findings:
[full research report from Phase 4]

Follow the structure guide and formatting rules from the content-style skill for this content type.
Return the file path of the created content.
```

**For backlog items:** Also include articles created earlier in this batch as potential cross-references.

**Store the created file path(s)** — they are passed as input to Phase 5.5 and beyond.

---

## Phase 5.5: Image Generation

**Skip this phase entirely if any of the following are true:**

- `image_generation.enabled` is not `true` in config (or the `image_generation` section is absent)
- The content type is in `image_generation.skip_types` (e.g., `glossary`)

The `image-generator` agent will handle per-article word count and API key checks internally and report if skipped.

**For articles**, spawn the `image-generator` agent via the Task tool:

```text
Use the image-generator agent.

Article path: [file path from Phase 5]
Article slug: [slug from Phase 5]
Content type: [article or glossary]
Image generation config:
  enabled: [image_generation.enabled from config]
  provider: [image_generation.provider from config]
  model: [image_generation.model from config, if set]
  guidelines: [image_generation.guidelines from config]
  output_path: [image_generation.output_path from config]
  hero_dimensions: [image_generation.hero_dimensions from config]
  inline_dimensions: [image_generation.inline_dimensions from config]
  placement: [image_generation.placement from config]
  min_word_count: [image_generation.min_word_count from config]
  skip_types: [image_generation.skip_types from config]
  max_inline_images: [image_generation.max_inline_images from config, if set]
```

After the agent returns:

1. If the agent reported "skipped" or an error: note it and continue to Phase 6 without inserting images.
2. If images were generated:
   - Insert the hero image markdown after the closing `---` of the frontmatter, before the first paragraph
   - Insert each inline image markdown before its target `## Heading` as specified in the agent's output
   - Store the list of created image file paths — they are added to the git commit in Phase 9

**For glossary entries:** Skip this phase.

---

## Phase 6: Style Review

Spawn the `style-enforcer` agent via the Task tool with a focused prompt:

```text
Use the style-enforcer agent to review the content at [file path from Phase 5].
Content type: [content type name]
Config:
  word_range: [content_types.<type>.word_range from config]
  guidelines: [content_types.<type>.guidelines list from config]
  reference_content: [reference_content list from config]
Check sentence length, paragraph density, scope discipline, tone, plain English, structure, and linking.
Return a structured style review report with must-fix issues.
```

Apply any **must-fix** issues from the report before proceeding. If fixes are needed, edit the file(s) directly (they are in scope for this skill).

---

## Phase 7: Auto-create Missing Glossary Entries

**Skip this phase if any of the following are true:**

- The `glossary` config block is absent or `glossary.enabled` is false
- `glossary.auto_stubs` is false
- The current content type is the glossary type itself (i.e., `content_type_name == glossary.content_type`)

If all conditions pass, spawn the `glossary-creator` agent via the Task tool:

```text
Use the glossary-creator agent.

Article path: [file path from Phase 5]
Glossary path: [content_types.[glossary.content_type].path]/[default_language]/
Author: [from config]
[If batch: also list glossary entries created earlier in this batch to avoid duplicates]

Scan the article for technical terms that don't have glossary entries.
Create entries for any missing terms. Skip terms that already exist.
Return the list of created glossary entry file paths (or empty list if none created).
```

**Store the list of created glossary paths** — passed to Phase 8.

---

## Phase 8: Bidirectional Linking

Spawn the `content-linker` agent via the Task tool.

**Base prompt (always included):**

```text
Use the content-linker agent.

New content: [file path from Phase 5]
Content type: [content type name]
Default language: [from config]
Config:
  content_index_path: [content_index_path from config]
  linking_max_candidates: [linking_max_candidates from config, default 50]
  linking_max_links: [linking_max_links from config, default 10]
  url_patterns: [url_patterns from config, if set]

Ensure all cross-content links are complete:
- Update related content's relatedArticles
- Add inline links in existing content where the new topic is mentioned without a link

Return a linking report.
```

**If `glossary.enabled` AND `glossary.bidirectional_linking` are true, add to the prompt:**

```text
Glossary entries created in this run: [list from Phase 7, if any]

Also ensure glossary bidirectional links:
- Update glossary relatedArticles for terms referenced by the content
- Add inline links in existing articles where glossary terms are mentioned
```

Review the report. If there are warnings about broken references, fix them before committing.

---

## Phase 9: Reindex + Build + Commit

1. **Regenerate the content index**: Run the reindex procedure before committing:
   - Read config for `content_types`, `languages`, `content_index_path`
   - Use Glob to find all `.md`/`.mdx` files per type/language
   - Read each file's frontmatter only
   - Write `.content-ops/content-index.json` with the structured metadata
   - (Or invoke the reindex skill if available)

2. **Stage all created and modified files** (including the updated `content-index.json` and any image files from Phase 5.5)

3. **Commit**:

```text
content: add [content type] "<title>"

- New [content type]: [file path]
- Images: [N images, or "none"]
- New glossary: [list any created in Phase 7, or "none" or "skipped — glossary disabled"]
- Updated: [list any modified existing files from Phase 8]

Co-Authored-By: Claude <noreply@anthropic.com>
```

The post-commit hooks will automatically update trackers when content files are written.

The content index is regenerated in this phase (before commit) so it stays in sync with the committed content.

---

## Batch Mode (Backlog)

When mode is **autonomous** (source is backlog), phases 4-9 loop per item:

1. For each article in the batch, execute phases 4 through 9 sequentially
2. Each article gets its **own commit** — progress is saved even if the session is interrupted
3. Track across items: new glossary entries and new articles created so far, so subsequent items can reference earlier ones (pass this context to draft-writer and glossary-creator agents)
4. After all items complete, print a batch summary:

```text
## Batch Complete

### Articles written
- #1 "Title" → [path]
- ...

### Glossary entries created
- term1, term2, ...

### Existing content updated
- [list modified files]

### Commits
- [list of commit hashes and messages]
```
