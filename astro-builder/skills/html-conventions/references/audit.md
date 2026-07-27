# HTML conventions — mechanical audit checklist

The machine-runnable checks for the `html-conventions` skill. `SKILL.md` is the source of every
rule; this file only encodes *how to detect* violations of those rules. `/astro-builder:audit`
runs this checklist as the HTML entry in its domain-checklist step — keep the two in sync by
editing the rule in `SKILL.md` first, then its check here.

**Contract for every check below:** a grep hit is a *candidate*, not a verdict. Confirm each hit
against the rule's intent (and its documented exceptions) before reporting. Report confirmed
findings with `file:line`, the offending fragment, and the suggested fix.

Before running: identify the layout file (`src/layouts/BaseLayout.astro` or equivalent) — several
checks treat the layout and page-views differently.

---

## HTML-1 — `<img>` without `alt`

- **Rule:** every image carries an explicit `alt` — descriptive or deliberately empty
  (SKILL.md §6).
- **Severity:** P1
- **Detect:** `grep -rn -E "<(img|Image)\b" src --include="*.astro" | grep -v "alt"`
  (multi-line tags evade the pipe — also open each `<Image` / `<img` hit and confirm an `alt`
  attribute exists somewhere in the tag).
- **Confirm:** `alt=""` is compliant (decorative); only a truly absent `alt` is a violation.
  Also flag `alt` values that begin with "image of" / "picture of" as P2 copy issues.
- **Fix:** add a descriptive `alt` from frontmatter or `tl()`, or an explicit `alt=""` if
  decorative.

## HTML-2 — Positive `tabindex`

- **Rule:** tab order is DOM order; positive `tabindex` is forbidden (SKILL.md §8).
- **Severity:** P1
- **Detect:** `grep -rn -E "tabindex=[\"'{]?[1-9]" src --include="*.astro"`
- **Confirm:** `tabindex="0"` and `tabindex="-1"` are the allowed values and won't match; any
  positive value is a violation.
- **Fix:** remove the attribute and reorder the markup (or fix the CSS `order`/`position` that
  made the DOM order feel wrong).

## HTML-3 — `autofocus`

- **Rule:** `autofocus` is forbidden on content pages (SKILL.md §8).
- **Severity:** P2
- **Detect:** `grep -rn "autofocus" src --include="*.astro"`
- **Confirm:** a search input inside a dedicated search page or an input inside a just-opened
  `<dialog>` may be acceptable — confirm with the user before reporting those; everywhere else
  is a violation.
- **Fix:** remove the attribute; let the user reach the field in natural order.

## HTML-4 — Click handlers on `div` / `span`

- **Rule:** clickable `div`/`span` is forbidden — actions are `<button>`, navigation is
  `<a href>` (SKILL.md §4).
- **Severity:** P1
- **Detect:** `grep -rn -E "<(div|span)[^>]*(onclick|on:click|role=\"button\")" src --include="*.astro"`
  — also grep `<script>` blocks for `addEventListener("click"` and confirm the target element
  is interactive.
- **Confirm:** a click listener on a container that only *delegates* to real `<button>`/`<a>`
  children is acceptable; a `div`/`span` acting as the control itself is a violation.
- **Fix:** replace with `<button type="button">` (action) or `<a href>` (navigation); move the
  visual treatment to a class.

## HTML-5 — `<a>` without `href`

- **Rule:** an `<a>` without `href` is not a link — unfocusable and unannounced (SKILL.md §4).
- **Severity:** P1
- **Detect:** `grep -rn -E "<a(\s[^>]*)?>" src --include="*.astro" | grep -v "href"`
  (multi-line tags evade the pipe — confirm each `<a` hit has `href` within the tag).
- **Confirm:** any anchor missing `href` is a violation — there is no allowed exception in this
  stack.
- **Fix:** add the real `href`; if there is no destination, it's an action — make it a
  `<button type="button">`.

## HTML-6 — More than one `<main>` or `<h1>` per page

- **Rule:** exactly one `<main>` (layout-owned) and one `<h1>` (page-view-owned) per page
  (SKILL.md §1).
- **Severity:** P1
- **Detect:** `grep -rln "<main" src --include="*.astro"` — only the layout(s) should appear.
  `grep -rc "<h1" src/page-views src/layouts src/components --include="*.astro"` — no file
  should count more than 1, layouts and shared components should count 0.
- **Confirm:** compose each page mentally (layout + page-view + components it renders): the
  *rendered* page must end up with exactly one of each. A page-view with one `<h1>` is correct;
  a component rendered multiple times that contains an `<h1>` is a violation even at count 1.
- **Fix:** remove `<main>` from page-views (the layout provides it); demote extra `<h1>`s to the
  level matching their place in the outline.

## HTML-7 — `<html>` without `lang`

- **Rule:** `<html lang={Astro.currentLocale}>` always; never hardcoded (SKILL.md §1).
- **Severity:** P1
- **Detect:** `grep -rn "<html" src --include="*.astro"`
- **Confirm:** the tag must carry `lang={Astro.currentLocale}` (or a variable derived from it).
  Missing `lang` and hardcoded `lang="en"` on a multilingual site are both violations.
- **Fix:** set `lang={Astro.currentLocale}` in the layout.

## HTML-8 — Skipped heading levels

- **Rule:** heading levels descend without skips; level = structure, size = CSS (SKILL.md §3).
- **Severity:** P2
- **Detect:** no reliable grep — inspection. For each page-view:
  `grep -on -E "<h[1-6]" src/page-views/*.astro` lists the heading sequence per file in source
  order; walk it and flag any step that increases by more than one (e.g. `h1` → `h3`). Account
  for headings contributed by components the page-view renders.
- **Confirm:** the sequence to judge is the *rendered* one (layout + page-view + components).
  A component designed to slot under an `<h2>` section legitimately starts at `<h3>`.
- **Fix:** renumber the heading to the correct level and restyle in scoped CSS if the size was
  the motivation.

## HTML-9 — Form control without an associated label

- **Rule:** every control has a programmatic label; placeholder is not a label (SKILL.md §7).
- **Severity:** P1
- **Detect:** `grep -rn -E "<(input|select|textarea)" src --include="*.astro"` — for each hit
  (skip `type="hidden"` and `type="submit"`), confirm a `<label for>` matching its `id` exists
  in the same file, or the control is wrapped in a `<label>`.
- **Confirm:** an `aria-label` on the control is technically labeled but flag it as P2 if a
  visible label was possible; `placeholder` alone is always a violation.
- **Fix:** add `<label for="...">` (`.sr-only` if it must be visually hidden), and while there:
  check `type` and `autocomplete` are set per SKILL.md §7.

## HTML-10 — `outline: none` without a `:focus-visible` replacement

- **Rule:** never remove the focus indicator without an equal-or-better replacement
  (SKILL.md §8; styling rules in css-conventions).
- **Severity:** P1
- **Detect:** `grep -rn -E "outline:\s*(none|0)" src --include="*.astro" --include="*.css"`
- **Confirm:** allowed only when the same component's `<style>` (or the same `global.css` rule
  set) draws a visible `:focus-visible` indicator for that element. `outline: none` with nothing
  given back is a violation.
- **Fix:** delete the `outline: none`, or pair it with a `:focus-visible` rule using
  `var(--color-focus)`.

## HTML-11 — `aria-hidden="true"` on focusable elements

- **Rule:** `aria-hidden` never goes on an element keyboard users can reach (SKILL.md §5).
- **Severity:** P1
- **Detect:** `grep -rn -E "<(a|button|input|select|textarea)[^>]*aria-hidden" src --include="*.astro"`
  — also check `aria-hidden` containers for focusable descendants.
- **Confirm:** `aria-hidden="true"` on decorative inline SVGs/icons is the legitimate use; on
  anything focusable (or wrapping something focusable) it is a violation.
- **Fix:** remove `aria-hidden`, or make the element genuinely inert (`tabindex="-1"` +
  `disabled`/`inert` as appropriate) if it truly must be hidden.

## HTML-12 — Unclosed tags

- **Rule:** every tag is explicitly closed — the Astro 7 Rust compiler errors on unclosed tags
  (SKILL.md §2).
- **Severity:** P0 — it breaks the build; nothing else can be audited until it's fixed.
- **Detect:** run `pnpm build` and read the compiler errors — each one names the file and the
  offending tag, which is the authoritative answer. To find candidates without building, compare
  opening and closing counts per file, e.g.
  `grep -c "<p" src/page-views/AboutPageView.astro` vs
  `grep -c "</p>" src/page-views/AboutPageView.astro`, repeated over
  `grep -rl "<p" src --include="*.astro"` for the block elements in play
  (`p`, `div`, `section`, `ul`, `ol`, `li`, `h1`–`h6`).
- **Confirm:** a count mismatch is a *candidate*, not a verdict — void and self-closed elements
  (`<img>`, `<br>`, `<link>`, `<Image />`), text or code samples containing `<p` inside a fenced
  block or a string, and prefix overlaps (`<p` also matches `<pre`) are all false positives. A
  build error is always a verdict.
- **Fix:** close the tag (two properly closed `<p>` elements, never `<p>…<p>…</p>`).

## HTML-13 — Block element inside a `<p>`

- **Rule:** no block-level element inside a `<p>` — Astro 7 no longer restructures invalid nesting
  (SKILL.md §2).
- **Severity:** P1
- **Detect:** `grep -rn -E "<p[^>]*>.*<(div|section|ul|ol|h[1-6])" src --include="*.astro"`,
  then read every multi-line `<p>` block by hand — the single-line grep cannot see a `<ul>` three
  lines below the opening `<p>`.
- **Confirm:** a block element inside a `<p>` is always a violation; there is no exception.
- **Fix:** hoist the block element out of the paragraph so it is a sibling, and move any styling
  that assumed the nesting.

## HTML-14 — Missing explicit whitespace between inline elements

- **Rule:** spacing between inline elements is authored explicitly — `compressHTML` defaults to
  `'jsx'` in Astro 7 and strips whitespace between elements (SKILL.md §2).
- **Severity:** P2
- **Detect:** `grep -rn -B1 -E "^\s*<(em|strong|span|a|code|b|i)\b" src --include="*.astro"` and
  inspect the hits whose *previous* line ends with an inline closing tag (`</span>`, `</a>`,
  `</strong>`, `</em>`, `</code>`) — those are the adjacencies that lost their space.
- **Confirm:** only a violation when a visible space is intended. Deliberately adjacent inline
  elements (a badge glued to a label, punctuation following a link) are correct as written; when
  in doubt, check the rendered page in `dist/`.
- **Fix:** put the elements on the same line with a literal space between them, or insert `{' '}`.
  Changing `compressHTML` is a project-wide decision, never the fix for one page.

## HTML-15 — Nested interactive elements

- **Rule:** no interactive element inside another interactive element (SKILL.md §2). This is an
  accessibility rule on its own footing — not something the Astro 7 compiler change introduced.
- **Severity:** P1
- **Detect:** `grep -rn -E "<a\b[^>]*>.*<(a|button)\b" src --include="*.astro"` and
  `grep -rn -E "<button\b[^>]*>.*<(a|button)\b" src --include="*.astro"`, then read every
  multi-line `<a>` / `<button>` block by hand — the single-line grep cannot see a nested control
  three lines below the opening tag.
- **Confirm:** always a violation — the accessibility tree gets an ambiguous target and the
  keyboard user gets a focus stop whose action is unpredictable.
- **Fix:** make the two actions siblings, or turn the outer element into a plain container.
