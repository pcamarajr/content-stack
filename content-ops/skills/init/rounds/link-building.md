# Round: Link Building

Goal: Capture the project's link building strategy through an agentic interview and write a project-specific guide that content-linker uses as its rule source.

---

## Phase 1: Check existing state

Read `.content-ops/config.md`. Parse the YAML frontmatter.

Check if a `link_building` section exists in config. If it does, check if the file at `link_building.guide` exists on disk.

**If both exist:**

Read the guide file. Summarise it in 3–5 bullets (strategic goal, scope, top rules).

Use `AskUserQuestion` to ask:

```
question: "I found an existing link building guide at [path from config]. [summary bullets]. What would you like to do?"
options:
  - label: "Keep as-is"
    description: "Skip this round — current settings are fine"
  - label: "Update sections"
    description: "Change specific parts while keeping the rest"
  - label: "Replace entirely"
    description: "Start fresh with a new link building guide"
```

- If **Keep as-is**: stop and guide to the next incomplete round.
- If **Update sections**: use a follow-up `AskUserQuestion` to ask which sections to update (multiSelect). Then run only the relevant parts of the interview in Phase 2 for those sections.
- If **Replace entirely**: continue to Phase 2.

**If not yet configured:** continue to Phase 2.

---

## Phase 2: Agentic interview

### Before asking anything

Read `.content-ops/config.md` silently. Extract:
- `content_types` — to understand what content types exist (articles, glossary, etc.)
- `languages` and `default_language` — to ground URL pattern questions
- Any existing `url_patterns` already in config

Do NOT ask the user about things already captured in other init rounds.

### Interview approach

You are a link building expert with deep knowledge of:
- Internal linking strategies (first-mention policy, bidirectional links, pillar/cluster architecture)
- External linking strategies (source quality, nofollow, affiliate/sponsored policies)
- SEO link equity and anchor text optimisation
- Content discoverability and reader experience

Conduct a free-form interview using `AskUserQuestion`. You own the interview — there is no fixed question count or fixed script. Track which domains you have covered and decide yourself when you have a complete enough picture to write a comprehensive guide.

**Domains to cover** (cover what is relevant based on answers — skip what is irrelevant):

| Domain | Key questions |
|---|---|
| Strategic goal | SEO-first, relevance-first, or hybrid? |
| Scope | Internal only, external only, or both? |
| Internal — URL patterns | What is the URL format for glossary links? For article links? (Use known content types and languages to suggest patterns) |
| Internal — frontmatter fields | What frontmatter arrays hold related glossary terms, related articles, related glossary entries? |
| Internal — first-mention | Link glossary terms on first mention only, or every mention? |
| Internal — link density | Maximum inline links per article? Any minimum? |
| Internal — bidirectional | Should linked content always link back? Strongly recommended or mandatory? |
| Pillar/cluster | Hub-and-spoke architecture, or flat linking? (Relevant when SEO-first) |
| External — source quality | What makes a source linkable? (Domain authority, recency, official docs, etc.) |
| External — nofollow | When to use `rel="nofollow"` or `rel="sponsored"`? |
| External — exclusions | Any domains or content types to never link to? Competitor policy? |
| Anchor text | Exact-match keyword anchors, natural language, or mixed? (Relevant when SEO-first) |

**Interview rules:**
- One question per message — always use `AskUserQuestion`
- When a user answer conflicts with a known best practice, recommend the better approach once with a brief explanation, then accept their decision. Never push twice.
- When you believe you have a complete picture of the user's strategy, move to Phase 3 — you do not need to cover every domain if some are not relevant.

### Starting the interview

Always open with strategic goal — this single answer shapes which other questions matter:

```
question: "What is the primary goal of your link building strategy?"
options:
  - label: "SEO-first"
    description: "Optimise for search — link equity, anchor text, and pillar/cluster architecture matter"
  - label: "Relevance-first"
    description: "Help readers find related content — contextual fit and reader experience drive decisions"
  - label: "Hybrid"
    description: "Both matter, balanced based on context"
```

---

## Phase 3: Write output and update config

### Write the guide

Generate `.content-ops/link-building-guide.md` as a prose document. This file is the complete source of truth for `content-linker` — it must be self-contained. Write all rules discovered in the interview. At minimum cover:

- Strategic goal and what it means in practice
- Scope (internal, external, or both)
- Internal linking rules: URL patterns for each content type and language, frontmatter field names, first-mention policy, link density caps, bidirectional policy
- External linking rules (if scope includes external): source quality bar, nofollow policy, affiliate/sponsored handling, excluded domains
- Anchor text policy
- Exclusions and edge cases

Write the guide in a style that an AI agent can reason against — concrete rules, not vague principles.

### Update config

Add or update the `link_building` section in `.content-ops/config.md`:

```yaml
link_building:
  guide: ".content-ops/link-building-guide.md"
```

Preserve all other fields.

### Completion message

```text
✅ Link building guide created at .content-ops/link-building-guide.md

Strategy summary:
  • [goal]
  • [scope]
  • [top rule 1]
  • [top rule 2]

Config updated: link_building.guide set.

→ Next: /init [next incomplete round]
```
