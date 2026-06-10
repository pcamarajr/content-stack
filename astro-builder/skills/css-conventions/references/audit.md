# CSS conventions — mechanical audit checklist

The machine-runnable checks for the `css-conventions` skill. `SKILL.md` is the source of every
rule; this file only encodes *how to detect* violations of those rules. `/astro-builder:audit`
runs this checklist as the CSS entry in its domain-checklist step — keep the two in sync by
editing the rule in `SKILL.md` first, then its check here.

**Contract for every check below:** a grep hit is a *candidate*, not a verdict. Confirm each hit
against the rule's intent (and its documented exceptions) before reporting. Report confirmed
findings with `file:line`, the offending fragment, and the suggested fix.

Before running: read `.astro-builder/design-system.md` to learn the project's token names, and
`src/styles/global.css` to know which values are tokens.

---

## CSS-1 — `!important`

- **Rule:** `!important` is forbidden; cascade fights are solved by `@layer` order (SKILL.md §2.4).
- **Severity:** P1
- **Detect:** `grep -rn "!important" src --include="*.astro" --include="*.css"`
- **Confirm:** allowed only inside `@media (prefers-reduced-motion: reduce)` blocks. Anything
  else is a violation.
- **Fix:** remove `!important`; adjust `@layer` order in `global.css` or lower the competing
  selector's specificity with `:where()`.

## CSS-2 — Tailwind / utility-class framework

- **Rule:** utility-class frameworks are forbidden (SKILL.md §2.5).
- **Severity:** P0
- **Detect:** `grep -rn -E "@tailwind|@apply|tailwindcss" src package.json`
- **Confirm:** any hit in source or dependencies is a violation; a mention inside a comment or
  docs file is not.
- **Fix:** remove the dependency and rewrite utility classes as semantic classes in scoped
  `<style>` blocks using tokens.

## CSS-3 — CSS-in-JS / preprocessor

- **Rule:** CSS-in-JS libraries and preprocessors are forbidden (SKILL.md §2.5).
- **Severity:** P0
- **Detect:** `grep -rn -E "styled-components|@emotion|sass|less|stylus" package.json`
- **Confirm:** check it is a real dependency, not a substring of an unrelated package name.
- **Fix:** remove the dependency; express the styles in native CSS (`@layer`, nesting,
  `color-mix()`, custom properties cover the preprocessor use cases).

## CSS-4 — CSS Modules / sibling `.css` files

- **Rule:** all component CSS lives in the component's `<style>` block; CSS Modules and sibling
  `.css` files are forbidden (SKILL.md §2.2).
- **Severity:** P1
- **Detect:** find files matching `**/*.module.css`, and `.css` files named after a component
  (e.g. `Card.css` next to `Card.astro`).
- **Confirm:** `src/styles/global.css` is the one allowed stylesheet; anything else is a
  violation.
- **Fix:** move the rules into the component's scoped `<style>` block (or into `global.css` if
  genuinely global) and delete the file.

## CSS-5 — `<style is:global>` in components

- **Rule:** if it needs to be global, it belongs in `global.css` (SKILL.md §2.2).
- **Severity:** P1
- **Detect:** `grep -rn "style is:global" src --include="*.astro"`
- **Confirm:** a hit in `src/layouts/BaseLayout.astro` used purely to import `global.css` is
  acceptable; everywhere else is a violation.
- **Fix:** move the rules into `global.css` under the appropriate `@layer`, or drop `is:global`
  and let Astro scope them.

## CSS-6 — Inline `style=` with standard properties

- **Rule:** inline styles may set CSS custom properties only, never standard properties
  (SKILL.md §2.2).
- **Severity:** P1
- **Detect:** `grep -rnE "style=\"[^\"]*[a-z-]+:" src --include="*.astro"` (also check
  `style={` expressions).
- **Confirm:** custom-property assignments (`style="--x: ..."`, including template-literal
  expressions that only set `--*` properties) are the allowed exception; any standard property
  is a violation.
- **Fix:** move the declaration into the `<style>` block; if the value is dynamic, pass it
  through a custom property and consume it in scoped CSS.

## CSS-7 — Raw hex colors outside `global.css`

- **Rule:** color literals are forbidden outside `global.css` — colors come from `--color-*`
  tokens (SKILL.md §2.1).
- **Severity:** P1
- **Detect:** `grep -rn -E "#[0-9a-fA-F]{3,8}" src --include="*.astro"`
- **Confirm:** flag hits inside `<style>` blocks. Hex fragments in markup that are not colors
  (anchors, IDs, data) are false positives.
- **Fix:** use the matching `--color-*` token; if none exists, add one to `global.css` first and
  document it in `.astro-builder/design-system.md`.

## CSS-8 — Raw `rgb()` / `hsl()` / `oklch()` outside `global.css`

- **Rule:** same token discipline as CSS-7 — functional color literals are forbidden outside
  `global.css` (SKILL.md §2.1).
- **Severity:** P1
- **Detect:** `grep -rn -E "rgba?\(|hsla?\(|oklch\(" src --include="*.astro"`
- **Confirm:** flag hits inside `<style>` blocks. `oklch(from var(--c) ...)` relative-color
  derivations of an existing token are acceptable.
- **Fix:** replace with a `--color-*` token (adding it to `global.css` if needed), or derive the
  variant with `color-mix()` / relative color syntax from an existing token.

## CSS-9 — ID selectors for styling

- **Rule:** IDs are reserved for anchor targets and JS hooks, never styling (SKILL.md §2.4).
- **Severity:** P2
- **Detect:** `grep -rn -E "^\s*#[a-z]" src --include="*.astro"`
- **Confirm:** flag hits inside `<style>` blocks; `#` occurrences in markup or scripts are false
  positives.
- **Fix:** replace the ID selector with a semantic class.

## CSS-10 — Nesting deeper than 2 levels

- **Rule:** nesting maximum 2 levels deep in scoped CSS (SKILL.md §2.4).
- **Severity:** P2
- **Detect:** no reliable grep — manually inspect the `<style>` blocks of any file already
  flagged by the other checks, plus the largest components.
- **Confirm:** `&:hover` / `& .child` is the allowed depth; a selector three levels in is a
  violation.
- **Fix:** flatten — Astro's scoping already isolates the component, so descendant chains add
  specificity without adding safety.

## CSS-11 — Utility-style class names

- **Rule:** utility-class names (`.mt-4`, `.text-lg`, `.flex`, `.gap-2`) are forbidden; classes
  are semantic and kebab-case (SKILL.md §2.3).
- **Severity:** P2
- **Detect:** `grep -rn -E "class=\"[^\"]*\b(mt|mb|mx|my|pt|pb|px|py|gap|text|font|w|h)-[0-9a-z]+\b" src --include="*.astro"`
- **Confirm:** the pattern is noisy — confirm the class encodes a visual value rather than a
  meaning (`.text-lg` is a violation; `.text-block` is not).
- **Fix:** rename to a semantic class and move the visual decision into its scoped CSS rule.

## CSS-12 — Universal selector outside the reset

- **Rule:** `*` is only allowed in `@layer reset` (SKILL.md §2.4).
- **Severity:** P2
- **Detect:** `grep -rn -E "^\s*\*[ ,{:]" src --include="*.astro"` and the same pattern in
  `global.css` outside the `@layer reset` block.
- **Confirm:** `*, *::before, *::after` box-sizing rules inside `@layer reset` are the allowed
  use; component-level universal selectors are violations.
- **Fix:** target the actual elements or a shared class instead.

## CSS-13 — Non-canonical token namespaces

- **Rule:** tokens use the six canonical namespaces (`--color-*`, `--font-*`, `--text-*`,
  `--space-*`, `--radius-*`, `--shadow-*`); inventing new namespaces is forbidden
  (SKILL.md §2.1, Constraints).
- **Severity:** P2
- **Detect:** `grep -rn -E "^\s*--[a-z]+-" src/styles/global.css` and review the prefixes found.
- **Confirm:** `--motion-*` is a sanctioned promotion for reused durations/easings; anything
  else outside the six namespaces (e.g. `--ui-*`, `--page-*`) is a violation.
- **Fix:** rename the token into the canonical namespace and update its usages.
