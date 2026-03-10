---
name: fact-check
description: Fact-check content by verifying every claim against trusted sources.
argument-hint: <file-path>
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, WebSearch, WebFetch, Edit, Task, TodoWrite
---

Fact-check content by verifying claims against trusted sources.

**File:** $ARGUMENTS

Pass the path to an article or glossary file (e.g., `src/content/articles/en/my-article.md`).

## Phase 1: Extract Claims

Read the target file. Extract every factual claim:

- **Dates and historical events** — e.g., "X was created in 2009"
- **Numbers and statistics** — e.g., "N items total", "X per cycle"
- **Technical details** — How mechanisms work, protocol specifics
- **Attributions** — e.g., "created by X"
- **Temporal claims** — e.g., "every N years", "every N minutes"

List each claim clearly.

## Phase 2: Verify via content-researcher Agent

Delegate verification to the `content-researcher` agent. The agent uses a research cache (MCP) to avoid re-verifying known facts — it checks cached findings before doing web searches.

```text
Use the content-researcher agent to verify these claims from the article "[title]":

1. [claim 1]
2. [claim 2]
...

For each claim: confirm, flag as unconfirmed, or mark incorrect with the correct information and source URL.
Check the research cache first; only search the web for uncached or stale topics.
```

## Phase 3: Report

Present the agent's findings in this format:

```text
## Fact-Check Report: <article title>

### Summary
- Total claims checked: N
- Confirmed: N
- Unconfirmed: N
- Incorrect: N

### Details

| Claim | Status | Source | Notes |
|-------|--------|--------|-------|
| "X was created in 2009" | Confirmed | source-url/... | — |
| "reward is Y per cycle" | Incorrect | source-url/... | Corrected: Z per cycle |
```

### For Incorrect Claims

- Exact text that needs to change
- Corrected version
- Source citation

### For Unconfirmed Claims

- Why verification failed
- Suggestion: keep, rephrase, or remove

## Phase 4: Fix (with permission)

After presenting the report, ask the user if they want you to fix incorrect claims directly. If yes:

1. Fix only factually incorrect statements
2. Do not change tone, structure, or style
3. Run `pnpm build` to verify
4. Commit: `content: fact-check corrections in "<title>"`
