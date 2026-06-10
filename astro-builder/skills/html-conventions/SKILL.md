---
description: >
  Use this skill whenever writing, reviewing, or refactoring markup in an astro-builder project —
  creating or editing a layout, page-view, or component, building navigation, a form, a card grid,
  an image, a table, or a date display. Trigger before choosing between `<button>` and `<a>`,
  before adding any `onclick`, `role`, `aria-*`, or `tabindex` attribute, before writing alt text,
  before adding a heading, and when reviewing templates for accessibility. Semantics and
  accessibility are one domain: the right element IS the accessible one. Enforces landmark
  structure (one `<main>`, one `<h1>`), unbroken heading hierarchy, button-vs-link discipline,
  ARIA-only-when-native-can't, explicit alt text, labeled forms, and focus order — the markup
  counterpart to the css-conventions skill.
---

# HTML Conventions — astro-builder

The single source of truth for how markup is authored in an astro-builder project. Fires every
time an `.astro` template or HTML fragment is written, reviewed, or refactored — the counterpart
of `css-conventions`: that skill owns how things look, this one owns what things *are*.

**Why these rules exist:** the browser builds an accessibility tree from your markup, and
assistive technology navigates that tree — not your pixels. A native `<button>` ships keyboard
activation, focus, and screen-reader announcement for free; a `<div onclick>` ships none of them
and needs JS + ARIA + tabindex to badly reimplement what the element already was. Semantics and
accessibility are not two concerns: choosing the right landmark *is* the screen-reader navigation,
the right heading level *is* the document outline. Every rule below follows one principle —
**say what it is, and the platform does the rest.** The mechanical checks for these rules live in
`references/audit.md`; the audit runs them, this file defines them.

---

## 1 — Document structure & landmarks

Every page has exactly one skeleton, owned by `BaseLayout.astro`: `<html lang>`, a skip link,
then `header` → `nav` → `main` → `footer`. Page-views fill `<main>` — they never re-declare it.

- **`<html lang={Astro.currentLocale}>` always.** Never hardcode `lang="en"` — wrong `lang` makes
  screen readers pronounce one language with another's rules.
- **Exactly one `<main>` per page**, with `id="main"` as the skip-link target. It lives in the
  layout; a page-view or component that renders its own `<main>` is a violation.
- **Exactly one `<h1>` per page** — the page's title, inside `<main>`, owned by the page-view.
  The site name in the header is not an `<h1>`.
- **Skip link first.** The first focusable element in `<body>` is `<a href="#main">` with the
  `.skip-link` utility class (defined in `global.css` — see css-conventions §2.2), its text via
  `tl()` like every UI string.
- **`<nav>` for navigation blocks** — and when a page has more than one, each gets a
  distinguishing `aria-label` ("Main", "Footer", "Breadcrumb").

```astro
<!-- 🔴 Bad: divs with class names that *describe* landmarks instead of being them -->
<body>
  <div class="header"><div class="nav">...</div></div>
  <div class="content"><slot /></div>
  <div class="footer">...</div>
</body>

<!-- ✅ Good: the landmarks ARE the structure; skip link first; one main -->
<body>
  <a href="#main" class="skip-link">{tl("layout.skipToContent")}</a>
  <header>
    <nav aria-label={tl("layout.mainNav")}>...</nav>
  </header>
  <main id="main"><slot /></main>
  <footer>...</footer>
</body>
```

The init scaffold for this skeleton is `docs/init-templates/BaseLayout.astro.template` (plugin
root) — keep it in sync with these rules.

## 2 — Heading hierarchy

Headings are the document outline, not a font-size picker. Screen-reader users navigate by
heading level; a skipped level is a hole in their map.

- **No skips.** An `<h2>` section may contain `<h3>`s, never jump to `<h4>`.
- **Level = structure, size = CSS.** If a heading "looks too big", restyle it in the scoped
  `<style>` block — never demote it to a smaller level for looks.
- **Don't use headings for non-headings.** A card title that doesn't introduce a document section
  is a `<p>` with a class, not an `<h5>`.

```astro
<!-- 🔴 Bad: h4 chosen for its size; outline jumps h1 → h4 -->
<h1>{article.data.title}</h1>
<h4 class="byline">{tl("article.byline")}</h4>

<!-- ✅ Good: structure in the level, size in the CSS -->
<h1>{article.data.title}</h1>
<p class="byline">{tl("article.byline")}</p>
<h2>{tl("article.relatedTitle")}</h2>
```

## 3 — Buttons vs links

One question decides it: **does it navigate or does it act?**

| Element | Use for | Never for |
|---|---|---|
| `<a href>` | navigation — a URL changes (pages, anchors, downloads, mail) | triggering JS actions |
| `<button type="button">` | actions — open dialog, toggle theme, copy, submit-adjacent JS | navigation styled as a button |
| `<button type="submit">` | submitting the form it lives in | anything outside a form |
| `<div>` / `<span>` + onclick | **nothing, ever** | — |

- An `<a>` **without `href` is not a link** — it's unfocusable and unannounced. If there is no
  URL, it should have been a `<button>`.
- A "button-looking link" is still a link: style the `<a>` with a class — element choice follows
  behavior, never appearance.
- Clickable `<div>`/`<span>` is forbidden. No amount of `role="button"` + `tabindex="0"` +
  keydown handlers earns back what `<button>` gives for free.

```astro
<!-- 🔴 Bad: a div pretending, and a link that acts -->
<div class="button" onclick="openMenu()">Menu</div>
<a onclick="copyLink()">Copy link</a>

<!-- ✅ Good: behavior picks the element; CSS picks the look -->
<button type="button" class="menu-toggle">{tl("nav.menu")}</button>
<a href={`/${Astro.currentLocale}/pricing`} class="button">{tl("nav.pricing")}</a>
```

## 4 — ARIA minimum

The first rule of ARIA: **don't use ARIA when a native element exists.** ARIA adds announcements;
it never adds behavior — a `role` promises keyboard support that you then owe in JS.

| Bad | Good | Why |
|---|---|---|
| `<div role="button" tabindex="0">` | `<button>` | the element ships focus + keyboard + role |
| `<div role="navigation">` | `<nav>` | landmark element exists |
| `<span role="heading" aria-level="2">` | `<h2>` | heading element exists |
| `<div role="list">` + `role="listitem"` | `<ul><li>` | list elements exist |
| `<a aria-label="Read more about pricing">More</a>` | `<a href="...">{tl("home.pricingCta")}</a>` | fix the visible text, don't patch it invisibly |

- **`aria-label` doesn't fix wrong semantics.** It relabels an element; it can't change what the
  element is. Label only elements whose role is already right and whose accessible name is
  genuinely missing (icon-only buttons, multiple `<nav>`s).
- **Legitimate ARIA in this stack** (no native equivalent exists): `aria-current="page"` on the
  active nav link, `aria-expanded` on a disclosure toggle, `aria-label` to distinguish landmarks,
  `aria-describedby` for form errors (§6), `aria-hidden="true"` on purely decorative inline SVGs.
- **`aria-hidden="true"` never goes on a focusable element** — it hides the element from the
  accessibility tree while keyboard users can still land on it: a focus black hole.

## 5 — Images & alt text

Every `<img>` (and Astro `<Image />`) carries an explicit `alt`. Omitted alt is never valid —
screen readers fall back to announcing the file name.

- **Informative images: describe function or content** in context — what the user misses without
  it, not "image of".
- **Decorative images: `alt=""` explicitly.** Empty alt is a deliberate statement ("skip me"),
  omission is a bug.
- **Images of text are forbidden** — write the text, style it with CSS.
- Alt text is UI copy: locale-aware (content frontmatter or `tl()`), and reviewed under the
  `ux-writing` skill like any other string.

```astro
<!-- 🔴 Bad: omitted alt; filename gets announced. And "image of" noise. -->
<Image src={hero} />
<img src="/chart.png" alt="Image of a chart" />

<!-- ✅ Good: informative describes, decorative declares itself empty -->
<Image src={hero} alt={article.data.heroAlt} />
<img src="/divider.svg" alt="" />
```

## 6 — Forms

Every control has a programmatic label; every error is programmatically attached to its field.
Placeholder text is not a label — it vanishes on first keystroke (see `ux-writing`).

- **Label every control** with `<label for>` / `id` (or by wrapping). Visually hidden labels use
  `.sr-only`, never `display: none` (which removes them from the accessibility tree too).
- **Group related controls** (radios, checkboxes, address blocks) in `<fieldset>` with a
  `<legend>` — the legend is announced with each control in the group.
- **Associate errors** with `aria-describedby` pointing at the error element, plus
  `aria-invalid="true"` on the control. An error floating near the field in the DOM is invisible
  to a screen reader focused on the input.
- **Use `autocomplete`** on every field with a standard value (`name`, `email`, `postal-code`, …)
  and the right `type` (`email`, `url`, `tel`) — free correctness, mobile keyboards, and autofill.

```astro
<!-- 🔴 Bad: placeholder-as-label, orphan error, generic type -->
<input type="text" placeholder="Email" />
<span class="error">Invalid email</span>

<!-- ✅ Good: label, type, autocomplete, error wired to the field -->
<label for="email">{tl("form.emailLabel")}</label>
<input type="email" id="email" name="email" autocomplete="email"
  aria-invalid="true" aria-describedby="email-error" />
<p class="error" id="email-error">{tl("form.emailError")}</p>

<fieldset>
  <legend>{tl("form.planLegend")}</legend>
  <label><input type="radio" name="plan" value="free" /> {tl("form.planFree")}</label>
  <label><input type="radio" name="plan" value="pro" /> {tl("form.planPro")}</label>
</fieldset>
```

## 7 — Focus

Keyboard users experience the page as a sequence of focus stops. The DOM order is that sequence —
manage it with structure, not numbers.

- **Tab order = DOM order.** If tabbing feels wrong, reorder the markup (or fix a CSS
  `order`/`position` that diverges visual order from DOM order) — never patch with `tabindex`.
- **Positive `tabindex` is forbidden.** It hijacks the natural order for the whole page. Only
  `tabindex="0"` (join the order — rare, e.g. a scrollable region) and `tabindex="-1"`
  (programmatic focus target, like the skip-link's `#main`) are legitimate.
- **`autofocus` is forbidden** on content pages — it scrolls users past everything before the
  field and disorients screen readers mid-announcement.
- **Never remove the focus indicator without a replacement.** `outline: none` (or `0`) is allowed
  only alongside a `:focus-visible` rule that draws an equal-or-better indicator. The default
  lives in `global.css` `@layer base` (`:focus-visible { outline: 2px solid var(--color-focus) }`
  — see css-conventions); component CSS overrides the *style*, never the *existence*.
- **The skip link** (§1) is the first focus stop and becomes visible on focus (`.skip-link`
  utility in `global.css`).

```css
/* 🔴 Bad: indicator deleted, nothing given back */
.card a:focus { outline: none; }

/* ✅ Good: restyled, still unmistakably visible */
.card a:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}
```

## 8 — Lists, tables, time

Data with a shape gets the element with that shape — CSS can restyle anything, but only the right
element announces itself.

- **Sequences are lists.** Nav links, cards, tags, footer links: `<ul>`/`<ol>` + `<li>`, restyled
  with `list-style: none` and flex/grid — not a pile of sibling `<div>`s.
- **Tabular data is a `<table>`** with `<caption>`, `<thead>`, and `<th scope="col|row">` — never
  a CSS grid of `<div>`s (loses row/column announcement) and never a table for layout.
- **Dates and times are `<time datetime>`** with the machine-readable ISO value, displayed
  human-formatted per locale.

```astro
<!-- 🔴 Bad: shape lost — divs and a bare date string -->
<div class="tags">{tags.map((t) => <div class="tag">{t}</div>)}</div>
<span>June 10, 2026</span>

<!-- ✅ Good: list announced as "list, 3 items"; date machine-readable -->
<ul class="tags">{tags.map((t) => <li class="tag">{t}</li>)}</ul>
<time datetime={article.data.date.toISOString()}>
  {article.data.date.toLocaleDateString(Astro.currentLocale)}
</time>
```

---

## Verify before finishing

After writing or refactoring any markup, confirm:

- [ ] The page has exactly one `<main>` (in the layout) and exactly one `<h1>` (in the page-view).
- [ ] Heading levels descend without skips; no heading was chosen for its size.
- [ ] Every interactive element is a real `<button>` or `<a href>` — no clickable `div`/`span`,
      no `<a>` without `href`.
- [ ] No ARIA attribute was added where a native element could carry the meaning; every
      `aria-label` names an element whose role is already correct.
- [ ] Every image has an explicit `alt` — descriptive or deliberately `""`.
- [ ] Every form control has an associated label; groups have `fieldset`/`legend`; errors are
      wired via `aria-describedby`; standard fields carry `autocomplete`.
- [ ] No positive `tabindex`, no `autofocus`; any `outline: none` has a `:focus-visible`
      replacement.
- [ ] Lists, tables, and dates use `ul`/`ol`, `table` + `th scope`, and `<time datetime>`.
- [ ] All visible strings (including alt text and `aria-label` values) route through `tl()` or
      content frontmatter — never hardcoded (see `ux-writing`).

---

## Constraints

- Semantics are decided by behavior and meaning, never by appearance — CSS restyles the right
  element; it never excuses the wrong one.
- `BaseLayout.astro` owns the document skeleton (`html lang`, skip link, landmarks, `<main>`);
  page-views and components never re-declare landmarks.
- The mechanical checks for this skill live in `references/audit.md`, run by
  `/astro-builder:audit`. When a rule here changes, update its check there.
- Focus-indicator styling crosses into `css-conventions` — the rule (never remove without
  replacement) lives here; the token and `@layer base` placement live there.
- Always follow MDN for element and ARIA semantics, and the Astro 6 documentation:
  https://docs.astro.build/llms-small.txt
