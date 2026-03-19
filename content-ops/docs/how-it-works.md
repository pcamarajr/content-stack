# How it works

content-ops is built around a **phase-based orchestration model**. Rather than one monolithic prompt, complex tasks are broken into focused phases — each handled by a dedicated agent or skill. This keeps each step predictable, auditable, and independently improvable.

---

## The write-content pipeline

When you run `/write-content`, the skill coordinates a sequence of 9 phases:

```
Phase 1  → Parse arguments (article / glossary / backlog item)
Phase 2  → Load config, guidelines, reference content
Phase 3  → Plan the topic (interactive Q&A or backlog parsing)
Phase 4  → Research (content-researcher agent + cache)
Phase 5  → Draft (draft-writer agent)
Phase 5.5→ Generate images (image-generator agent, optional)
Phase 6  → Style review (style-enforcer agent)
Phase 7  → Auto-create missing glossary entries (glossary-creator agent)
Phase 8  → Bidirectional linking (content-linker agent)
Phase 9  → Reindex + commit
```

Each phase reads from files, calls an agent, and writes results back to files. Nothing is held in memory between phases — this makes the pipeline resumable and transparent.

---

## Agents and what they own

| Agent | Phase | Responsibility |
|---|---|---|
| `content-researcher` | 4 | Web research + cache read/write |
| `draft-writer` | 5 | Write the article or glossary entry |
| `image-generator` | 5.5 | Build image prompts, call API, save files |
| `style-enforcer` | 6 | Review against style guide + reference articles |
| `glossary-creator` | 7 | Scan article for terms that need glossary entries |
| `content-linker` | 8 | Find and add bidirectional links |

---

## Interactive vs. backlog mode

**Interactive mode** (`/write-content article "Topic"`):
- Phase 3 asks you a few questions about angle, target audience, and key points
- The rest runs automatically

**Backlog mode** (`/write-content backlog 3`):
- Reads your backlog file, picks the next N pending items
- Runs the full pipeline for each item autonomously
- Each item gets its own git commit — if interrupted, completed items aren't lost

---

## How linking works

The `content-linker` agent uses a two-step approach to avoid reading every file in your content directory:

1. **Filter** — read `content-index.json`, filter candidates by language and type (capped at 50)
2. **Rank** — single LLM pass to select the most relevant matches (capped at `linking_max_links`, default 10)
3. **Edit** — read only the selected files, add links bidirectionally (frontmatter arrays + inline)

This means linking scales even on large content sites — the agent only reads files it's actually going to link to.

---

## How research caching works

The `content-researcher` agent writes findings to `.content-ops/research-cache/<topic>.json`. On subsequent runs for the same topic, it reads the cache first and skips re-searching if the findings are fresh (controlled by `research_cache_ttl_days` in config, default 30 days).

The cache is committed to git — so it's portable across machines and sessions, including Claude Code on the web.

---

## Hooks

The plugin auto-loads three hooks — no manual configuration needed:

| Hook | Trigger | What it does |
|---|---|---|
| `SessionStart` | Opening Claude Code | Displays your content-ops config summary |
| `PostToolUse` (Edit/Write) | After file writes | Reminds you to update backlog/translation tracker |
| `PostToolUse` (Bash/git commit) | After a commit | Suggests running reindex if content changed |

---

## Auto-loaded skills

Some skills are loaded silently by agents — you never invoke them directly:

| Skill | What it provides |
|---|---|
| `content-style` | Voice, tone, sentence rules, structure guidelines |
| `content-image-style` | Image prompt patterns, file naming, alt text |
| `content-inventory` | Snapshot of all articles/glossary per language |
| `internal-linking` | Bidirectional linking conventions |
| `update-trackers` | Logic for updating backlog and translation tracker |

These exist as separate skills so they can be updated independently without touching agent prompts.

---

## File flow overview

```
.content-ops/
├── config.md                 ← Read by every skill at startup
├── backlog.md                ← Read/written by write-content + update-trackers
├── translation-tracker.md    ← Read/written by translate + update-trackers
├── strategy.md               ← Read by suggest-content + write-content
├── pillars/                  ← Read by suggest-content + write-content
├── localization/             ← Read by translate agent
├── content-index.json        ← Written by reindex, read by content-linker
└── research-cache/           ← Written + read by content-researcher
```

Everything is plain files tracked in git. No database, no server, no background process.
