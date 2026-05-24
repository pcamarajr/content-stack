# Animation & Transitions — Modern CSS Reference

## Scroll-Driven Animations
**Tier**: 2+ | Chrome 115, Edge 115, Firefox 110, Safari 18 (partial)

Link animations directly to scroll position — no IntersectionObserver or scroll JS needed.

```css
/* Scroll progress bar */
@keyframes grow-bar {
  from { transform: scaleX(0); }
  to   { transform: scaleX(1); }
}

.progress-bar {
  animation: grow-bar linear;
  animation-timeline: scroll(root);
  transform-origin: left;
}

/* Fade in elements as they enter the viewport */
@keyframes fade-in {
  from { opacity: 0; translate: 0 2rem; }
  to   { opacity: 1; translate: 0 0; }
}

.section {
  animation: fade-in linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 30%;
}

/* Named timeline — share one scroll timeline across elements */
.scroll-container {
  scroll-timeline-name: --gallery;
  scroll-timeline-axis: inline;
  overflow-x: scroll;
}

.gallery-item {
  animation: slide-in linear;
  animation-timeline: --gallery;
}
```

**`@supports` guard**:
```css
@supports (animation-timeline: scroll()) {
  .progress-bar {
    animation: grow-bar linear;
    animation-timeline: scroll(root);
  }
}
```

---

## `@starting-style`
**Tier**: 2+ | Chrome 117, Edge 117, Safari 17.5, Firefox 129

Define the style an element transitions *from* when it's first displayed. Enables pure-CSS enter animations.

```css
dialog {
  transition: opacity 0.3s, transform 0.3s, display 0.3s allow-discrete, overlay 0.3s allow-discrete;
  opacity: 1;
  transform: translateY(0);
}

/* Starting state — what it transitions FROM on entry */
@starting-style {
  dialog[open] {
    opacity: 0;
    transform: translateY(-1rem);
  }
}

/* Exit transition */
dialog:not([open]) {
  opacity: 0;
  transform: translateY(-1rem);
}
```

---

## `transition-behavior: allow-discrete`
**Tier**: 2+ | Chrome 117, Safari 17.5, Firefox 129

Required to animate elements in/out of `display: none`.

```css
.drawer {
  display: none;
  opacity: 0;
  transform: translateX(-100%);
  transition:
    display    0.3s allow-discrete,
    opacity    0.3s,
    transform  0.3s,
    overlay    0.3s allow-discrete;
}

.drawer.is-open {
  display: block;
  opacity: 1;
  transform: translateX(0);
}

@starting-style {
  .drawer.is-open {
    opacity: 0;
    transform: translateX(-100%);
  }
}
```

---

## View Transitions
**Tier**: 2+ (same-document) | Chrome 111, Safari 18, Firefox 128

Animate between two states of a page or component.

```css
.hero-image {
  view-transition-name: hero;
}

::view-transition-old(hero) {
  animation: 300ms ease-out fade-out;
}

::view-transition-new(hero) {
  animation: 300ms ease-in fade-in;
}

/* Cross-document (MPA) */
@view-transition {
  navigation: auto;
}
```

JS trigger for same-document:
```js
document.startViewTransition(() => {
  updateContent();
});
```

---

## `offset-path` — Motion Path
**Tier**: 2+ | Chrome 115, Safari 15.4, Firefox 72

```css
@keyframes move-along {
  from { offset-distance: 0%; }
  to   { offset-distance: 100%; }
}

.icon {
  offset-path: path("M 10,80 C 40,10 65,10 95,80 S 150,150 180,80");
  offset-rotate: auto;
  animation: move-along 2s linear infinite;
}

.orbiter {
  offset-path: circle(40% at center);
  animation: move-along 3s linear infinite;
}
```

---

## `prefers-reduced-motion`
**Tier**: 1–3 (always include)

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

/* Or opt-in pattern */
@media (prefers-reduced-motion: no-preference) {
  .hero { animation: slide-in 0.6s ease both; }
}
```

> Note: this is the **only** allowed `!important` in astro-builder CSS — accessibility reset for reduced motion is the platform convention.
