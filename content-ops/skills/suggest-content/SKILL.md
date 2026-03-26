---
name: suggest-content
description: Identify content gaps and add suggestions to the backlog. Accepts an optional freeform payload to narrow scope. Without a payload, surveys the full corpus against pillars. Powered by the backlog-suggester agent.
argument-hint: "[freeform context]"
user-invocable: true
allowed-tools: Read, Task, TodoWrite
---

Identify content gaps and populate the backlog with focused, pillar-aligned suggestions.

**Arguments:** $ARGUMENTS

---

## Phase 1: Load config

Read `.content-ops/config.md`. Extract:

- `backlog_file`, `content_index_path`, `content_strategy`, `content_pillars_path`
- The full `backlog_suggester` block (may be absent — agent uses defaults)

---

## Phase 2: Run backlog-suggester

Spawn the `backlog-suggester` agent via the Task tool:

```text
Use the backlog-suggester agent.

Mode: user
Payload: [full $ARGUMENTS text, or empty string if no arguments]
Config:
  backlog_file: [backlog_file from config]
  content_index_path: [content_index_path from config]
  content_strategy: [content_strategy from config]
  content_pillars_path: [content_pillars_path from config, or "not configured"]
  backlog_suggester: [full backlog_suggester block from config, or "not configured — use defaults"]
```

The agent handles all gap analysis, deduplication, timeliness checks, user
interaction (approve/reject), and backlog writing. No further action needed from
this skill.
