# Component Patterns — Modern CSS Reference

## `accent-color`
**Tier**: 2+ | Chrome 93, Safari 15.4, Firefox 92

One-line theming for native form controls: checkboxes, radios, range inputs, progress bars.

```css
:root {
  accent-color: var(--color-primary);
}

input[type="range"]    { accent-color: oklch(0.7 0.15 150); }
input[type="checkbox"] { accent-color: var(--color-primary); }
```

---

## `env()` Variables
**Tier**: 2+ | Chrome 69, Safari 11.1, Firefox 65

Access environment variables — critical for iOS safe areas (notch, Dynamic Island, home indicator).

```css
.navbar {
  padding-top: env(safe-area-inset-top);
  padding-left: env(safe-area-inset-left);
  padding-right: env(safe-area-inset-right);
}

.bottom-nav {
  padding-bottom: max(env(safe-area-inset-bottom), var(--space-m));
}

:root {
  --safe-top:    env(safe-area-inset-top, 0px);
  --safe-bottom: env(safe-area-inset-bottom, 0px);
}
```

Requires `<meta name="viewport" content="viewport-fit=cover">` to activate safe areas.

---

## Media Feature Queries — Beyond Viewport Size

### `(hover: hover)` and `(pointer: fine)`
**Tier**: 2+ | Chrome 41, Safari 9, Firefox 64

```css
@media (hover: hover) {
  .card:hover { transform: translateY(-2px); }
  .button:hover { background: var(--color-primary-dark); }
}

@media (pointer: coarse) {
  .button { min-height: 44px; padding-inline: var(--space-m); }
}

@media (pointer: fine) {
  .data-table td { padding: var(--space-xs) var(--space-s); }
}
```

### `(prefers-contrast: more)`
**Tier**: 2+ | Chrome 96, Safari 14.1, Firefox 101

```css
@media (prefers-contrast: more) {
  :root {
    --color-text: #000000;
    --color-bg:   #ffffff;
  }

  .button {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }
}
```

### `(display-mode: standalone)`
**Tier**: 2+ | Chrome 45, Safari 13, Firefox 89

```css
@media (display-mode: standalone) {
  .install-banner { display: none; }
  .navbar { padding-top: env(safe-area-inset-top); }
}
```

### `(scripting: none)`
**Tier**: 1+ | Chrome 120, Safari 17, Firefox 113

Progressive enhancement — show fallback content when JS is unavailable.

```css
.accordion-content { display: none; }

@media (scripting: none) {
  .accordion-content { display: block; }
  .accordion-toggle  { display: none; }
}
```

---

## `scrollbar-color` / `scrollbar-width`
**Tier**: 2+ | Chrome 121, Safari 18.2, Firefox 64

Style scrollbars natively — no `::-webkit-scrollbar` hack needed.

```css
:root {
  scrollbar-color: var(--color-primary) transparent;
  scrollbar-width: thin;
}

.sidebar {
  scrollbar-color: var(--color-text-muted) transparent;
  scrollbar-width: thin;
  overflow-y: auto;
}

.carousel {
  scrollbar-width: none;
  overflow-x: scroll;
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

---

## Scroll Snap (carousels & galleries)
**Tier**: 2+

```css
.carousel {
  display: flex;
  overflow-x: scroll;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
  scrollbar-width: none;
}

.carousel-item {
  scroll-snap-align: start;
  flex: 0 0 100%;
}

@media (prefers-reduced-motion: reduce) {
  .carousel { scroll-behavior: auto; }
}
```
