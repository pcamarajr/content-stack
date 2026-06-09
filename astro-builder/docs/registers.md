# Design registers — brand vs. product

Every surface an astro-builder site ships falls into one of two registers. The register sets the
*defaults* for type, color, motion, and layout judgment — and which anti-slop rules are hard
failures vs. advisory. Resolve the register **before** making design decisions, and record it in
`.astro-builder/design-system.md`.

> Adapted from Impeccable (Apache-2.0) — `skill/reference/brand.md` and `product.md`. See `NOTICE.md`.

---

## Resolving the register

| Signal | Register |
|---|---|
| Landing page, marketing, campaign, portfolio, about, long-form editorial, anything where the page **is** the product | **brand** |
| App UI, dashboard, settings, data tables, docs reader, authenticated surfaces, anything where the user is **in a task** | **product** |

A single site usually has both: a `brand` marketing home and a `product` docs/app section. Tag the
register per surface, not per repo. When unsure, ask. Record the default register in
`design-system.md` and note per-section exceptions.

---

## Brand register

When design **is** the product. The visitor's impression is the deliverable.

### The brand slop test

If someone could glance at it and say "AI made that" without hesitation, it failed. The bar is
distinctiveness — a visitor should ask "how was this made?", not "which AI made this?" Average is no
longer findable; restraint **without intent** reads as mediocre, not refined.

**Name the reference before committing.** "Stripe-minimal", "Klim specimen-page", "Liquid-Death
acid-maximalism" are different lanes. Unnamed ambition collapses into beige. Don't drift into
editorial-magazine aesthetics (display-serif italic + drop caps + ruled columns) on a brief that
isn't a magazine — that's the most saturated lane of all.

### Defaults

- **Type** — two families when the voice needs it; a single deliberately-chosen family is fine. Run
  the font-selection procedure: write three physical-object voice words, reject reflex defaults
  (Inter, Fraunces, Playfair, Space Grotesk, DM Sans, Plus Jakarta, Cormorant…), browse a real
  catalog. Modular scale ≥1.25 ratio, fluid `clamp()` headings.
- **Color** — permission for committed / full / drenched palettes. A single saturated color across a
  hero is voice, not excess. Commit; don't hedge with neutrals at the edges.
- **Layout** — asymmetry, intentional grid-breaks, fluid `clamp()` spacing that breathes on large
  viewports. Image-led briefs (food, hotel, travel, fashion) **must** ship real imagery — a colored
  block where a hero photo belongs is a bug.
- **Motion** — one well-orchestrated page-load beats scattered micro-interactions. Some brands skip
  entrance motion entirely; that restraint is also voice.

### Permissions brand has that product doesn't

Ambitious first-load motion · single-purpose viewports (one idea per fold) · unexpected color
strategies · art direction that varies per section when the narrative demands it.

---

## Product register

When design **serves** the product. The tool should disappear into the task.

### The product slop test

Not "would someone say AI made this" — familiarity is a feature here. The test: would a user fluent
in the category's best tools (Linear, Figma, Notion, Raycast, Stripe) trust this interface, or pause
at every subtly-off component? The failure mode isn't flatness — it's **strangeness without
purpose**: over-decorated buttons, mismatched controls, gratuitous motion, display fonts where
labels belong, invented affordances for standard tasks.

### Defaults

- **Type** — one well-tuned family is usually right (headings, buttons, labels, body, data). **Fixed
  `rem` scale, not fluid** — a clamp-sized h1 that shrinks in a sidebar looks worse. Tighter ratio
  (1.125–1.2). Prose still caps at 65–75ch; dense tables may run wider.
- **Color** — Restrained is the floor. Accent reserved for primary action, current selection, and
  state indicators — never decoration. A second neutral layer for sidebars/toolbars. Standardize a
  state vocabulary: hover, focus, active, disabled, selected, loading, error, warning, success, info.
- **Components** — every interactive component ships **all** states (default, hover, focus, active,
  disabled, loading, error). Skeletons for loading, not center-screen spinners. Empty states that
  teach the interface. Consistent affordances across the surface.
- **Layout** — responsiveness is **structural** (collapse sidebar, responsive table, breakpoint
  columns), not fluid typography.
- **Motion** — 150–250 ms transitions. Motion conveys state, never decoration. No orchestrated
  page-load sequences; users load into a task.

### Permissions product has that brand surfaces shouldn't lean on

System/familiar sans defaults (system-ui stacks) · standard nav patterns (top bar + side nav,
breadcrumbs, tabs, command palette) · density when users need it · consistency over surprise —
delight is saved for moments, not pages.

---

## How the register changes the rules

`docs/anti-slop.md` tags each rule with how it applies per register:

- **Both** — hard failure in either register (broken images, low contrast, gray-on-color, cramped
  padding, justified body, tiny text, layout-property animation…).
- **brand-advisory** — font/color/eyebrow/serif-display rules are *advisory* on brand surfaces
  (editorial briefs may legitimately want them) but stronger tells on product UI.
- **product-only** — display fonts in UI, inconsistent component vocabulary, modal-as-first-thought,
  decorative motion — only meaningful in the product register.

When the audit runs, it reads the register from `design-system.md` and adjusts severity accordingly.
