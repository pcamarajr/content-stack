---
description: Audit the Astro 6 project for anti-patterns, missing translations, broken internal links, style guide violations, and schema inconsistencies. Produces a prioritized report with actionable fixes.
---

# /astro-builder:audit

You are auditing this Astro 6 project for quality issues. Run a thorough inspection across four categories, then produce a prioritized report.

## Step 1 — Load project context

Read:
1. `CLAUDE.md` — project rules and quality gates.
2. `.astro-builder/anti-patterns.md` — project-specific anti-patterns.
3. `.astro-builder/content-schema.md` — expected content structure.
4. `.astro-builder/style-guide.md` — writing rules.
5. `.astro-builder/design-system.md` — token namespaces.
6. `src/styles/global.css` — token source of truth.
7. `astro.config.ts` — i18n config, integrations, adapter.
8. `src/content.config.ts` — collection schemas.

Also read, from the plugin root:
- `docs/astro-patterns.md` — canonical Astro 6 anti-patterns.
- `docs/anti-slop.md` — the anti-slop / design-quality rule catalog (used in Step 4.6).
- `docs/registers.md` — the brand vs. product register model that scopes Step 4.6 severity.

## Step 2 — Architecture audit

Check for violations of the page-views pattern:

- **Thin pages**: Every file in `src/pages/` should be ≤5 lines — a single import and component render. Flag any page that contains markup, data fetching, or logic.
- **Page-view imports**: Every page-view in `src/page-views/` should use `Astro.currentLocale` — flag any that accept a `lang` prop instead.
- **No prop threading**: Components should never receive `lang` or `tl` as props — each resolves its own locale. Grep for `lang={` and `tl={` in component calls.
- **Config file location**: `src/content/config.ts` must not exist. Only `src/content.config.ts` is valid.
- **Astro config extension**: `astro.config.mjs` must not exist. Only `astro.config.ts` is valid.

## Step 3 — i18n audit

- **Missing locale pages**: For every page in `src/pages/en/`, check that a matching page exists in every other configured locale folder. List missing pages.
- **Missing translation keys**: For every key in `src/i18n/en.json`, check that the same key exists in all other locale JSON files. List missing keys with the English fallback value.
- **Missing translationKey**: For every content entry, check that `translationKey` is set. Flag entries that are missing it.
- **Unlinked translations**: For entries that have `translationKey`, verify a matching entry exists in every configured locale. List entries with no translation.
- **Hardcoded strings**: Grep `.astro` files for literal English text outside of `tl()` calls (e.g. `>About<`, `>Home<`). Flag suspected hardcoded UI strings.

## Step 4 — Content schema audit

For each content collection defined in `src/content.config.ts`:
- Check that all content files have all required frontmatter fields.
- Check that `lang` values match valid configured locales.
- Check that `date` fields are valid ISO dates.
- Check that `tags` are arrays (not strings).
- Flag any files with frontmatter errors.

## Step 4.5 — CSS conventions audit

Read `.astro-builder/design-system.md` to learn the project's token names. Then sweep the codebase for `css-conventions` skill violations. Report findings as P1 unless noted.

Run these greps (adjust shell-globbing as needed):

| Violation | Pattern | Severity |
|---|---|---|
| `!important` used | `grep -rn "!important" src --include="*.astro" --include="*.css"`. Allowed only inside `@media (prefers-reduced-motion: reduce)` blocks. | P1 |
| Tailwind / utility framework | `grep -rn -E "@tailwind\|@apply\|tailwindcss" src package.json` | P0 |
| CSS-in-JS or preprocessor | `grep -rn -E "styled-components\|@emotion\|sass\|less\|stylus" package.json` | P0 |
| CSS Modules / sibling .css | find files matching `**/*.module.css` or component-named `.css` siblings | P1 |
| `<style is:global>` in component | `grep -rn "style is:global" src --include="*.astro"` (outside `src/layouts/BaseLayout.astro` if used to import global.css) | P1 |
| Inline `style=` with standard properties | `grep -rnE "style=\"[^\"]*[a-z-]+:" src --include="*.astro"`. Only custom-property assignments (`style="--x: ..."`) are allowed. | P1 |
| Raw hex colors outside global.css | `grep -rn -E "#[0-9a-fA-F]{3,8}" src --include="*.astro"` — flag any in `<style>` blocks. | P1 |
| Raw `rgb(` / `rgba(` / `hsl(` outside global.css | `grep -rn -E "rgba?\(\|hsla?\(" src --include="*.astro"` in `<style>` blocks | P1 |
| ID selectors for styling | `grep -rn -E "^\s*#[a-z]" src --include="*.astro"` in `<style>` blocks | P2 |
| Nesting deeper than 2 levels | manual inspection of any `<style>` block flagged by the file scan | P2 |

For each violation, link to the specific file:line and quote the offending fragment in the report.

## Step 4.6 — Anti-slop & design-quality audit

Detect AI-generated design tells ("slop") and design-quality defects. Read the full rule catalog at
`docs/anti-slop.md` (relative to plugin root) — it defines ~40 rules in three categories (`slop`,
`quality`, `product-only`), each with a detection approach and per-register applicability.

1. **Resolve the register.** Read the `Register` field in `.astro-builder/design-system.md`
   (default `brand` for marketing/landing sites, `product` for app/docs surfaces). See
   `docs/registers.md`. The register changes severity:
   - Drop `product-only` rules entirely on brand surfaces.
   - Downgrade `brand-advisory` rules (overused fonts, AI palettes, gradient text, italic-serif
     hero, eyebrow chips) to **P3** advisories on brand surfaces; keep them **P1** on product
     surfaces.
   - `both` rules apply at their listed severity in either register.
2. **Run the `grep`-detectable rules** from the catalog and collect candidate file:line hits.
3. **Inspect the visual-only rules** on the highest-traffic templates (home, a representative
   content page, the shared layout) plus any component the user flags.
4. **Confirm intent before reporting.** A grep hit is a candidate, not a confirmed violation — e.g.
   `letter-spacing: -0.02em` on a display heading is fine; the rule targets crushed *body* tracking.

Report findings under a dedicated **Anti-slop** subsection of the report, each with file:line, the
offending fragment, the rule id, and the concrete fix from the catalog.

---

## Step 5 — Style guide audit

Read `.astro-builder/style-guide.md` and check a sample of 5 content files per collection:
- Does the tone match the defined voice?
- Are sentences within the defined length guidelines (if specified)?
- Are there obvious grammar issues or inconsistencies?

This is a best-effort check — report findings but don't auto-fix style issues.

## Step 6 — Build validation

Run `pnpm build`. If it fails, include the full error output in the report as a P0 issue.
Run `tsc --noEmit`. Include any TypeScript errors as P0 issues.
Run `biome check .` if Biome is configured. Include lint errors as P1 issues.

## Step 7 — Report

Produce a structured report in this format:

```
## Audit Report — {date}

### P0 — Must fix (build broken or data loss risk)
- [ ] {issue description} → {file:line} → {suggested fix}

### P1 — Should fix (correctness or i18n gaps)
- [ ] {issue description} → {file:line} → {suggested fix}

### P2 — Nice to fix (style, consistency, minor issues)
- [ ] {issue description} → {file:line} → {suggested fix}

### Summary
- Files audited: {n}
- Issues found: {P0: n, P1: n, P2: n}
- Build status: PASS / FAIL
```

After presenting the report, ask: "Would you like me to fix all P0 and P1 issues automatically?"

If yes, fix them autonomously, then re-run `pnpm build` and `tsc --noEmit` to confirm all P0/P1 issues are resolved.

## Constraints

- Never auto-fix P2 style issues without asking.
- Never modify content body text during the audit without explicit instruction.
- Always follow the Astro 6 documentation: https://docs.astro.build/llms-small.txt
