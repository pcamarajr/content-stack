# Miscellaneous — Modern CSS Reference

## `@property`
**Tier**: 2+ | Chrome 85, Safari 16.4, Firefox 128

Define typed custom properties. Enables transitions on custom properties and prevents inheritance.

```css
@property --angle {
  syntax: "<angle>";
  inherits: false;
  initial-value: 0deg;
}

.button {
  --angle: 0deg;
  background: conic-gradient(from var(--angle), var(--color-primary), var(--color-accent));
  transition: --angle 1s;
}

.button:hover { --angle: 360deg; }

/* Clamped/ranged custom properties */
@property --progress {
  syntax: "<percentage>";
  inherits: false;
  initial-value: 0%;
}
```

---

## `content-visibility`
**Tier**: 2+ | Chrome 85, Edge 85, Firefox 125 (Safari partial)

Skip rendering off-screen content. Significant performance boost for long pages.

```css
.page-section {
  content-visibility: auto;
  contain-intrinsic-size: auto 400px;
}

.offscreen-panel {
  content-visibility: hidden;
}
```

---

## `overscroll-behavior`
**Tier**: 2+ | Chrome 63, Safari 16, Firefox 59

Stop scroll events from propagating to the page when a scrollable element hits its boundary.

```css
.modal {
  overflow-y: auto;
  overscroll-behavior-y: contain;
}

.carousel {
  overflow-x: scroll;
  overscroll-behavior-x: contain;
}

html {
  overscroll-behavior: none;
}
```

---

## `::backdrop`
**Tier**: 2+ | Chrome 67, Safari 15.4, Firefox 47

Style the backdrop of `<dialog>`, fullscreen elements, or popovers.

```css
dialog::backdrop {
  background: oklch(0 0 0 / 0.5);
  backdrop-filter: blur(4px);
  transition: opacity 0.3s;
}

[popover]::backdrop {
  background: transparent;
}
```

---

## Popover API
**Tier**: 1+ | Chrome 114, Safari 17, Firefox 125

Native popovers without JS positioning libraries.

```html
<button popovertarget="my-menu">Open</button>
<div id="my-menu" popover>Menu content</div>
```

```css
[popover] {
  opacity: 0;
  transform: translateY(-0.5rem);
  transition: opacity 0.2s, transform 0.2s,
              display 0.2s allow-discrete,
              overlay 0.2s allow-discrete;
}

[popover]:popover-open {
  opacity: 1;
  transform: translateY(0);
}

@starting-style {
  [popover]:popover-open {
    opacity: 0;
    transform: translateY(-0.5rem);
  }
}
```

---

## `scroll-snap`
**Tier**: 2+ | Chrome 69, Safari 11, Firefox 68

```css
.carousel {
  display: flex;
  overflow-x: scroll;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
}

.carousel-item {
  scroll-snap-align: start;
  flex: 0 0 100%;
}
```

---

## `image-set()`
**Tier**: 2+ | Chrome 113, Safari 17.2, Firefox 89

Responsive images in CSS — like `srcset` for background images.

```css
.hero {
  background-image: image-set(
    url("hero.avif") type("image/avif"),
    url("hero.webp") type("image/webp"),
    url("hero.jpg")  type("image/jpeg")
  );
}
```

---

## `backdrop-filter`
**Tier**: 2+ | Chrome 76, Safari 9 (prefixed), Firefox 103

```css
.navbar {
  background: oklch(1 0 0 / 0.7);
  backdrop-filter: blur(12px) saturate(180%);
  -webkit-backdrop-filter: blur(12px) saturate(180%);
}

.glass-card {
  background: oklch(1 0 0 / 0.15);
  backdrop-filter: blur(16px) brightness(1.1);
  border: 1px solid oklch(1 0 0 / 0.3);
}
```

---

## `mix-blend-mode` + `isolation`
**Tier**: 2+ | Chrome 41, Safari 8, Firefox 32

```css
.blend-title {
  mix-blend-mode: multiply;
  color: var(--color-primary);
}

.card {
  isolation: isolate;
}

.card-overlay {
  mix-blend-mode: overlay;
  background: oklch(0.6 0.2 30 / 0.5);
}
```

---

## `clip-path` with `path()` and `shape()`
**Tier**: `path()` Tier 2+ | `shape()` Tier 1 (Chrome 132+)

```css
.avatar   { clip-path: circle(50%); }
.chevron  { clip-path: polygon(0 0, 100% 0, 85% 100%, 15% 100%); }

.blob {
  clip-path: path("M 0,100 C 20,80 80,80 100,100 L 100,0 L 0,0 Z");
}

@supports (clip-path: shape(from 0% 0%, line to 100% 0%)) {
  .card {
    clip-path: shape(
      from 0% 0%,
      line to 100% 0%,
      line to 100% calc(100% - 2rem),
      arc to 0% calc(100% - 2rem) of 2rem cw,
      close
    );
  }
}
```

---

## `border-image` Gradient Borders
**Tier**: 2+ | Chrome 56, Safari 9.1, Firefox 50

```css
.card {
  border: 2px solid transparent;
  border-image: linear-gradient(135deg, var(--color-primary), var(--color-accent)) 1;
}

/* Rounded gradient border — needs background-clip */
.rounded-gradient-border {
  background:
    linear-gradient(var(--color-bg), var(--color-bg)) padding-box,
    linear-gradient(135deg, var(--color-primary), var(--color-accent)) border-box;
  border: 2px solid transparent;
  border-radius: var(--radius-lg);
}
```
