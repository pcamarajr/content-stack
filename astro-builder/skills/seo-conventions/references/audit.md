# SEO conventions — mechanical audit checklist

The machine-runnable checks for the `seo-conventions` skill. `SKILL.md` is the source of every
rule; this file only encodes *how to detect* violations of those rules. `/astro-builder:audit`
runs this checklist as the SEO entry in its domain-checklist step — keep the two in sync by
editing the rule in `SKILL.md` first, then its check here.

**Contract for every check below:** a grep hit is a *candidate*, not a verdict. Confirm each hit
against the rule's intent (and its documented exceptions) before reporting. Report confirmed
findings with `file:line`, the offending fragment, and the suggested fix.

Before running: identify the layout file (`src/layouts/BaseLayout.astro` or equivalent) and read
`astro.config.ts` — several checks treat the layout as the one legitimate home for SEO markup,
and three checks read the config directly. These checks audit only the site's code; search
performance data (GSC, keywords) is the `content-seo` plugin's territory and is out of scope.

---

## SEO-1 — Page-view without a `description`

- **Rule:** every page-view passes `description` (and `title`) to BaseLayout (SKILL.md §2).
- **Severity:** P1
- **Detect:** `grep -rL "description" src/page-views --include="*.astro"` lists page-views that
  never mention `description`; then open every page-view's `<BaseLayout` call and confirm both
  `title` and `description` props are present.
- **Confirm:** the prop must reach BaseLayout — a `description` variable defined but never
  passed is still a violation.
- **Fix:** pass `description` from frontmatter (content pages) or `tl()` (index/landing pages);
  add `description` to the collection schema if it's missing there.

## SEO-2 — Duplicate titles

- **Rule:** one unique title per page; the layout owns the site-name suffix (SKILL.md §2).
- **Severity:** P1
- **Detect:** collect every `title=` value passed to `<BaseLayout` across
  `src/page-views/*.astro`. Literal strings can be compared directly; for `tl()` keys compare
  the resolved values in each locale's `src/i18n/*.json`. Content pages titled from frontmatter
  are distinct by construction — check literals and `tl()` keys only. Also grep for page-views
  appending the site name themselves: `grep -rn "title={\`" src/page-views --include="*.astro"`
  and inspect for hardcoded suffixes.
- **Confirm:** two pages resolving to the same final title is a violation; the same `tl()` key
  reused across locales is fine (different resolved values).
- **Fix:** give each page a distinct title; remove any site-name suffix from page-views (the
  layout appends it).

## SEO-3 — Hand-written SEO tags outside BaseLayout

- **Rule:** the `<head>` is a deep module — no SEO markup outside the layout (SKILL.md §1, §5).
- **Severity:** P1
- **Detect:**
  `grep -rn -E "(<title|<meta|rel=\"canonical\"|property=\"og:|name=\"twitter:|application/ld\+json|hreflang)" src --include="*.astro" | grep -v "src/layouts/"`
- **Confirm:** any hit in a page, page-view, or component is a violation — there is no allowed
  exception. Hits inside the layout are the implementation, not violations.
- **Fix:** delete the hand-written tag; express the need through the BaseLayout props
  (`title`, `description`, `image`, `type`, `publishedAt`) or extend the layout's derivation if
  the contract genuinely can't express it.

## SEO-4 — `@astrojs/sitemap` missing

- **Rule:** sitemap via the official integration, never hand-rolled (SKILL.md §7).
- **Severity:** P1
- **Detect:** `grep -n "@astrojs/sitemap" astro.config.ts` — must hit both the import and the
  `integrations` array (confirm `sitemap()` is actually listed, not just imported). Also
  `grep -rn "sitemap" src/pages` — a hand-rolled sitemap endpoint is its own violation.
- **Confirm:** integration present and invoked = pass; absent, or present alongside a custom
  sitemap endpoint = violation.
- **Fix:** `pnpm add @astrojs/sitemap`, add `sitemap()` to `integrations`, delete any custom
  endpoint.

## SEO-5 — `Astro.site` not set

- **Rule:** `site` is mandatory in `astro.config.ts` — canonicals, OG urls, hreflang, the
  sitemap, and RSS all derive from it (SKILL.md §3).
- **Severity:** P0 — without it the sitemap integration and every canonical silently degrade.
- **Detect:** `grep -n "site:" astro.config.ts`
- **Confirm:** must be an absolute production URL. While here, also grep the codebase for that
  origin hardcoded as a string (`grep -rn "https://<the-domain>" src --include="*.astro"`) —
  hardcoded origins are SEO-3-adjacent violations.
- **Fix:** set `site: "https://<production-domain>"` in `defineConfig`; replace hardcoded
  origins with derivations from `Astro.site`.

## SEO-6 — robots.txt missing or silent about the sitemap

- **Rule:** `public/robots.txt` exists and references the sitemap (SKILL.md §7).
- **Severity:** P1
- **Detect:** check `public/robots.txt` exists, then `grep -n "Sitemap:" public/robots.txt`.
- **Confirm:** the `Sitemap:` line must be an absolute URL ending in `/sitemap-index.xml` and
  its origin must match the config's `site`.
- **Fix:** scaffold from `docs/init-templates/robots.txt.template` (plugin root), substituting
  the site URL.

## SEO-7 — Missing RSS endpoint per locale

- **Rule:** one feed per locale via `@astrojs/rss` at `src/pages/{locale}/rss.xml.ts`
  (SKILL.md §7).
- **Severity:** P2
- **Detect:** for every locale in the config's `i18n.locales`, check
  `src/pages/<locale>/rss.xml.ts` exists: `ls src/pages/*/rss.xml.ts`. Then
  `grep -rn "@astrojs/rss" src/pages` — feeds must use the official package, and each feed must
  filter entries to its own locale.
- **Confirm:** a site with no content collections may legitimately skip RSS — confirm with the
  user before reporting. A feed that exists but mixes locales is a violation.
- **Fix:** scaffold the missing locale's endpoint from `docs/init-templates/rss.xml.ts.template`
  (plugin root).

## SEO-8 — Missing 404 per locale

- **Rule:** every locale ships a localized 404 page (SKILL.md §7).
- **Severity:** P2
- **Detect:** for every locale in the config's `i18n.locales`, check
  `src/pages/<locale>/404.astro` exists: `ls src/pages/*/404.astro`.
- **Confirm:** the page must follow the page-views pattern and use `tl()` — a hardcoded-English
  404 in every locale folder is a partial violation (report as P2 i18n gap).
- **Fix:** scaffold from `docs/init-templates/404.astro.template` (plugin root) and add the
  `notFound.*` keys to every locale's i18n JSON.

## SEO-9 — Root redirect missing

- **Rule:** `/` redirects explicitly to the default locale (SKILL.md §7).
- **Severity:** P1
- **Detect:** `grep -n -A2 "redirects" astro.config.ts` — must map `"/"` to
  `"/<defaultLocale>"`. Also confirm `redirectToDefaultLocale: false` in `i18n.routing`
  (the redirect is explicit, not implicit).
- **Confirm:** a `src/pages/index.astro` that renders a redirect is the inferior variant of the
  same intent — flag it and point at the config-level redirect.
- **Fix:** add `redirects: { "/": "/<defaultLocale>" }` to `defineConfig`.

## SEO-10 — hreflang validation

- **Rule:** alternates (including `x-default`) derive from the i18n config and the current
  route — zero props (SKILL.md §6).
- **Severity:** P1
- **Detect:** no reliable source grep — validate the *built output*. Run `pnpm build`, pick one
  page per locale plus the home pages, and inspect `dist/`:
  `grep -o '<link rel="alternate" hreflang="[^"]*" href="[^"]*"' dist/<locale>/<page>/index.html`
  For each sampled page check: (a) one alternate per configured locale, (b) one `x-default`
  pointing at the default locale, (c) every `href` is absolute on the config's `site` origin,
  (d) reciprocity — each alternate's target page lists the same group back.
- **Confirm:** a missing alternate on one locale of a translated pair is the classic drift this
  rule exists to catch. Pages legitimately untranslated still list all locale alternates under
  this architecture (routes exist per locale) — only report targets that 404 in `dist/`.
- **Fix:** alternates are derived in BaseLayout — if any sampled page is wrong, the bug is in
  the layout derivation (or the page bypassed the layout), never in per-page data.
