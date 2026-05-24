# Color & Theming — Modern CSS Reference

## CSS Custom Properties
**Tier**: 1–3 (universal)

```css
:root {
  --color-brand: oklch(0.6 0.2 260);
  --space-md: 1rem;
  --radius-sm: 0.375rem;
}
```

---

## OKLCH Color Space
**Tier**: 2+ | Chrome 111, Safari 15.4, Firefox 113

Perceptually uniform — equal lightness steps look visually equal. Better for gradients, palettes, and accessible contrast.

```css
/* oklch(lightness chroma hue) */
/* lightness: 0–1, chroma: 0–0.4, hue: 0–360 */

.button {
  background: oklch(0.6 0.2 260);   /* a rich blue */
  color: oklch(0.98 0 0);           /* near-white */
}

/* Gradient that stays vivid (no grey muddy middle) */
.gradient {
  background: linear-gradient(
    to right,
    oklch(0.6 0.2 30),   /* orange */
    oklch(0.6 0.2 260)   /* blue */
  );
}
```

**`@supports` guard for Tier 3**:
```css
.button { background: hsl(220 70% 50%); }
@supports (color: oklch(0 0 0)) {
  .button { background: oklch(0.6 0.2 260); }
}
```

---

## `color-mix()`
**Tier**: 2+ | Chrome 111, Safari 16.2, Firefox 113

Mix two colors in any color space. Replaces SCSS `mix()` and manual rgba opacity tricks.

```css
:root {
  --color-brand: oklch(0.6 0.2 260);
  --color-brand-light: color-mix(in oklch, var(--color-brand) 30%, white);
  --color-brand-dark:  color-mix(in oklch, var(--color-brand) 70%, black);
  --color-brand-muted: color-mix(in oklch, var(--color-brand), transparent 40%);
}
```

---

## Relative Color Syntax
**Tier**: 1+ | Chrome 119, Safari 16.4, Firefox 128

Derive a new color from an existing one by modifying individual channels.

```css
:root { --color-brand: oklch(0.6 0.2 260); }

.muted    { color: oklch(from var(--color-brand) l 0.05 h); }  /* desaturate */
.lighter  { color: oklch(from var(--color-brand) calc(l + 0.2) c h); }
.opposite { color: oklch(from var(--color-brand) l c calc(h + 180)); }
```

**`@supports` guard**:
```css
@supports (color: oklch(from red l c h)) {
  .muted { color: oklch(from var(--color-brand) l 0.05 h); }
}
```

---

## `light-dark()` Function
**Tier**: 1+ | Chrome 123, Safari 17.5, Firefox 120

> **astro-builder requires a fallback for this feature regardless of tier.** Safari 16.x returns
> invalid for `light-dark()`, breaking dark-mode color rendering. See `SKILL.md` Step 3.1.

Single declaration that adapts to `prefers-color-scheme` and `color-scheme` property. Replaces dual `@media` blocks.

```css
:root {
  /* Always define base + media-query fallback first */
  --color-bg: #ffffff;
  --color-text: #111111;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #1a1a1a;
    --color-text: #eeeeee;
  }
}

/* Progressive enhancement */
@supports (color: light-dark(#000, #fff)) {
  :root {
    color-scheme: light dark; /* required */
    --color-bg: light-dark(#ffffff, #1a1a1a);
    --color-text: light-dark(#111111, #eeeeee);
  }
}
```

---

## `accent-color`
**Tier**: 2+ | Chrome 93, Safari 15.4, Firefox 92

One-line theming for native form controls.

```css
:root {
  accent-color: var(--color-primary);
}

input[type="range"]    { accent-color: oklch(0.7 0.15 150); }
input[type="checkbox"] { accent-color: var(--color-primary); }
```
