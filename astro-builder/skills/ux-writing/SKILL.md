---
description: >
  Use this skill whenever writing or reviewing interface copy in an astro-builder project — button
  and CTA labels, error and validation messages, form labels and placeholders, empty states,
  loading states, success messages, confirmation dialogs, tooltips, and navigation labels. Trigger
  before adding any user-facing string to an `.astro` component or to an i18n locale JSON file, and
  when reviewing existing copy for clarity. Good UX writing is invisible: specific copy gets users
  through the task; vague copy creates support tickets and abandonment. Enforces verb+object button
  labels, the error-message formula, and clarity principles, and keeps copy consistent with the
  project style guide and i18n setup.
---

# UX Writing — astro-builder

The single source of truth for how interface copy is written in an astro-builder project. Fires
whenever a user-facing string is authored or reviewed. Clear copy helps users succeed; unclear copy
creates frustration, errors, and support tickets.

> Adapted from Impeccable's `clarify.md` (Apache-2.0). See `NOTICE.md`.

---

## Step 1 — Locate the string correctly (i18n first)

This plugin enforces i18n via `tl()` and locale JSON. **Before writing any visible string:**

1. UI strings belong in `src/i18n/<locale>.json`, surfaced through `tl()` — never hardcoded in
   `.astro` markup. (The audit flags hardcoded strings; see `/astro-builder:audit` Step 3.)
2. Write the English (default-locale) copy first, then ensure every other configured locale has the
   same key. Keep terminology consistent across keys — pick one term and reuse it.
3. Read `.astro-builder/style-guide.md` for the project's voice and tone, and
   `.astro-builder/design-system.md` for the register (brand vs product — see `docs/registers.md`).
   Copy in a product register is plainer and more functional; brand copy carries voice.

## Step 2 — Apply the clarity principles

Every string follows these. They are not negotiable.

1. **Be specific** — "Enter your email", not "Enter value".
2. **Be concise** — cut filler, never at the cost of clarity.
3. **Be active** — "Save changes", not "Changes will be saved".
4. **Be human** — "Something went wrong", not "System error encountered".
5. **Tell users what to do**, not just what happened.
6. **Be consistent** — one term per concept, throughout.

**Never:** use jargon without explanation · blame the user ("You made an error" → "This field is
required") · be vague without explanation · use passive voice unnecessarily · over-explain · use
humor for errors (be empathetic instead) · vary terminology for variety · repeat information ·
use a placeholder as the only label (it disappears when the user types).

## Step 3 — Pattern reference

Resolve the **primary message** (the ONE thing the user needs to know), the **action needed**, and
the **tone** for the user's mental state, then apply the matching pattern.

### Button & CTA text

Verb + object. Describe the outcome. Never "OK", "Submit", "Yes/No", or "Click here".

| Bad | Good | Why |
|---|---|---|
| OK | Save changes | Says what will happen |
| Submit | Create account | Outcome-focused |
| Yes | Delete message | Confirms the action |
| Cancel | Keep editing | Clarifies what "cancel" means |
| Click here | Download PDF | Names the destination |

For destructive actions, name the destruction and show the count: "Delete 5 items", not "Delete
selected". Prefer "Delete" (permanent) vs "Remove" (recoverable) deliberately.

### Error & validation messages

Formula: **what went wrong (plain language) → how to fix it → example if helpful.** Don't blame the
user; link to help when applicable.

- Bad: `Error 403: Forbidden` → Good: "You don't have permission to view this page. Contact your
  admin for access."
- Bad: `Invalid input` → Good: "Email addresses need an @ symbol. Try: name@example.com"

### Form labels & instructions

Clear specific labels, not generic placeholders. Show format with an example placeholder, put
instructions before the field, explain why you're asking when it isn't obvious.

- Bad: `DOB (MM/DD/YYYY)` → Good: label "Date of birth" + a format placeholder.
- Bad: `Enter value here` → Good: "Your email address".

### Empty states

Explain why it's empty, show the next action, make it welcoming — not a dead end.

- Bad: "No items" → Good: "No projects yet. Create your first project to get started."

### Loading states

Set expectations and explain what's happening; offer an escape hatch when appropriate.

- Bad: "Loading…" (for 30s) → Good: "Analyzing your data… this usually takes 30–60 seconds".

### Success messages

Confirm what happened and what's next; brief but complete; match the emotional moment.

- Bad: "Success" → Good: "Settings saved. Changes take effect immediately."

### Confirmation dialogs

State the specific action, explain consequences for destructive ones, use clear button labels. Don't
overuse confirmations — reserve for risky, irreversible actions.

- Bad: "Are you sure?" → Good: "Delete 'Project Alpha'? This can't be undone." with a "Delete
  project" button (not "Yes").

### Help text & tooltips

Add value beyond the label; answer the implicit "What is this?" / "Why do you need this?"; keep it
brief.

- Bad: "This is the username field" → Good: "Choose a username. You can change this later in
  Settings."

### Navigation & wayfinding

Specific descriptive labels in the user's language, not internal jargon. Make hierarchy and current
location clear (breadcrumbs, active state).

- Bad: "Items" / "Things" → Good: "Your projects" / "Team members".

## Step 4 — Verify

- **Comprehension** — understandable without extra context?
- **Actionability** — does the user know what to do next?
- **Brevity** — as short as possible while staying clear?
- **Consistency** — matches terminology used elsewhere and in the other locales?
- **Tone** — right for the situation and the project's register?

---

## Constraints

- All visible UI strings route through `tl()` + locale JSON — never hardcode in markup.
- Keep terminology consistent across every locale file, not just English.
- Match `.astro-builder/style-guide.md` voice; defer to it on any conflict.
- Brand-register copy may carry more voice; product-register copy stays plain and functional.
