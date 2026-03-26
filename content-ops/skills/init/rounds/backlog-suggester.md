# Round: Backlog Suggester

Goal: Configure the `backlog-suggester` agent — the automated content gap detector
that runs after each article is written and powers `/suggest-content`.

---

## Phase 1: Check existing state

Read `.content-ops/config.md`. Parse the YAML frontmatter.

Check if a `backlog_suggester` section exists and is uncommented.

**If it already exists:**

Summarise the current settings in plain language (e.g., "auto-add on, mention
threshold 2, split suggestions off").

Use `AskUserQuestion` to ask:

```
question: "I found an existing backlog-suggester config. [summary]. What would you like to do?"
header: "Existing config"
options:
  - label: "Keep as-is"
    description: "Skip this round — current settings are fine"
  - label: "Review and update"
    description: "Go through the settings and change what you need"
```

- If **Keep as-is**: stop and guide to the next incomplete round.
- If **Review and update**: continue to Phase 2.

**If not yet configured:** continue to Phase 2 with a brief intro:

```
Let's set up the backlog-suggester — the agent that automatically identifies
content gaps after each article is written, and powers /suggest-content.

I'll ask a few questions. Answers shape the next question, so we'll go one at a time.
```

---

## Phase 2: Interview

Ask questions **one at a time** using `AskUserQuestion`. Each answer shapes the
next question — skip anything already answered or clearly implied. The structure
below is a guide, not a rigid script.

### Question 1: Auto-add vs. review-first

```
question: "When backlog-suggester finds a gap, should it add suggestions to the backlog automatically — or surface them for your approval first?"
header: "Suggestion mode"
options:
  - label: "Review first (Recommended)"
    description: "Agent surfaces candidates, you approve before they're written to the backlog"
  - label: "Auto-add"
    description: "Agent appends directly to the backlog without prompting — best for fully automated runs"
```

Store as `auto_add: false` (review-first) or `auto_add: true` (auto-add).

### Question 2: Mention threshold

This question matters more when `auto_add` is true — with review-first, the user
filters anyway. Adjust framing accordingly.

```
question: "How many times must a concept appear in an article before it qualifies as a backlog suggestion?"
header: "Mention threshold"
options:
  - label: "Once is enough (Recommended)"
    description: "Any mention qualifies — casts a wide net, you filter during review"
  - label: "At least twice"
    description: "Reduces noise — only recurring concepts get suggested"
  - label: "Three or more times"
    description: "High-signal only — concepts central to the article"
```

If `auto_add` is true, note that a higher threshold reduces backlog noise. Let the
user's answer drive the recommendation — don't override their preference.

Store as `mention_threshold: 1`, `2`, or `3`.

### Question 3: Topic boundaries

This shapes what the agent considers in-scope. Start by reading the content strategy
file (path from config) to get a sense of the site's focus areas. Use that as the
starting point.

```
question: "The agent uses topic_boundaries to avoid off-topic suggestions. Based on your strategy file, I'd describe your site's scope as:

  [1–3 sentence summary derived from strategy file]

Does that capture what should be in scope, or would you like to adjust it?"
header: "Topic scope"
options:
  - label: "That's accurate"
    description: "Use the derived summary as the topic boundary"
  - label: "I want to refine it"
    description: "I'll describe what's in and out of scope in my own words"
```

If **I want to refine it**: ask as a plain follow-up (no options — free-text reply):

```
Describe what's in scope for this site. Be specific about what should NOT be
suggested — the agent will use this to filter candidates.
```

Store the reply verbatim as `topic_boundaries`.

### Question 4: Content-type mapping

This controls whether a gap becomes a glossary entry or a full article.

```
question: "When the agent finds a gap, how should it decide whether to suggest a glossary entry or a full article?"
header: "Type mapping"
options:
  - label: "Let the agent decide (Recommended)"
    description: "Agent uses built-in heuristics: short definitions → glossary, people/events/technologies → article"
  - label: "I'll define rules"
    description: "Specify patterns — e.g. 'technical terms → glossary, historical events → article'"
```

- If **Let the agent decide**: store `content_type_mapping: []`.
- If **I'll define rules**: ask as a plain follow-up (no options — free-text reply):

```
Describe your mapping rules. For example: 'acronyms and protocol names → glossary;
people, events, and case studies → article'.
```

Parse the reply into a list of rule objects and store under `content_type_mapping`.
If parsing is ambiguous, store the raw string and add a comment.

### Question 5: Deduplication threshold

Only ask this if `auto_add` is true (where false positives have higher cost) OR if
the user has asked a technical question during this session. Skip otherwise — the
default (0.8) handles most cases well.

If you decide to ask:

```
question: "How aggressively should the agent collapse near-duplicate suggestions? For example, 'Lightning Network' and 'What is the Lightning Network?' are the same gap."
header: "Dedup sensitivity"
options:
  - label: "Standard (Recommended)"
    description: "80% similarity — collapses obvious rephrases, keeps genuinely distinct topics"
  - label: "Strict"
    description: "90% similarity — only collapses near-identical titles"
  - label: "Loose"
    description: "70% similarity — collapses more aggressively, may over-merge"
```

Store as `dedup_threshold: 0.8`, `0.9`, or `0.7`.

If skipped: store `dedup_threshold: 0.8`.

### Question 6: Split suggestions

```
question: "Should the agent flag articles that have grown too broad — suggesting they be split into focused pieces?"
header: "Split detection"
options:
  - label: "No — skip split detection (Recommended)"
    description: "Keep suggestions focused on missing content, not reorganising existing content"
  - label: "Yes — flag split candidates"
    description: "Agent will surface articles covering many distinct topics as split candidates"
```

Store as `suggest_splits: false` or `suggest_splits: true`.

---

## Phase 3: Write config

Append or update the `backlog_suggester` block in `.content-ops/config.md`. If the
key already exists, update it in place. If it does not exist, add it after the
existing keys. Preserve all other fields.

```yaml
backlog_suggester:
  mention_threshold: [1|2|3]
  auto_add: [true|false]
  topic_boundaries: "[scope description]"
  content_type_mapping: []  # or list of rules
  dedup_threshold: [0.7|0.8|0.9]
  suggest_splits: [true|false]
```

---

## Phase 4: Confirm and guide

```text
✅ backlog-suggester configured

  Mode:              [Auto-add | Review-first]
  Mention threshold: [N]
  Topic scope:       [first sentence of topic_boundaries]
  Type mapping:      [Agent decides | N custom rules]
  Dedup threshold:   [N]
  Split detection:   [On | Off]

Call it any time with /suggest-content.

→ Next: [next incomplete round, or "All rounds complete"]
```
