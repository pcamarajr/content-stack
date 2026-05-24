# Positioning — Modern CSS Reference

## Anchor Positioning
**Tier**: 1+ | Chrome 125, Edge 125 (Safari / Firefox in progress)

> **astro-builder rule:** use only for **non-critical UI** (decorative tooltips, hover hints).
> For form validation popovers, menu dropdowns, or any UI users must reach, use `position: absolute`
> with manual coordinates or the Popover API's default top-layer placement. See `SKILL.md` Step 3.2.

Position an element relative to any other element on the page — no JS `getBoundingClientRect()` needed.

```css
/* 1. Name the anchor */
.trigger {
  anchor-name: --my-anchor;
}

/* 2. Position relative to it */
.tooltip {
  position: absolute;
  position-anchor: --my-anchor;

  top:    anchor(bottom);
  left:   anchor(center);
  translate: -50% 0;
  margin-top: var(--space-xs);
}

/* 3. Fallback positions */
@position-try --flip-above {
  top:    auto;
  bottom: anchor(top);
  margin-top: 0;
  margin-bottom: var(--space-xs);
}

.tooltip {
  position-try-fallbacks: --flip-above, --flip-left;
  position-try-order: most-width;
}
```

**`@supports` guard**:
```css
@supports (anchor-name: --x) {
  .tooltip {
    position: absolute;
    position-anchor: --my-anchor;
    top: anchor(bottom);
  }
}
```

---

## `inset` Shorthand
**Tier**: 2+ | Chrome 87, Safari 14.1, Firefox 87

```css
.overlay { inset: 0; }
.modal   { inset: var(--space-m); }
.tooltip { inset: auto auto 0 50%; } /* top right bottom left */
```

---

## Logical Properties
**Tier**: 2+ | Chrome 89, Safari 15, Firefox 87

Writing-mode aware layout — essential for i18n (RTL, vertical text).

```css
/* Physical → Logical mapping */
/* margin-left   → margin-inline-start */
/* margin-right  → margin-inline-end */
/* margin-top    → margin-block-start */
/* margin-bottom → margin-block-end */

.card {
  margin-inline:  auto;
  margin-block:   var(--space-m);
  padding-inline: var(--space-l);
  padding-block:  var(--space-m);

  border-inline-start: 3px solid var(--color-primary);
}

.icon {
  inline-size:  1.5rem;
  block-size:   1.5rem;
  max-inline-size: 100%;
}
```

---

## `position: sticky` with Logical Offsets
**Tier**: 2+

```css
.sticky-header {
  position: sticky;
  inset-block-start: 0;
  z-index: 10;
}
```

---

## `scroll-margin` / `scroll-padding`
**Tier**: 2+ | Chrome 69, Safari 14.1, Firefox 68

Offset scroll-to-anchor positions — essential when a sticky header covers anchor targets.

```css
:root { --header-height: 4rem; }

html { scroll-padding-top: var(--header-height); }

.section {
  scroll-margin-top: calc(var(--header-height) + var(--space-m));
}

html { scroll-behavior: smooth; }

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
}
```
