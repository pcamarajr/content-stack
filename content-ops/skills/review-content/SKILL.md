---
name: review-content
description: Review content for tone, style, structure, glossary coverage, and linking completeness against the style guide.
argument-hint: <file-path>
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite
---

Review content for tone, style, structure, and linking completeness.

**File:** $ARGUMENTS

Pass the path to an article or glossary file (e.g., `src/content/articles/en/my-article.md`).

## Instructions

The `content-style` and `content-inventory` skills auto-load. Read the target file to understand what you're reviewing.

## Phase 1: Style Review via style-enforcer Agent

Read `.content-ops/config.md` to detect the content type from the file path (match against `content_types.*.path`).

Delegate the full style audit to the `style-enforcer` agent:

```text
Use the style-enforcer agent to review the file at [path].
Content type: [detected content type]
Config:
  word_range: [content_types.<type>.word_range]
  guidelines: [content_types.<type>.guidelines list]
  reference_content: [reference_content list]
Perform a complete review.
```

The agent returns a structured report with score, must-fix, should-fix, and consider categories.

## Phase 2: Glossary Coverage Audit

**Skip this phase if the `glossary` config block is absent or `glossary.enabled` is false.**

Read the `glossary` block from `.content-ops/config.md` to determine if glossary is enabled.

If enabled, scan the article body for domain-specific technical terms. For each:

1. **Has glossary entry + is linked?** — Good.
2. **Has glossary entry + NOT linked?** — Flag: "Term X is used but not linked to its glossary entry."
3. **No glossary entry + is a technical term?** — Flag: "Term X has no glossary entry. Consider creating one with `/write-content glossary X`."

Check that `relatedGlossary` in frontmatter includes terms linked in body. Note: `relatedGlossary` may also include terms relevant to the topic even without inline links — this is valid.

## Phase 3: Linking Completeness Audit

1. **Inline glossary links** — Only on first mention? Flag duplicates.
2. **Inline article links** — Related articles linked in body where natural?
3. **Frontmatter `relatedArticles`** — Includes all genuinely related articles?
4. **Frontmatter `relatedGlossary`** — Includes all glossary terms linked in body?
5. **Bidirectional check** — For each reference, check if the referenced content links back. Flag missing back-links as **recommendations** (not mandatory — there are cases where a back-link may not make sense).

## Phase 4: Glossary-Specific Checks (glossary files only)

**Skip this phase if the `glossary` config block is absent or `glossary.enabled` is false.**

**Also skip if the file being reviewed is not the glossary content type** (check file path against `content_types.[glossary.content_type].path` from config).

If applicable:

- **Definition length** — 1-2 sentences. Flag if longer.
- **Example** — One concrete sentence. Flag if missing or abstract.
- **Body content** — 1-2 dictionary-style sentences. Flag if longer.
- **Term capitalization** — Proper nouns capitalized, common terms lowercase.

## Phase 5: Combined Report

Present the style-enforcer agent's report combined with your glossary and linking findings:

```text
## Content Review: <title>

### Score: X/10 (from style-enforcer)

### Must Fix
- [Critical: style issues + broken links + missing glossary links for jargon]

### Should Fix
- [Style issues + missing back-links + duplicate links]

### Consider
- [Suggestions: glossary entries to create, additional linking, structural improvements]

### Looks Good
- [Strengths — always acknowledge what's working]
```

For each issue: exact location, what's wrong, concrete suggestion.

## Phase 6: Fix (with permission)

After presenting the report, ask the user if they want you to fix any issues. If yes:

1. Apply fixes in severity order (must fix → should fix → consider)
2. For linking fixes, delegate to the `content-linker` agent
3. Commit: `content: review fixes for "<title>"`
