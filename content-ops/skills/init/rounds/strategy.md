# Round: Content Strategy

Goal: Define content pillars and an editorial plan. Create `.content-ops/strategy.md` and per-pillar files under `.content-ops/pillars/`.

---

## Phase 1: Check existing state

Read `.content-ops/config.md`. Extract `content_strategy` and `content_pillars_path`.

Check if this round has already run: look for `content_strategy` in config — its presence is the authoritative signal. Also check for the strategy file on disk (try the configured path, then `.content-ops/strategy.md`) as secondary validation.

**If a strategy already exists:**

Read it. Show a summary:

```text
I found an existing content strategy at [path]:

  Pillars: [list pillar names]
  [One-line description of each]

Want to:
  A — Keep it as-is (skip this round)
  B — Add or update specific pillars
  C — Rewrite it entirely
```

- If **A**: stop and guide to `/init infra`.
- If **B**: ask which pillars to add or update; run Phase 3 only for those.
- If **C**: continue to Phase 2.

**If no strategy exists:** continue to Phase 2.

---

## Phase 2: Scan for coverage signals

Silently scan existing content:

- Read frontmatter from all articles in the default language — collect all `tags` values
- Group tags into apparent clusters (e.g., "bitcoin, blockchain, mining" → "Technical")
- Count articles per cluster

Also read the project description from the config (the comment line above `author`).

Build a coverage picture. This will be shown in Phase 3 to help the user name and define their pillars.

---

## Phase 3: Pillar interview

Ask questions one at a time. Each answer shapes the next.

### Question 1: Validate the coverage picture

Present the tag clusters found in Phase 2:

```text
Here's what your [N] existing articles cover, roughly:

  [Cluster A]: [N] articles — [example tags]
  [Cluster B]: [N] articles — [example tags]
  [Cluster C]: [N] articles — [example tags]

Do these groupings make sense as content pillars,
or would you organize it differently?

  A — Yes, those clusters look about right
  B — I'd group them differently
  C — I don't have much existing content yet
```

- If **A**: pre-fill pillar names from clusters; confirm each in Phase 3.
- If **B**: ask them to describe their preferred grouping (free text), then continue.
- If **C**: continue to naming pillars from scratch.

### Question 2: Name the pillars

```text
What are your content pillars? List 3–5 themes that organize your editorial plan.

Examples for a Bitcoin blog:     Bitcoin Basics, Technical Deep Dives, Economics
Examples for a cooking blog:     Quick Weeknight Meals, Baking, Global Cuisines
Examples for a dev tools blog:   CI/CD, Observability, Security, Career

Your pillars:
```

Free text. Parse comma-separated or line-separated names.

### Questions 3–N: One pillar at a time

For each pillar, ask two questions in sequence (separate AskUserQuestion calls):

#### Step A — Audience

```text
Pillar: "[Name]"

Who is this pillar for?
  A — Beginners (no prior knowledge needed)
  B — Intermediate (some background assumed)
  C — Advanced (practitioners, goes deep)
  D — Mixed / all levels
```

#### Step B — Core topics

```text
Name 3–5 core topics this "[Name]" pillar covers.
These become the starting point for your content roadmap.

Example: "What is Bitcoin, How wallets work, Private keys, Seed phrase security"
```

After collecting the topics, silently cross-reference against existing articles. Then show (not a question — just informative):

```text
Of those [N] topics in "[Name]":
  ✅ [topic] — covered by "[article title]"
  ✅ [topic] — covered by "[article title]"
  ⬜ [topic] — not covered yet
  ⬜ [topic] — not covered yet

Gaps will appear as top recommendations in /suggest-content.
```

Continue to the next pillar.

### After all pillars: source hierarchy (optional)

```text
For fact-checking and research, which sources do you trust most for this domain?
List domains in order of authority.

Examples for Bitcoin:  bitcoin.org, github.com/bitcoin/bips, developer.bitcoin.org
Examples for cooking:  seriouseats.com, food52.com, usda.gov
Examples for devops:   docs.docker.com, kubernetes.io, martinfowler.com

(Press Enter to skip — Claude will use general web search with no preference.)
```

Free text or skip. Store as `source_hierarchy` in config if provided.

---

## Phase 4: Generate files

### `.content-ops/strategy.md`

Include:

- **Editorial mission** — one paragraph derived from the project description + pillar themes
- **Pillar overview table** — Name | Audience | Core topics | Articles published
- **Per-pillar section** — name, description, target reader, core topics list, coverage note, top 1–2 uncovered topics to write next

### Per-pillar files in `.content-ops/pillars/`

One file per pillar at `.content-ops/pillars/[pillar-slug].md`.

Each file contains:

- Pillar name and one-sentence description
- Target audience
- Core topics as a checklist (✅ if an article exists, ⬜ if not — include the article slug for ✅ items)
- Writing guidance specific to this pillar (tone, depth, types of examples to use)
- Linked articles (slug list)

---

## Phase 5: Update config

Append to `.content-ops/config.md` as new fields (not updating placeholders):

- `content_strategy: ".content-ops/strategy.md"`
- `content_pillars_path: ".content-ops/pillars"`
- `source_hierarchy: [...]` (only if provided in the interview)

Preserve all other fields.

---

## Phase 6: Confirm and guide

```text
✅ Content strategy created

  .content-ops/strategy.md
  .content-ops/pillars/
    [pillar-1-slug].md  — [N] topics, [N] covered, [N] gaps
    [pillar-2-slug].md  — [N] topics, [N] covered, [N] gaps
    [pillar-3-slug].md  — [N] topics, [N] covered, [N] gaps

Run /suggest-content to see prioritized recommendations based on your pillars.

→ Next: /init infra
  Set up trackers and file-based content index (via /reindex).
```
