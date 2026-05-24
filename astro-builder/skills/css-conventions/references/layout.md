# Layout & Sizing — Modern CSS Reference

## `min()`, `max()`, `clamp()`
**Tier**: 2+ | Chrome 79, Safari 11.1, Firefox 75

Replace breakpoint-heavy sizing with fluid, math-driven values.

```css
/* clamp(min, preferred, max) */
h1 { font-size: clamp(1.5rem, 4vw + 1rem, 3.5rem); }
.container { width: clamp(320px, 90%, 1200px); }

/* min() — never exceeds the smallest value */
.sidebar { width: min(300px, 100%); }

/* max() — never goes below the largest value */
.hero { padding: max(2rem, 5vh); }

/* Fluid spacing tokens — define once in global.css */
:root {
  --space-s: clamp(0.75rem, 1.5vw, 1rem);
  --space-m: clamp(1rem,    2vw,   1.5rem);
  --space-l: clamp(1.5rem,  4vw,   3rem);
}
```

---

## Container Queries
**Tier**: 2+ | Chrome 105, Safari 16, Firefox 110

Style components based on their container size, not the viewport.

```css
.card-wrapper {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card { display: grid; grid-template-columns: 1fr 2fr; }
}

@container (min-width: 600px) {
  .card-title { font-size: var(--text-2xl); }
}
```

### Container Query Units
```css
/* cqw = 1% of container width, cqh = 1% of container height */
.card-heading {
  font-size: clamp(1rem, 4cqw, 2rem);
}
```

---

## Subgrid
**Tier**: 2+ | Chrome 117, Safari 16, Firefox 71

Align grid items across nested grid contexts.

```css
.grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: auto auto auto;
  gap: var(--space-m);
}

.card {
  display: grid;
  grid-row: span 3;
  grid-template-rows: subgrid;
}
```

---

## `aspect-ratio`
**Tier**: 2+ | Chrome 88, Safari 15, Firefox 89

Replace the padding-top hack entirely.

```css
.video  { aspect-ratio: 16 / 9; width: 100%; }
.avatar { aspect-ratio: 1; border-radius: 50%; }
```

---

## `field-sizing: content`
**Tier**: 1+ | Chrome 123 (Safari / Firefox in progress)

Auto-resize `<input>` and `<textarea>` to fit their content — no JS needed.

```css
textarea {
  field-sizing: content;
  min-height: 3lh;
  max-height: 20lh;
  resize: none;
}

input[type="text"] {
  field-sizing: content;
  min-width: 10ch;
}
```

**`@supports` guard for Tier 2/3**:
```css
@supports (field-sizing: content) {
  textarea { field-sizing: content; resize: none; }
}
```

---

## Intrinsic Sizing Keywords
**Tier**: 2+ | broadly supported

```css
.sidebar  { width: min-content; }
.tag      { width: max-content; }
.card     { width: fit-content(400px); }
```

---

## Dynamic Viewport Units
**Tier**: 2+ | Chrome 108, Safari 15.4, Firefox 101

Solve the classic `100vh` mobile browser bar problem.

```css
.hero    { height: 100svh; } /* always fully visible */
.overlay { height: 100dvh; } /* tracks actual available height */
.panel   { min-height: 100svh; max-height: 100lvh; }
```

---

## CSS Math Functions — `round()`, `mod()`, `rem()`, `abs()`, `sign()`
**Tier**: 2+ | Chrome 125, Safari 15.4, Firefox 118

```css
.card {
  width: round(var(--container-width), 8px); /* snap to 8px grid */
}

.font { font-size: round(nearest, 1.7rem, 0.25rem); }
.box  { width: round(up, 33.3%, 1px); }

.offset { translate: abs(var(--x)) 0; }

.arrow {
  rotate: calc(sign(var(--delta)) * 45deg);
}
```

---

## `margin-trim`
**Tier**: 1+ | Safari 16.4, Chrome 130 (Firefox in progress)

Remove the leading/trailing margin of children at the container edge.

```css
.card-body {
  margin-trim: block;
}

.tag-list {
  display: flex;
  margin-trim: inline;
}
```

**`@supports` guard**:
```css
@supports (margin-trim: block) {
  .card-body { margin-trim: block; }
}
```
