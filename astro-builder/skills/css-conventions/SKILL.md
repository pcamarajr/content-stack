---
description: >
  Use this skill whenever writing, reviewing, or refactoring CSS in this astro-builder project —
  in Astro scoped `<style>` blocks, in `src/styles/global.css`, in component style attributes, or
  anywhere a color, size, spacing value, animation, or layout decision is being made. Also trigger
  before adding interactivity to any component: walk the CSS → vanilla `<script>` → Astro island
  ladder before reaching for `client:*`. This skill enforces six disciplines (tokens, scoping, file
  location, selectors, naming, anti-Tailwind) plus a Tier-1 modern-CSS feature checklist. Never
  reach for legacy patterns (px-based media queries, CSS-in-JS, utility frameworks, preprocessors)
  when native modern CSS can express the same thing.
---

# CSS Conventions — astro-builder

The single source of truth for how CSS is authored in an astro-builder project. Fires every time
CSS is written, reviewed, or refactored. Six disciplines, one modern-features checklist, one
interactivity ladder.

---

## Step 1 — Resolve the project's browser tier

Read in this order, stop at first match:

1. `package.json` → `browserslist` field
2. `.browserslistrc` file
3. `astro.config.ts` → `build.target` (Astro defaults to `'baseline-widely-available'` ≈ Tier 1)
4. **No config found → assume Tier 1** (astro-builder default).

Map to tier:

| Tier | Resolves to roughly | Stance |
|------|---------------------|--------|
| **Tier 1** (default) | Chrome 125+ / Safari 17.5+ / Firefox 128+ | Use everything stable. Two mandatory fallbacks (Step 4). |
| **Tier 2** | Chrome 111+ / Safari 16.4+ / Firefox 113+ | Use most modern features. Wrap `field-sizing`, `@scope`, `@starting-style`, `transition-behavior: allow-discrete`, scroll-driven animations, `:popover-open` in `@supports`. |
| **Tier 3** | Chrome 105+ / Safari 15+ / Firefox 110+ | Be selective. Wrap OKLCH, `color-mix`, `:has()`, container queries, `@layer` in `@supports`. |

When uncertain, run `npx browserslist` in the project root.

---

## Step 2 — Apply the six disciplines

Every CSS change must satisfy all six. They are not negotiable.

### 2.1 — Token discipline

All values in these six domains must come from CSS custom properties defined in
`src/styles/global.css`:

| Namespace | Domain |
|-----------|--------|
| `--color-*` | every color (background, text, border, shadow color, outline, ...) |
| `--font-*` | font family stacks |
| `--text-*` | font sizes |
| `--space-*` | spacing scale (margin, padding, gap) |
| `--radius-*` | border-radius |
| `--shadow-*` | box-shadow |

**Rules:**

- Raw hex / rgb / hsl / oklch literals in those domains: **forbidden outside `global.css`**.
- Raw pixel/rem values for font-size, spacing scale, or radius: **forbidden outside `global.css`**.
- If the value you need isn't in the design system, add a token to `global.css` first, then use it.
- Document new tokens in `.astro-builder/design-system.md`.

**Allowed raw values (not design-system axes):**

- One-off layout dimensions: `width`, `height`, `max-width`, `min-height`, positional `top/left/right/bottom`, container `inline-size` thresholds. These are component-specific, not design-system axes.
- Math primitives inside `clamp()` / `min()` / `max()`: vw/vh/em/% units expressing layout fluidity.
- Z-index values (use a documented z-index scale if the project has one; otherwise raw integers).
- Animation durations and easings (consider promoting to `--motion-*` tokens if reused 3+ times).

### 2.2 — Scoping & file location

- **One global stylesheet only:** `src/styles/global.css`. No `reset.css`, `typography.css`, etc.
- **`global.css` structure:** four `@layer` declarations, in this order:
  ```css
  @layer reset, tokens, base, utilities;

  @layer reset { /* normalize / box-sizing / element resets */ }
  @layer tokens { :root { /* all --color-*, --font-*, --text-*, --space-*, --radius-*, --shadow-* */ } }
  @layer base { /* element selectors only: body, h1–h6, a, button, ::selection, focus styles, prefers-reduced-motion */ }
  @layer utilities { /* tiny, deliberate set: .sr-only, .skip-link */ }
  ```
- **No class selectors in `@layer base`.** Classes belong to scoped component CSS.
- **All component CSS lives in the component's `<style>` block.** One `.astro` file = one `<style>` block.

**Forbidden:**

- CSS Modules (`*.module.css`).
- Sibling `.css` files paired with a component.
- `<style is:global>` inside components — if it needs to be global, it belongs in `global.css`.
- Inline `style=""` with standard CSS properties.

**Single exception:** inline `style=""` may set **CSS custom properties only**, never standard
properties. This is the legitimate channel for dynamic values (scroll progress, anchor positioning
target IDs, runtime theming):

```astro
<div style={`--scroll-progress: ${progress}`}>
```

### 2.3 — Class naming

- **kebab-case:** `.card-actions`, never `.cardActions` or `.card_actions`.
- **Semantic, not visual:** `.muted`, never `.gray-text`. `.actions`, never `.flex-row-end`.
- **Brief inside scoped components.** Single words when unambiguous (`.title`, `.input`, `.actions`).
  Compound only when needed (`.form-actions`, `.nav-link`).
- **No BEM.** `__element` / `--modifier` syntax is redundant — Astro scopes for you.
- **No utility-class names.** `.mt-4`, `.text-lg`, `.flex`, `.gap-2`, etc. are forbidden.
- **Global utilities** (`@layer utilities`) stay semantic: `.sr-only`, `.skip-link`.

### 2.4 — Selectors & specificity

- **`!important` is forbidden.** Cascade fights are solved by adjusting `@layer` order in `global.css`.
- **Nesting maximum 2 levels deep** inside scoped CSS. Enough for `&:hover` / `& .child`, no deeper.
- **No ID selectors for styling** (`#foo`). IDs are reserved for anchor targets and JS hooks.
- **Universal selector `*`** only allowed in `@layer reset` (e.g. `*, *::before, *::after { box-sizing: border-box }`). Forbidden in component CSS.
- **Prefer `:is()` / `:where()`** for grouped selectors. Use `:where()` to keep specificity at zero for defaults that should be easy to override.

### 2.5 — Anti-Tailwind / framework discipline

**Forbidden — never install, never reference:**

| Category | Examples |
|---|---|
| Utility-class frameworks | Tailwind (`tailwindcss`, `@tailwind`, `tailwind.config.*`, `@apply`), UnoCSS, Tachyons, Open Props utilities, Bootstrap utilities |
| Component-class frameworks | Bulma, Pico, DaisyUI, Bootstrap |
| CSS-in-JS | styled-components, emotion, stitches, vanilla-extract |
| Preprocessors | Sass, Less, Stylus |

The native equivalents are already in CSS (`@layer`, nesting, `color-mix()`, relative color syntax,
container queries, custom properties). Preprocessors add a build step that obscures the platform.

### 2.6 — Modern CSS feature checklist

Before finalizing any CSS, run through this. Each item has a minimum tier — items at or below the
project's tier are free to use; items above require an `@supports` wrapper or a graceful fallback.

#### Color & theming
- [ ] **CSS custom properties** for repeated values — *Tier 1–3*
- [ ] **OKLCH** for color definitions — *Tier 2+*
- [ ] **`color-mix()`** for tints/shades/opacity variants — *Tier 2+*
- [ ] **Relative color syntax** (`oklch(from var(--c) l c h)`) — *Tier 1+*
- [ ] **`light-dark()`** — *Tier 1, with mandatory fallback (Step 4)*
- [ ] **`accent-color`** for native form controls — *Tier 2+*

#### Layout & sizing
- [ ] **`clamp()`** for fluid typography and spacing — *Tier 2+*
- [ ] **`min()` / `max()`** for bounded sizing — *Tier 2+*
- [ ] **Dynamic viewport units** (`svh`, `dvh`, `lvh`) instead of `100vh` — *Tier 2+*
- [ ] **Container queries** for component-level responsiveness instead of viewport media queries — *Tier 2+*
- [ ] **`subgrid`** when grid children must align across rows/columns — *Tier 2+*
- [ ] **`aspect-ratio`** instead of the padding-top hack — *Tier 2+*
- [ ] **`field-sizing: content`** for auto-resizing inputs/textareas — *Tier 1+*
- [ ] **`margin-trim`** instead of `:last-child` overrides — *Tier 1+*

#### Selectors & logic
- [ ] **`:has()`** for conditional parent/sibling styling instead of JS class toggling — *Tier 2+*
- [ ] **`:is()` / `:where()`** to reduce selector repetition — *Tier 2+*
- [ ] **`@layer`** for cascade management instead of specificity hacks — *Tier 2+*
- [ ] **`@scope`** for component-scoped styles (rarely needed — Astro scopes automatically) — *Tier 1+*
- [ ] **CSS nesting** (`&`) instead of repeated selectors — *Tier 2+*

#### Animation & transitions
- [ ] **Scroll-driven animations** for scroll-linked effects instead of IntersectionObserver + JS — *Tier 2+*
- [ ] **`@starting-style`** for enter animations on newly displayed elements — *Tier 2+*
- [ ] **`transition-behavior: allow-discrete`** to animate `display: none` toggling — *Tier 2+*
- [ ] **`view-transition-name`** for page/component transitions instead of JS animation libraries — *Tier 2+*
- [ ] **`offset-path`** to animate elements along a curve — *Tier 2+*
- [ ] **`interpolate-size: allow-keywords`** to animate `height: auto` — *Tier 0 with `@supports`*
- [ ] Always respect **`prefers-reduced-motion`** — *Tier 1–3*

#### Typography
- [ ] **`text-wrap: balance`** on headings — *Tier 2+*
- [ ] **`text-wrap: pretty`** on body paragraphs — *Tier 1+*
- [ ] **`cap` / `lh` / `rex` units** for cap-height / line-height-relative sizing — *Tier 2+*
- [ ] **`@font-face size-adjust`** to normalize font fallbacks — *Tier 2+*
- [ ] **`::marker`** to style list bullets — *Tier 2+*

#### Positioning
- [ ] **`inset` shorthand** instead of top/right/bottom/left longhand — *Tier 2+*
- [ ] **Logical properties** (`margin-inline`, `padding-block`) for i18n-ready layouts — *Tier 2+*
- [ ] **`scroll-margin` / `scroll-padding`** for sticky-header anchor offsets — *Tier 2+*
- [ ] **Anchor positioning** for tooltips / popovers / dropdowns — *Tier 1, non-critical UI only (Step 4)*

#### Visual effects
- [ ] **`backdrop-filter`** for frosted glass / blur overlays — *Tier 2+*
- [ ] **`mix-blend-mode`** + **`isolation`** for CSS compositing — *Tier 2+*
- [ ] **`clip-path`** for shape masking instead of SVG wrappers — *Tier 2+*

#### Component patterns
- [ ] **`env(safe-area-inset-*)`** for iOS notch / Dynamic Island safe areas — *Tier 2+*
- [ ] **`scrollbar-color` / `scrollbar-width`** instead of `::-webkit-scrollbar` — *Tier 2+*
- [ ] **`overscroll-behavior`** on modals/drawers — *Tier 2+*
- [ ] **`@media (hover: hover)`** to scope hover effects away from touch — *Tier 2+*
- [ ] **`@media (pointer: coarse)`** for larger touch targets — *Tier 2+*
- [ ] **`@media (prefers-contrast: more)`** for accessibility — *Tier 2+*

#### Architecture
- [ ] **`@property`** for typed custom properties that need transitions — *Tier 2+*
- [ ] **`content-visibility: auto`** on off-screen heavy sections — *Tier 2+*
- [ ] **`::backdrop`** for dialog/popover overlay styling — *Tier 2+*
- [ ] **`:popover-open`** for native popover state — *Tier 1+*

---

## Step 3 — Mandatory fallbacks (always, even at Tier 1)

Two features in the Tier-1 checklist have functional-break failure modes for users on slightly
older browsers (~12% of real-world traffic). Both require fallbacks regardless of tier.

### 3.1 — `light-dark()` always pairs with `prefers-color-scheme`

`light-dark()` returns invalid in Safari 16.x, breaking dark-mode color rendering. Never use it
bare. Either define dark colors via a media query and skip `light-dark()`, or wrap:

```css
:root {
  --color-bg: white;
  --color-text: black;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: black;
    --color-text: white;
  }
}

/* Optional progressive enhancement using light-dark() */
@supports (color: light-dark(white, black)) {
  :root {
    color-scheme: light dark;
    --color-bg: light-dark(white, black);
    --color-text: light-dark(black, white);
  }
}
```

### 3.2 — Anchor positioning only for non-critical UI

Anchor positioning is Chrome-only as of Tier 1's floor (no Safari/Firefox support yet in stable).
Use it only where a position fallback to default location is acceptable:

- ✅ Decorative tooltips that enhance but aren't required for understanding.
- ✅ Hover hints on icons.
- 🔴 Never: form validation popovers, menu dropdowns that users must reach, command palettes.

For critical UI, use `position: absolute` with manual coordinates or the Popover API's default
top-layer placement.

---

## Step 4 — Interactivity ladder

Before adding any JavaScript to a component, walk the ladder. Move to the next tier only when the
current tier truly cannot express the behavior.

### Tier 1 — CSS only

Try these first:

| Behavior | CSS pattern |
|---|---|
| Focus reveal | `:focus-within` on the form/section wrapper |
| Value reveal | `:not(:has(:placeholder-shown))`, `:valid`, `:invalid` |
| Accordion / collapsible | `<details>` / `<summary>` |
| Tabs | radio inputs + `:checked` + sibling selectors |
| Hover chrome | `@media (hover: hover)` + `:hover` / `:focus-visible` |
| Carousel (content) | `scroll-snap-type` + scroll-driven animations for pagination state |
| Mobile nav drawer | `:popover-open` + `<button popovertarget>` (with native popover), or checkbox-hack as fallback |
| Tooltips (decorative) | anchor positioning + `:hover` / `:focus-visible` |
| Entrance animations | `@starting-style` + `transition-behavior: allow-discrete` |
| Exit animations | `transition-behavior: allow-discrete` on `display` transitions |
| Sticky reveal on scroll | scroll-driven animations |

### Tier 2 — Vanilla `<script>` in the `.astro` component

Use when CSS truly can't express the behavior and side effects are bounded. **Not an island** —
just a `<script>` block in the Astro component. No framework, no hydration.

| Behavior | Pattern |
|---|---|
| Theme toggle / persistence | Read/write `localStorage`, set `data-theme` on `<html>`. Apply in a sync script in `<head>` to avoid flash. |
| Modal open/close | Native `<dialog>` + `dialog.showModal()` / `dialog.close()` |
| Copy-to-clipboard | `navigator.clipboard.writeText()` on click |
| Smooth-scroll with offset | When CSS `scroll-margin` is insufficient |
| Analytics events | Click/scroll listeners that post to an analytics endpoint |
| ARIA-correct tablist | When the radio-button tabs pattern doesn't meet accessibility requirements |
| Native popover programmatic control | `popover.showPopover()` / `.hidePopover()` |

### Tier 3 — Astro island (last resort)

Add `client:load` / `client:idle` / `client:visible` / `client:only` to a framework component
**only** when:

- Stateful UI with derived state across multiple inputs (complex form validation, multi-step wizard).
- Real-time updates from a data source (live feeds, chat, websocket-driven UI).
- Interactive data visualization where the framework's reactivity is the cleanest expression.
- A third-party widget requires the framework wrapper (rare).

For everything else, descend the ladder.

---

## Step 5 — Reference files

Load these on demand for exact syntax, browser version floors, and `@supports` patterns:

- `references/color.md` — OKLCH, `color-mix`, relative color, `light-dark`
- `references/layout.md` — `clamp`, container queries, subgrid, `field-sizing`, dvh units, math functions
- `references/selectors.md` — `:has()`, `@layer`, `@scope`, nesting
- `references/animation.md` — scroll-driven, `@starting-style`, view transitions, `offset-path`
- `references/typography.md` — `text-wrap`, `cap` unit, `font-size-adjust`, `::marker`
- `references/positioning.md` — anchor positioning, logical properties, `scroll-margin`
- `references/misc.md` — `@property`, `content-visibility`, popover, `backdrop-filter`, blend modes, `clip-path`
- `references/components.md` — `accent-color`, `env()`, media features, scrollbar, `margin-trim`, scroll-snap

Load only the file relevant to the feature you're using. Do not load all references at once.

---

## Constraints

- Always follow MDN Web API references for browser/web API usage.
- Always follow the Astro 6 documentation: https://docs.astro.build/llms-small.txt
- All token names use the six canonical namespaces. Inventing a new namespace (e.g. `--ui-*`, `--page-*`) is forbidden.
- The `.astro-builder/design-system.md` file is the human-readable index of tokens. `global.css` is the source of truth.
- When new tokens are needed, add to `global.css` first, then document in `design-system.md`.
