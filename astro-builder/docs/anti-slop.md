# Anti-slop & design-quality catalog

The rule catalog the `/astro-builder:audit` anti-slop step (Step 4.6) runs against. Two categories:

- **slop** — tells that something was AI-generated. Distinctiveness failures.
- **quality** — general design and accessibility defects, register-independent.

Each rule lists a **detection** approach (a `grep` when mechanically detectable, otherwise *visual*
— inspect rendered output or source by eye) and **register** applicability:

- `both` — flag in either register.
- `brand-advisory` — advisory on brand surfaces, P1 on product.
- `product-only` — only meaningful in the product register.

Resolve the project's register from `.astro-builder/design-system.md` first (default `brand` for
marketing sites, `product` for app/docs). See `docs/registers.md`.

> Adapted from Impeccable's anti-pattern registry (Apache-2.0). See `NOTICE.md`.

`grep` patterns target `<style>` blocks in `.astro` files plus `src/styles/global.css`. Tune globs
per project. A grep hit is a *candidate*, not a confirmed violation — confirm against the rule intent
before reporting.

---

## Category: slop

| id | Rule | Detection | Register | Sev |
|---|---|---|---|---|
| `side-tab` | Thick colored border on one side of a card — the single most recognizable AI tell. | `grep -rnE "border-(left\|top\|right\|bottom):\s*[0-9]" src --include="*.astro"` → flag thick (≥3px) accent-colored side borders on cards. | both | P1 |
| `border-accent-on-rounded` | Thick accent border on a rounded card — border clashes with the radius. | visual + the `side-tab` grep cross-checked against `border-radius`. | both | P1 |
| `overused-font` | Inter, Roboto, Geist, Plus Jakarta Sans, Space Grotesk, Fraunces — converged, no longer distinctive. | `grep -rniE "Inter\|Roboto\|Geist\|Plus Jakarta\|Space Grotesk\|Fraunces" src/styles/global.css` (check `--font-*`). | brand-advisory | P2 |
| `single-font` | One family for the entire page — no typographic hierarchy. | Inspect `--font-*` tokens: only one real family defined. | brand-advisory | P2 |
| `flat-type-hierarchy` | Font sizes too close together — ratio <1.25 between steps. | Inspect `--text-*` scale in `global.css`. | both | P2 |
| `gradient-text` | Gradient text — decorative, a common tell on headings/metrics. | `grep -rnE "background-clip:\s*text\|-webkit-background-clip:\s*text" src --include="*.astro" --include="*.css"` | brand-advisory | P1 |
| `ai-color-palette` | Purple/violet gradients, cyan-on-dark — the loudest AI palette tells. | visual + inspect `--color-*` tokens for default purple→violet gradients. | brand-advisory | P1 |
| `cream-palette` | Warm cream/beige page background reached for by reflex as the "tasteful" default. | Inspect `--color-bg` for default warm off-white not tied to a named palette. | brand-advisory | P2 |
| `dark-glow` | Dark background + colored `box-shadow` glow — default "cool" AI look. | `grep -rnE "box-shadow:[^;]*(rgba?\([^)]*\b(0\.[3-9])\)\|0 0 [0-9]+px)" src --include="*.astro"` on dark surfaces. | brand-advisory | P2 |
| `nested-cards` | Cards inside cards — visual noise, excessive depth. | visual: a `.card`-like container holding another. Flatten with spacing/dividers. | both | P2 |
| `monotonous-spacing` | Same spacing value everywhere — no rhythm. | Inspect whether only one or two `--space-*` steps are ever used. | both | P2 |
| `bounce-easing` | Bounce/elastic easing — dated and tacky. | `grep -rnE "cubic-bezier\([^)]*-[0-9]\|elastic\|bounce" src --include="*.astro" --include="*.css"` (negative control point = overshoot). | both | P2 |
| `icon-tile-stack` | Small rounded-square icon container stacked above a heading — universal AI feature-card template. | visual. | brand-advisory | P2 |
| `italic-serif-display` | Oversized italic serif (Fraunces/Playfair/Recoleta) as the hero headline. | visual + `font-style: italic` on a serif `--font-display`. | brand-advisory | P2 |
| `hero-eyebrow-chip` | Tiny uppercase letter-spaced label / pill chip directly above an oversized hero headline. | visual. | brand-advisory | P2 |
| `repeated-section-kickers` | Tiny uppercase tracked labels repeated above every section heading — editorial scaffolding. | visual. | brand-advisory | P3 |
| `numbered-section-markers` | `01 / 02 / 03` display markers as section labels. | `grep -rnE ">0[1-9][^0-9<]" src --include="*.astro"` near headings. | brand-advisory | P3 |
| `em-dash-overuse` | More than two em-dashes in a body passage — AI cadence tell. | `grep -rno "—" src/content` then count per file (>2). | both | P2 |
| `marketing-buzzword` | streamline / empower / supercharge / world-class / enterprise-grade / next-generation / cutting-edge / seamless / leverage / unlock. | `grep -rniE "streamline\|empower\|supercharge\|world-class\|enterprise-grade\|next-generation\|cutting-edge\|seamless(ly)?\|leverage\|unlock your" src/content src --include="*.astro"` | both | P2 |
| `aphoristic-cadence` | 3+ sections landing on "X. No Y." / "Not a feature. A platform." manufactured-contrast aphorisms. | visual / read the copy. | both | P3 |
| `oversized-h1` | A full-sentence headline blown up to display size, dominating the fold. | visual. (Short punchy headlines at display size are fine.) | brand-advisory | P2 |
| `extreme-negative-tracking` | `letter-spacing` crushed past legibility. | `grep -rnE "letter-spacing:\s*-0\.0[5-9]\|letter-spacing:\s*-0\.[1-9]" src --include="*.astro" --include="*.css"` | both | P2 |

## Category: quality

| id | Rule | Detection | Register | Sev |
|---|---|---|---|---|
| `broken-image` | `<img>` with empty/missing/placeholder `src` ships as a broken box. | `grep -rnE "<img[^>]*src=(\"\"\|''\|\"#\")" src --include="*.astro"` + flag `Astro.glob` images that 404. | both | P1 |
| `gray-on-color` | Gray text on a colored background — washed out. | visual: muted text color over a non-neutral surface. Use a darker shade of the bg color. | both | P1 |
| `low-contrast` | Text below WCAG AA (4.5:1 body, 3:1 large). | Compute contrast on `--color-text`/`--color-text-muted` vs surfaces. | both | P1 |
| `layout-transition` | Animating `width`/`height`/`padding`/`margin` — layout thrash. | `grep -rnE "transition:[^;]*(width\|height\|padding\|margin)\|@keyframes" src --include="*.astro" --include="*.css"` | both | P1 |
| `line-length` | Text wider than ~80ch — eye loses its place. | Check text containers lack `max-width` near `65ch–75ch`. | both | P2 |
| `cramped-padding` | Text flush against a bordered/colored container edge (<8px padding). | visual + inspect padding on bordered/outlined/filled containers. | both | P2 |
| `body-text-viewport-edge` | Paragraphs flush against the viewport edge — no container padding. | visual on mobile widths; ensure a padded container or `max-width` + auto margins. | both | P2 |
| `tight-leading` | `line-height` below 1.3 on multi-line text. | `grep -rnE "line-height:\s*1(\.[0-2])?[^0-9]" src --include="*.astro" --include="*.css"` on body. | both | P2 |
| `skipped-heading` | Heading levels skip (h1 → h3). Breaks the screen-reader outline. | scan rendered heading order per page. | both | P1 |
| `justified-text` | `text-align: justify` without hyphenation — rivers of white. | `grep -rnE "text-align:\s*justify" src --include="*.astro" --include="*.css"` | both | P2 |
| `tiny-text` | Body text below 12px. | Inspect `--text-xs`/`--text-sm` usage on body copy. | both | P2 |
| `all-caps-body` | Long passages in `text-transform: uppercase`. | `grep -rnE "text-transform:\s*uppercase" src --include="*.astro" --include="*.css"` → flag on body, not short labels. | both | P2 |
| `wide-tracking` | `letter-spacing` above 0.05em on body text. | `grep -rnE "letter-spacing:\s*0\.(0[6-9]\|[1-9])" src --include="*.astro" --include="*.css"` on body. | both | P3 |
| `text-overflow` | Content wider than its container — spill or stray horizontal scrollbar. | visual at multiple widths. | both | P2 |
| `clipped-overflow-container` | `overflow: hidden/clip` wrapping an absolutely-positioned tooltip/menu/popover. | `grep -rnE "overflow:\s*(hidden\|clip)" src --include="*.astro"` cross-checked against positioned children. | both | P2 |

## Category: product-only

Only meaningful when the surface is in the product register.

| id | Rule | Detection | Sev |
|---|---|---|---|
| `display-fonts-ui` | Display fonts in UI labels, buttons, or data. | visual + `--font-display` applied to buttons/labels. | P1 |
| `inconsistent-components` | Same action (e.g. "save") rendered with different button shapes across screens. | visual sweep of repeated components. | P1 |
| `reinvented-affordances` | Custom scrollbars, weird form controls, non-standard modals for standard tasks. | visual. | P2 |
| `decorative-motion` | Motion that conveys no state change. | visual. | P2 |
| `missing-states` | Interactive component missing default/hover/focus/active/disabled/loading/error. | inspect component `<style>` for `:hover`/`:focus-visible`/`:disabled` etc. | P1 |
| `modal-first-thought` | Modal used where inline/progressive disclosure would serve. | visual. | P3 |

---

## How the audit uses this

1. Read the register from `design-system.md`.
2. Run every `grep`-detectable rule; collect candidate file:line hits.
3. For visual-only rules, inspect the highest-traffic templates (home, a content page, the layout)
   and any component the user flags.
4. Drop `product-only` rules on brand surfaces; downgrade `brand-advisory` rules to P3 advisories on
   brand surfaces.
5. Report under a dedicated "Anti-slop" section with file:line, the offending fragment, and the fix.

A grep hit is a candidate. Confirm intent before reporting — e.g. `letter-spacing: -0.02em` on a
display heading is fine; the rule targets crushed body tracking.
