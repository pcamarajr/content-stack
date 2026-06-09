# Typography — Modern CSS Reference

## `text-wrap: balance`
**Tier**: 2+ | Chrome 114, Safari 17.5, Firefox 121

Evenly distributes words across lines in headings. Eliminates awkward single-word orphans.
Use on headings — browser limits it to ~6 lines for performance.

```css
h1, h2, h3, h4, .card-title, .hero-headline {
  text-wrap: balance;
}
```

---

## `text-wrap: pretty`
**Tier**: 1+ | Chrome 117, Edge 117 (Safari / Firefox in progress)

Like `balance` but for body text — prevents orphaned last words. No line limit.

```css
p, li, blockquote {
  text-wrap: pretty;
}
```

**Combined pattern**:
```css
:is(h1, h2, h3, h4, h5, h6, .heading) { text-wrap: balance; }
:is(p, li, blockquote, figcaption)     { text-wrap: pretty; }
```

---

## `cap` and `lh` Units
**Tier**: 2+ | Chrome 109, Safari 16.4, Firefox 110 (`cap`); Chrome 109, Safari 17, Firefox 120 (`lh`)

- `cap` = height of a capital letter in the current font
- `lh` = current `line-height`
- `rlh` = root `line-height`
- `rex` = x-height of root font

```css
/* Icon aligned to cap height */
.icon {
  width: 1cap;
  height: 1cap;
  vertical-align: middle;
}

/* Textarea min/max in line units */
textarea {
  min-height: 3lh;
  max-height: 20lh;
}

/* Consistent rhythm */
.section {
  padding-block: 2rlh;
}
```

---

## `font-size-adjust`
**Tier**: 2+ | Chrome 127, Safari 17, Firefox 118 (`from-font` value)

Normalizes x-height across font fallbacks so text doesn't jump size while the web font loads.

```css
body {
  font-family: var(--font-body);
  font-size-adjust: from-font;
}

/* Or manual value */
body {
  font-size-adjust: 0.52;
}
```

---

## `hyphenate-limit-chars`
**Tier**: 2+ | Chrome 109, Safari 17 (Firefox partial)

```css
p {
  hyphens: auto;
  hyphenate-limit-chars: 8 4 3;
}
```

---

## `initial-letter`
**Tier**: 1+ | Chrome 110, Safari 9 (prefixed), Firefox 130

Drop caps natively.

```css
p::first-letter {
  initial-letter: 3;
  color: var(--color-primary);
  margin-right: 0.125em;
}
```

---

## `::marker`
**Tier**: 2+ | Chrome 86, Safari 14.1, Firefox 68

Style list bullets and numbers without `::before` hacks.

```css
li::marker {
  color: var(--color-primary);
  font-size: 0.75em;
}

ol li::marker {
  color: var(--color-primary);
  font-weight: 700;
}

ul.checklist li::marker {
  content: "✓ ";
  color: oklch(0.6 0.2 145);
}
```

---

## `counter()` / `counter-reset` / `counter-increment`
**Tier**: 2+ | broadly supported

CSS-only numbered steps without JS or manual numbering.

```css
.steps { counter-reset: step; }

.steps li {
  counter-increment: step;
}

.steps li::before {
  content: "Step " counter(step);
  display: block;
  font-weight: 700;
  color: var(--color-primary);
}

/* Nested counters — "1.1", "1.2", "2.1" */
ol {
  counter-reset: section;
  list-style: none;
}

ol li { counter-increment: section; }
ol li::before {
  content: counters(section, ".") " ";
}
```
