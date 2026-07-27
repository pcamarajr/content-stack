---
description: >
  Audit an astro-builder project end to end and produce a prioritized, actionable report. Trigger
  when the user runs /astro-builder:audit, asks to "audit the site", "check for anti-patterns",
  "find what's broken", "review the project for quality issues", or before a release / after a
  large refactor / after onboarding an existing Astro repo. Covers architecture (page-views,
  config locations), i18n completeness, content schema validity, every convention-skill domain
  checklist (CSS, HTML/a11y, and technical SEO today; more as skills ship), anti-slop design review, style guide adherence, and
  build validation.
---

# /astro-builder:audit

You are auditing this Astro 7 project for quality issues across every domain the plugin enforces.

**Why this shape:** the audit is a thin orchestrator. Each convention skill owns its rules in its
`SKILL.md` and the mechanical checks for those rules in its `references/audit.md` — the rule and
its check live together, and the audit never restates them. Adding a new domain to the audit costs
one line in the Domain checklists table. The steps below that have no backing skill (architecture,
i18n, schema, style guide, build) are the audit's own.

## Step 1 — Load project context

Read:
1. `CLAUDE.md` — project rules and quality gates.
2. `.astro-builder/anti-patterns.md` — project-specific anti-patterns.
3. `.astro-builder/content-schema.md` — expected content structure.
4. `.astro-builder/style-guide.md` — writing rules.
5. `.astro-builder/design-system.md` — token namespaces and register.
6. `src/styles/global.css` — token source of truth.
7. `astro.config.ts` — i18n config, integrations, adapter.
8. `src/content.config.ts` — collection schemas.

Also read, from the plugin root:
- `docs/astro-patterns.md` — canonical Astro 7 anti-patterns.
- `docs/anti-slop.md` — the anti-slop / design-quality rule catalog (used in Step 6).
- `docs/registers.md` — the brand vs. product register model that scopes Step 6 severity.

## Step 2 — Architecture audit

Check for violations of the page-views pattern:

- **Thin pages**: Every file in `src/pages/` should be ≤5 lines — a single import and component render. Flag any page that contains markup, data fetching, or logic.
- **Page-view imports**: Every page-view in `src/page-views/` should use `Astro.currentLocale` — flag any that accept a `lang` prop instead.
- **No prop threading**: Components should never receive `lang` or `tl` as props — each resolves its own locale. Grep for `lang={` and `tl={` in component calls.
- **Config file location**: `src/content/config.ts` must not exist. Only `src/content.config.ts` is valid.
- **Astro config extension**: `astro.config.mjs` must not exist. Only `astro.config.ts` is valid.

**Astro 7 config surface** — grep `astro.config.ts` for the `experimental` *key*
(`grep -nE "^\s*experimental\s*:" astro.config.ts`), not the bare word: the scaffolded template
mentions `experimental` in a comment on purpose, and a bare-word grep reports it as a violation.
Then check the rest:

- **Removed experimental flags**: `experimental.rustCompiler`, `experimental.advancedRouting` and
  `experimental.queuedRendering` no longer exist — flag each as P1 with "delete the key" as the fix.
- **Stabilized experimental flags**: `experimental.logger`, `experimental.cache` and
  `experimental.routeRules` moved to the top level (`logger`, `cache`, `routeRules`) — P1, fix is to
  hoist them out of `experimental`.
- **Reserved routing entrypoint**: `src/fetch.ts` must not exist unless it is a deliberate
  advanced-routing entrypoint. Otherwise flag P1 — rename the file, or set
  `fetchFile: './src/router.ts'` / `fetchFile: null` in `astro.config.ts`.
- **Removed `@astrojs/db`**: no `@astrojs/db` dependency and no `astro db` script in `package.json` —
  flag P1 and point at `node:sqlite` (Node 22.5+), Drizzle, or a hosted DB (Turso / PlanetScale / Neon).
- **Markdown plugins without their processor**: `markdown.remarkPlugins`, `markdown.rehypePlugins` or
  `markdown.remarkRehype` present **without** `@astrojs/markdown-remark` installed and
  `markdown: { processor: unified() }` set is a **P1**. The options are deprecated but still
  functional in Astro 7 — they just need that package (no longer bundled) plus the `unified()`
  processor; without both, the default Sätteri processor runs and the options have no effect.
  Fix: `pnpm add @astrojs/markdown-remark`,
  `import { unified } from "@astrojs/markdown-remark"`, set `markdown: { processor: unified() }` — or
  delete the plugins if the built-in GFM, smart punctuation and heading IDs already cover them.
- **Removed `astro:transitions` exports**: `TRANSITION_*` constants,
  `isTransitionBeforePreparationEvent()`, `isTransitionBeforeSwapEvent()` and
  `createAnimationScope()` are **P1** — use the lifecycle event-name strings
  (`'astro:before-preparation'`, `'astro:before-swap'`, …).
- **Container renderer import path**: a top-level `getContainerRenderer` import from
  `@astrojs/react` / `preact` / `solid-js` / `svelte` / `vue` / `mdx` is **P1** — it moved to the
  `@astrojs/<framework>/container-renderer` subpath.
- **Node version floor**: `engines.node` in `package.json` and the Node version pinned in CI must be
  `>=22.12.0` (Astro 7's requirement) — anything lower is a **P1**.

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

## Step 5 — Domain checklists

Each convention skill ships its mechanical checks in `references/audit.md`. For every row in the
table below, read the checklist file (path relative to the plugin root) and run every check in it.

| Domain | Checklist |
|---|---|
| CSS conventions | `skills/css-conventions/references/audit.md` |
| HTML conventions | `skills/html-conventions/references/audit.md` |
| SEO conventions | `skills/seo-conventions/references/audit.md` |

Contract (defined once here, honored by every checklist):
- A grep hit is a **candidate**, not a verdict — confirm against the rule's intent and documented
  exceptions before reporting.
- Report each confirmed finding with `file:line`, the offending fragment, the check's severity,
  and its suggested fix, grouped under a per-domain subsection of the report.
- To add a new domain to the audit, add one row to this table — nothing else.

## Step 6 — Anti-slop & design-quality audit

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

## Step 7 — Style guide audit

Read `.astro-builder/style-guide.md` and check a sample of 5 content files per collection:
- Does the tone match the defined voice?
- Are sentences within the defined length guidelines (if specified)?
- Are there obvious grammar issues or inconsistencies?

This is a best-effort check — report findings but don't auto-fix style issues.

## Step 8 — Build validation

Run `pnpm build`. If it fails, include the full error output in the report. **Severity follows the
convention rule the failure maps to** — a build error that a domain checklist already owns is
reported at that rule's severity (e.g. a block element inside a `<p>` is HTML-13, a P1), not
automatically P0. A build failure that maps to no convention rule is a **P0**.
Run `tsc --noEmit`. Include any TypeScript errors as P0 issues.
Run `biome check .` if Biome is configured. Include lint errors as P1 issues.

Two Astro 7 failure modes to name explicitly when they show up:

- A build error about an **unclosed tag** or a **block element inside a `<p>`** is Astro 7
  Rust-compiler strictness — the compiler errors where Astro 6 auto-corrected. Report it under the
  html-conventions rule it belongs to (`references/audit.md`: HTML-12 for unclosed tags, HTML-13 for
  a block element inside a `<p>`), at that rule's severity, with the fix at `file:line`.
- An install or build failure with no other explanation is usually **Node < 22.12.0**. Check `node -v`
  against Astro 7's `engines.node: ">=22.12.0"` before chasing anything else.

## Step 9 — Report

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

Before presenting the report, verify:

- [ ] Every domain checklist in the Step 5 table was read and fully run.
- [ ] Every finding has `file:line`, the offending fragment, and a concrete fix.
- [ ] Every grep candidate was confirmed against its rule's intent — no raw hits reported.
- [ ] Anti-slop severities reflect the resolved register.
- [ ] Build, TypeScript, and lint results are reflected in the P0/P1 sections.

After presenting the report, ask: "Would you like me to fix all P0 and P1 issues automatically?"

If yes, fix them autonomously, then re-run `pnpm build` and `tsc --noEmit` to confirm all P0/P1 issues are resolved.

## Constraints

- Never auto-fix P2 style issues without asking.
- Never modify content body text during the audit without explicit instruction.
- Never restate a convention skill's rules here — rules live in each skill's `SKILL.md`, checks in
  its `references/audit.md`. This file only orchestrates.
- Always follow the Astro 7 documentation: https://docs.astro.build/llms-small.txt
