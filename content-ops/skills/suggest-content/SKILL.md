---
name: suggest-content
description: Suggest the next set of articles to write based on the content strategy and pillars. Cross-references existing content, backlog, and learning progression to find the best next articles. Reads paths from plugin config.
argument-hint: "[count] [theme]"
user-invocable: true
allowed-tools: Read, Glob, Grep, WebSearch, TodoWrite
---

Suggest the next set of articles to write based on the content strategy and pillars.

**Arguments:** $ARGUMENTS

## Argument Syntax

Parse `$ARGUMENTS` as: `[count] [theme]`

- **Count** (optional, default 5): how many articles to suggest
- **Theme** (optional): filter by theme. Available themes come from the `themes` array in config, or are inferred from existing tags if `themes` is not configured. Use `all` for no filter.

**Examples:**

- `/suggest-content` → 5 suggestions across all themes
- `/suggest-content 3` → 3 suggestions across all themes
- `/suggest-content 5 economics` → 5 suggestions filtered by a configured theme
- `/suggest-content 10 technical` → 10 suggestions filtered by a configured theme

## Phase 0: Load Config

Read `.content-ops/config.md`. Extract these values — they are used throughout all phases:

- `content_strategy`, `content_pillars_path`, `backlog_file`, `themes`
- If `themes` is not set, infer themes from existing tags.

## Phase 1: Load the Content Strategy and Pillars

This is the ONE skill where loading the complete content strategy is justified. Read ALL of these:

1. The content strategy from config (`content_strategy`) — The high-level editorial plan with topics, gaps, themes, and goals
2. If `content_pillars_path` is configured: all pillar files in that directory (e.g., `pillar-foundations.md`, `pillar-operations.md`, etc.) — these provide detailed roadmaps per theme

## Phase 2: Map Existing Coverage

Using the `content-inventory` skill (auto-loaded) and by reading:

1. The backlog file from config (`backlog_file`) — Already planned articles and their status
2. All existing article frontmatter — titles, tags, `translationKey`

Build a coverage map:

- Which strategy topics / pillar items have corresponding articles already?
- Which topics are partially covered (article exists but doesn't cover all objectives)?
- Which topics have no coverage at all?
- Which backlog items are already planned but not written?

## Phase 3: Identify Gaps and Priorities

Score potential articles by these criteria (in priority order):

1. **Learning prerequisite gaps** — If article A assumes knowledge from topic B, and B has no article, B is high priority. Readers need a clear learning path.
2. **Glossary orphans** — Glossary terms that exist but have no related article explaining the concept in depth. These terms were created as side effects of other articles but deserve their own content.
3. **Strategy/pillar coverage** — Topics in the content strategy or pillar files with zero articles are higher priority than adding a second article to an already-covered topic.
4. **Natural reading flow** — Articles that would be the logical "next read" after existing popular articles. Check existing articles' "What's Next" sections — if they link to non-existent articles, those are high priority.
5. **Theme balance** — If the blog is heavy on one theme, prioritize underrepresented themes (from config `themes` or inferred from tags).
6. **Backlog alignment** — Prefer topics already in the backlog (they were identified as needed).

If a **theme filter** was specified, only suggest articles matching that theme.

## Phase 4: Research Timeliness

For the top candidates, do a quick WebSearch to check:

- Is there a recent event that makes this topic especially timely? (e.g., upcoming halving, major protocol upgrade, regulatory news)
- Are there common misconceptions in current search results that this article could correct?

Timeliness is a bonus, not a requirement. Don't force it.

## Phase 5: Present Suggestions

Output a ranked list:

```text
## Suggested Next Articles

### Coverage Summary
- Strategy/pillar topics covered: X/Y
- Articles: X published, Y in backlog
- Theme distribution: [theme1: N, theme2: N, ...]

### Suggestions

#### 1. "Article Title" (priority: high)
- **Slug:** `article-slug`
- **Pillar/topic:** Pillar Name — "Topic Name" (or "N/A" if not mapped)
- **Theme:** from config themes or inferred tags
- **Tags:** [suggested tags]
- **Rationale:** [1-2 sentences: why this article should be written next]
- **Prerequisites:** [articles the reader should read first — verify they exist]
- **Key points to cover:** [3-5 bullet points from strategy/pillar files]
- **Backlog status:** in backlog (#N) | not in backlog yet
- **Timeliness:** [any current relevance, or "evergreen"]

#### 2. "Article Title" (priority: high)
...

#### 3. "Article Title" (priority: medium)
...
```

### After Each Suggestion Include:

- A one-line command the user can run to write it: `/write-content article <topic>`
- Or if it should go to the backlog first: "Add to backlog with: [suggested backlog entry]"

## Phase 6: Update Backlog (with permission)

Ask the user if they want to add any of the suggestions to the backlog file (from config `backlog_file`). If yes:

- Add as new `pending` entries with the suggested tags, priority, and pillar reference (if applicable)
- Don't remove existing backlog entries
