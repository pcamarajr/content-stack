# Round: Voice & Style

Goal: Create a general voice guide and per-type structure guides, then link them in the config.

---

## Phase 1: Check existing state

Read `.content-ops/config.md`. Extract:

- `content_types` — to find any existing `guidelines` paths
- `reference_content` — existing reference files
- The project description comment (line starting with `#` above the `author` field)

Check if this round has already run: look for `.content-ops/content-styles/general.md` on disk and `reference_content` in config — together they are the authoritative signal. Also check `guidelines` paths in `content_types` as secondary validation.

**If a style guide already exists:**

Read `.content-ops/content-styles/general.md`. Summarize it in 3–5 bullets:

- Audience level
- Tone characteristics
- Key voice rules

Ask:

```text
I found an existing style guide at .content-ops/content-styles/general.md:

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

## Phase 3 (Phase A): General Voice Interview

Ask questions **one at a time** using AskUserQuestion. Wait for each answer before asking the next.

This phase produces the general guide only — voice, tone, jargon, and what to avoid across all content types. Structure and format rules come later in Phase B.

Target: **4–6 exchanges maximum.** Stop when you have enough to write the guide.
Each answer shapes whether and how to ask the next question — skip anything that's already implied.
Follow up when answers are vague or interesting.

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

## Phase 4 (Phase A output): Generate general.md

Using the answers from Phase 3 and the signals from Phase 2, create `.content-ops/content-styles/general.md`.

This file covers **cross-cutting concerns only** — what applies to all content types regardless of structure or format. Do NOT include sentence/paragraph rules, structure conventions, or opening/closing conventions here; those go in per-type guides.

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

### Jargon policy

How to handle domain-specific terms: define inline, link to glossary, avoid entirely, or assume known.

### What to avoid

3–5 specific anti-patterns for this project's voice. Make them concrete.
Example: "Don't open with a rhetorical question", "Don't hedge with 'it's important to note that'"

### Examples

Use the paragraph exercise from Question 3:

- One good opening paragraph (the one they chose, or a refined version)
- One bad opening paragraph (the one they rejected, with a note on why)

---

## Phase 5 (Phase B): Per-Type Structure Interviews

Loop through each content type defined in `content_types` from config. For each type, run a short conversational interview using AskUserQuestion, one question at a time.

The interview adapts based on answers — not a fixed script. Starting points vary by type length.

**For long-form types** (word_range max > 500 — e.g., articles, guides, tutorials):

Target 3-5 exchanges. Starting points:

- Sentence length — target and ceiling
- Paragraph density — max sentences per paragraph
- Opening convention — how the first paragraph should work
- Closing convention — how articles end

Skip questions already implied by previous answers. Follow up when answers are vague or interesting.

**For short-form types** (word_range max <= 500 — e.g., glossary entries):

Target 1-2 exchanges. Starting points:

- Sentence length and density only
- No opening/closing conventions for short-form content

Each type's answers produce `.content-ops/content-styles/[type].md` (using the content type key as the filename) with these sections:

### Sentence and paragraph rules

- Target sentence length and ceiling
- Paragraph density limit
- One idea per paragraph

### Structure conventions (long-form only)

- How to open (what the first paragraph should accomplish)
- Body conventions (subheadings, lists, code blocks if relevant)
- How to close

---

## Phase 6: Update Config

Update `.content-ops/config.md`:

- For each content type, set `guidelines` as a list:
  ```yaml
  guidelines:
    - ".content-ops/content-styles/general.md"
    - ".content-ops/content-styles/[type].md"
  ```
- Set `reference_content` to 2–3 representative files from Phase 2 scanning

Preserve all other fields.

---

## Phase 7: Confirm and Guide

```text
Done! Style guides created in .content-ops/content-styles/

  General:
    • [characteristic 1 from general.md]
    • [characteristic 2]

  Per-type:
    • [type1] — [key structure rule]
    • [type2] — [key structure rule]

Config updated: guidelines lists and reference_content set.

-> Next: /init strategy
```
