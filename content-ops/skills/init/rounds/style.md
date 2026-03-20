# Round: Voice & Style

Goal: Create a content style guide and link it in the config.

---

## Phase 1: Check existing state

Read `.content-ops/config.md`. Extract:

- `content_types` — to find any existing `guidelines` paths
- `reference_content` — existing reference files
- The project description comment (line starting with `#` above the `author` field)

Check if a style guide already exists: look at `guidelines` paths in `content_types`, and also check `.content-ops/content-style-guide.md` directly.

**If a style guide already exists:**

Read it. Summarize it in 3–5 bullets:

- Audience level
- Tone characteristics
- Key structural rules

Ask:

```text
I found an existing style guide at [path]:

  • [bullet 1]
  • [bullet 2]
  • [bullet 3]

Want to:
  A — Keep it as-is (skip this round)
  B — Update specific sections
  C — Replace it entirely
```

- If **A**: stop and guide to `/init strategy`.
- If **B**: ask which sections to update; run only the relevant questions from Phase 3.
- If **C**: continue to Phase 2.

**If no style guide exists:** continue to Phase 2.

---

## Phase 2: Scan existing content for style signals

Silently read 3–5 content files in the default language (pick the most recent or longest ones).

Note:

- Approximate average sentence length
- Jargon density (how many domain-specific terms per paragraph)
- Whether analogies or comparisons are used
- Whether articles end with a "next step" or related-content section
- Person (first / second / third)

These signals inform the style guide's examples and validate what the user tells you in Phase 3.

---

## Phase 3: Style interview

Ask questions **one at a time** using AskUserQuestion. Wait for each answer before asking the next.

Target: **4–6 exchanges maximum.** Stop when you have enough to write the guide.
Each answer shapes whether and how to ask the next question — skip anything that's already implied.

### Question 1: Reader

```text
Who is your primary reader?

  A — Complete beginners — assume zero prior knowledge
  B — Curious generalists — some context, can handle light complexity
  C — Practitioners — they know the field, want depth and precision
  D — It varies a lot by article
```

If **D**: follow up: "What's the most common type, if you had to pick one?" — note the variation, then treat as the primary.

Store this answer. It shapes the phrasing of all subsequent questions.

### Question 2: Tone (phrasing depends on Question 1)

**If beginner or generalist (A or B):**

```text
How should your writing handle complex ideas?

  A — Patient teacher: explain step by step, use analogies freely
  B — Storyteller: lead with a concrete example, then the concept
  C — Straight-talker: clear and direct, no unnecessary hand-holding
```

**If practitioner (C):**

```text
What's your default stance on technical depth?

  A — Go deep and show your work — readers can handle it
  B — State the position clearly, link to deeper reading
  C — Sharp and opinionated — lead with the conclusion
```

### Question 3: Paragraph comparison (show, don't ask)

Generate two short opening paragraphs on a topic relevant to this project. Infer the topic from the project description or the most common subject in existing articles. Label them A and B — one more accessible, one more precise.

```text
Two ways to open an article about [inferred topic]:

A: "[More accessible version — uses analogy, gentler pace, 2–3 sentences]"

B: "[More direct version — denser, more precise, assumes more context]"

Which feels closer to the voice you want?
  A — More like A
  B — More like B
  C — Somewhere between the two
```

Note: the contrast between the two paragraphs should be real and visible — not subtle. This exercise reveals more than any abstract question.

### Question 4: Article endings

```text
When you finish an article, what do you typically do?

  A — End cleanly — conclusion and done
  B — Point somewhere — related article, glossary term, or next action
  C — It varies by article
```

This determines whether the style guide defines a required closing-section convention.

### Question 5: Reference (optional)

```text
Is there any content — on your site or elsewhere — whose writing style you'd point to and say "that's the voice I want"?

Drop a URL, a file path, or just describe it.
(Press Enter to skip if nothing comes to mind.)
```

- If they give a **URL**: fetch it, extract 2–3 style markers (sentence length, tone, structure).
- If they give a **file path**: read it, note its key patterns.
- If they **skip**: proceed with what you have from Questions 1–4.

---

## Phase 4: Generate style guide

Using the answers from Phase 3 and the signals from Phase 2, create `.content-ops/content-style-guide.md`.

The guide must be **concrete and specific** — generic style guides are useless. Every rule needs an example.

Include these sections:

### Audience

A profile sentence: who the reader is and what they bring to the page.

### Voice

3–5 defining characteristics. Write them as statements, not adjectives.
Bad: "Friendly, clear, professional"
Good: "Explains every technical term the first time it appears", "Starts with why before how"

### Tone spectrum

Where this site sits on: formal ↔ casual, technical ↔ accessible, authoritative ↔ conversational.

### Sentence and paragraph rules

- Target sentence length (e.g., "aim for under 20 words; 25 is the ceiling")
- Paragraph density (e.g., "no more than 4 sentences per paragraph")
- One idea per paragraph

### Jargon policy

How to handle domain-specific terms: define inline, link to glossary, avoid entirely, or assume known.

### Structure conventions

- How to open an article (what the first paragraph should accomplish)
- Body conventions (subheadings, lists, code blocks if relevant)
- How articles end (based on Question 4's answer)

### What to avoid

3–5 specific anti-patterns for this project's voice. Make them concrete.
Example: "Don't open with a rhetorical question", "Don't hedge with 'it's important to note that'"

### Examples

Use the paragraph exercise from Question 3:

- One good opening paragraph (the one they chose, or a refined version)
- One bad opening paragraph (the one they rejected, with a note on why)

---

## Phase 5: Update config

Update `.content-ops/config.md`:

- For each content type in `content_types` that does not already have a type-specific `guidelines` file, set `guidelines: ".content-ops/content-style-guide.md"`
- Set `reference_content` to 2–3 of the most representative existing files found during Phase 2 scanning

Preserve all other fields.

---

## Phase 6: Confirm and guide

```text
✅ Style guide created at .content-ops/content-style-guide.md

Voice summary:
  • [characteristic 1 from the guide]
  • [characteristic 2]
  • [characteristic 3]

Config updated: guidelines paths and reference_content set.

→ Next: /init strategy
  Define your content pillars and editorial plan.
```
