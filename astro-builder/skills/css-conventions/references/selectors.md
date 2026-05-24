# Selectors & Logic — Modern CSS Reference

## `:has()` Selector
**Tier**: 2+ | Chrome 105, Safari 15.4, Firefox 121

The "parent selector". Conditionally style an element based on what it contains, or based on a sibling.

```css
/* Style a card that contains an image */
.card:has(img) { grid-template-columns: 1fr 2fr; }

/* Form field with error */
.field:has(input:invalid) label { color: var(--color-error); }

/* Nav item that is or contains the current page link */
.nav-item:has(> [aria-current="page"]) {
  background: var(--color-active-bg);
  font-weight: 600;
}

/* Select the label BEFORE a focused input (sibling, not parent) */
:has(+ input:focus) { color: var(--color-primary); }

/* Table row that has a checked checkbox */
tr:has(input[type="checkbox"]:checked) {
  background: color-mix(in oklch, var(--color-primary) 10%, transparent);
}
```

**`@supports` guard**:
```css
@supports selector(:has(a)) {
  .card:has(img) { grid-template-columns: 1fr 2fr; }
}
```

---

## `:is()` and `:where()`
**Tier**: 2+ | Chrome 88, Safari 14, Firefox 78

Group selectors without repeating them. `:is()` keeps specificity of highest selector. `:where()` has zero specificity.

```css
/* Instead of h1 a, h2 a, h3 a, h4 a */
:is(h1, h2, h3, h4) a { color: var(--color-primary); }

/* Zero-specificity reset */
:where(ul, ol) { list-style: none; margin: 0; padding: 0; }
```

---

## CSS Nesting
**Tier**: 2+ | Chrome 112, Safari 17.2, Firefox 117

Native `&` nesting — no preprocessor required. Inside astro-builder, **max 2 levels deep**.

```css
.card {
  padding: var(--space-m);
  border-radius: var(--radius-md);

  & .card-title {
    font-size: var(--text-xl);
  }

  &:hover {
    box-shadow: var(--shadow-md);
  }

  @media (min-width: 40rem) {
    display: grid;
    grid-template-columns: 1fr 2fr;
  }
}
```

---

## `@layer`
**Tier**: 2+ | Chrome 99, Safari 15.4, Firefox 97

Explicit cascade layer ordering. astro-builder mandates four layers in `global.css`:

```css
@layer reset, tokens, base, utilities;

@layer reset {
  *, *::before, *::after { box-sizing: border-box; }
}

@layer tokens {
  :root {
    --color-primary: oklch(0.6 0.2 260);
    /* ... */
  }
}

@layer base {
  body { font-family: var(--font-body); color: var(--color-text); }
}

@layer utilities {
  .sr-only { position: absolute; width: 1px; height: 1px; clip: rect(0,0,0,0); }
}
```

Component-scoped `<style>` blocks don't need `@layer` — Astro's scoping handles isolation.

---

## `@scope`
**Tier**: 1+ | Chrome 118, Safari 17.4 (Firefox in progress)

Rarely needed in astro-builder — Astro's scoped `<style>` blocks already isolate styles.
Use only when you genuinely need scope-within-scope (e.g. a content-rendered article needs its
own scoping inside a layout's scoped block).

```css
@scope (.prose) to (.no-prose) {
  h2 { font-size: var(--text-2xl); }
  p  { color: var(--color-text-muted); }
}
```

**`@supports` guard**:
```css
@supports at-rule(@scope) {
  @scope (.prose) { h2 { font-size: var(--text-2xl); } }
}
```

---

## `:nth-child(An+B of S)`
**Tier**: 1+ | Chrome 111, Safari 9, Firefox 113

Filter `nth-child` by a selector — skip non-matching siblings when counting.

```css
/* Every other .post (ignores .ad elements in the count) */
.post:nth-child(2n of .post) {
  background: var(--color-surface);
}
```
