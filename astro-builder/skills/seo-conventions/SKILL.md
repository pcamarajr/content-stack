---
description: >
  Use this skill whenever touching anything search engines or social cards consume in an
  astro-builder project — creating or editing a page-view (every one passes title + description),
  editing the `<head>` in `BaseLayout.astro`, adding or reviewing any `<title>`, `<meta>`,
  `<link rel="canonical">`, OG/Twitter tag, JSON-LD block, or hreflang alternate, configuring
  `site`, integrations, or redirects in `astro.config.ts`, adding a sitemap, robots.txt, RSS
  feed, or 404 page, or choosing a social-share image. Trigger BEFORE writing any meta tag by
  hand — in this stack the `<head>` is a deep module in BaseLayout and hand-written SEO tags
  outside it are a violation. Technical/structural SEO only: for GSC data, keyword research, or
  content briefs, use the content-seo plugin instead.
---

# SEO Conventions — astro-builder

The single source of truth for how technical SEO is built in an astro-builder project. Fires
every time a page-view, layout `<head>`, config integration, or SEO artifact (sitemap, robots,
RSS, 404, redirect) is written, reviewed, or refactored.

**Why these rules exist:** technical SEO is not a marketing task — it is a code shape. Canonical
URLs, OG tags, JSON-LD, and hreflang alternates are all *derivable* from facts the framework
already knows (`Astro.site`, `Astro.url.pathname`, `Astro.currentLocale`, the i18n config, the
page's own title/description). Anything derivable that is instead written by hand will drift:
one page forgets the canonical, another duplicates the title, a third hardcodes the wrong locale
in its OG tags. So the `<head>` is a **deep module** (APoSD): page-views pass five small props —
`title`, `description`, `image?`, `type?`, `publishedAt?` — and `BaseLayout.astro` derives
everything else. The interface stays narrow; the functionality behind it is the entire SEO
surface of the site. The mechanical checks for these rules live in `references/audit.md` — the
audit runs them; this file is where the rules are defined.

**Boundary with content-seo:** this skill owns SEO that lives in the *site's code* — canonical,
OG/Twitter, JSON-LD, sitemap, robots, hreflang, meta tags, RSS, 404s, redirects. The sibling
`content-seo` plugin owns SEO driven by *external data* — Google Search Console performance,
keyword research, ranking opportunities, and content briefs. Never pull GSC data, keyword
volumes, or SERP analysis into this skill's scope; never hand-write meta tags from that plugin's
side either. The handoff is clean: content-seo decides *what to say*, this skill guarantees the
markup that says it is structurally correct.

---

## 1 — The `<head>` is a deep module

All SEO markup lives in `BaseLayout.astro` and is derived from this exact props contract:

```ts
interface Props {
  title: string;
  description: string;
  image?: string;            // social-share image, root-relative or absolute
  type?: "website" | "article"; // default "website"
  publishedAt?: Date;        // required when type is "article"
}
```

Everything else — full title format, canonical URL, OG and Twitter tags, JSON-LD, hreflang
alternates, the RSS and sitemap `<link>`s — is computed inside the layout from `Astro.site`,
`Astro.url`, `Astro.currentLocale`, and the i18n config. **Hand-written SEO tags outside
BaseLayout are forbidden**: no `<meta name="description">`, no `og:*`/`twitter:*`, no
`<link rel="canonical">`, no `<script type="application/ld+json">` in any page, page-view, or
component.

```astro
<!-- 🔴 Bad: page-view smuggling its own SEO tags — duplicates and drifts -->
<BaseLayout title={article.data.title} description={article.data.description}>
  <link rel="canonical" href={`https://example.com/en/articles/${article.id}`} slot="head" />
  <meta property="og:title" content={article.data.title} slot="head" />
  ...
</BaseLayout>

<!-- ✅ Good: narrow interface; the layout derives canonical, OG, JSON-LD, hreflang -->
<BaseLayout
  title={article.data.title}
  description={article.data.description}
  image={article.data.heroImage}
  type="article"
  publishedAt={article.data.date}
>
  ...
</BaseLayout>
```

If a page genuinely needs an SEO behavior the contract can't express, extend the deep module —
add the rule to BaseLayout (and to this skill) so every page gets it. Never patch one page.

The init scaffold for this head is `docs/init-templates/BaseLayout.astro.template` (plugin
root) — keep it in sync with these rules.

## 2 — Titles and descriptions

- **One unique `title` per page.** Two pages with the same title compete with each other in
  search results. The audit flags duplicates.
- **The layout owns the title format.** Page-views pass the bare page title; BaseLayout composes
  the final form (`{title} · {siteName}`). A page-view that appends the site name itself will
  produce `Pricing · Acme · Acme`.
- **Every page-view passes a `description`** — it is a required prop, not an optional nicety.
  For content pages it comes from frontmatter (`description` is a required schema field); for
  index/landing pages it routes through `tl()` like any UI string.
- **Description length: ~70–160 characters.** Shorter reads as an afterthought in the SERP;
  longer gets truncated mid-sentence. Write it as the page's one-sentence pitch (see
  `ux-writing` for voice).

| Bad | Good | Why |
|---|---|---|
| `title="Home"` on every locale's index | `title={tl("home.title")}` | unique, localized |
| `title={\`${title} · Acme\`}` in a page-view | `title={title}` — layout appends | format lives once |
| omit `description`, hope for the best | required prop, fails the audit if missing | engines write their own otherwise |

## 3 — Canonical URLs

`Astro.site` is **mandatory** in `astro.config.ts` — every absolute URL on the site derives from
it. The canonical is computed once, in BaseLayout:

```astro
---
// ✅ Good: derived — correct on every page, every locale, forever
const canonical = new URL(Astro.url.pathname, Astro.site);
---
<link rel="canonical" href={canonical.href} />
```

```astro
<!-- 🔴 Bad: hardcoded origin; breaks on domain change, staging, and every new page -->
<link rel="canonical" href={"https://example.com" + Astro.url.pathname} />
```

Never hardcode the origin anywhere — not in canonicals, OG urls, JSON-LD, or RSS links.

## 4 — Open Graph and Twitter cards

The complete set, derived in BaseLayout — never partially copied into a page:

- `og:type` (from the `type` prop), `og:url` (the canonical), `og:title`, `og:description`,
  `og:site_name`, `og:locale` (from `Astro.currentLocale`).
- `og:image` only when the page provides one — resolved against `Astro.site` (crawlers ignore
  relative image URLs).
- `article:published_time` when `type === "article"` and `publishedAt` is set.
- `twitter:card` is `summary_large_image` when an image exists, `summary` otherwise, plus
  `twitter:title` / `twitter:description` / `twitter:image`.

The only per-page decision is *which image* — and that travels through the `image` prop.

## 5 — JSON-LD: derived, never hand-written

Structured data is generated by BaseLayout from the same props — pages never embed their own
`<script type="application/ld+json">`:

- **`WebSite`** on the home page (per locale): `name`, `url` (`Astro.site`), `inLanguage`.
- **`Article`** when `type === "article"`: `headline` (the title), `description`,
  `datePublished` (from `publishedAt`), `image` (when provided), `inLanguage`,
  `mainEntityOfPage` (the canonical).

```astro
---
// ✅ Good: one derivation in BaseLayout — every article page gets valid JSON-LD
const jsonLd = type === "article" ? { "@context": "https://schema.org", "@type": "Article", ... } : ...;
---
{jsonLd && <script type="application/ld+json" set:html={JSON.stringify(jsonLd)} />}
```

A hand-written JSON-LD block in a page-view is the same violation as a hand-written meta tag —
it will not survive the next schema change. New schema types (e.g. `BreadcrumbList`,
`FAQPage`) are added by extending the derivation in BaseLayout, never inline.

## 6 — hreflang alternates: zero props

The i18n architecture is fixed (`prefixDefaultLocale: true`, `Astro.currentLocale`, one locale
prefix per route), so alternates are fully derivable — page-views contribute **nothing**:

```astro
---
// ✅ Good: locales from config, path from the current route
import { getAbsoluteLocaleUrl } from "astro:i18n";
import { i18n } from "astro:config/client";

const localePath = Astro.url.pathname.replace(
  new RegExp(`^/${Astro.currentLocale}/`),
  "/",
);
---
{i18n.locales.map((locale) => (
  <link rel="alternate" hreflang={locale} href={getAbsoluteLocaleUrl(locale, localePath)} />
))}
<link rel="alternate" hreflang="x-default" href={getAbsoluteLocaleUrl(i18n.defaultLocale, localePath)} />
```

```astro
<!-- 🔴 Bad: alternates passed as props — every page restates what the config knows -->
<BaseLayout alternates={[{ lang: "en", href: "..." }, { lang: "it", href: "..." }]}>
```

The `x-default` alternate points at the default locale. Stripping the `Astro.currentLocale`
prefix is the one legitimate pathname operation — it uses the framework's locale answer, it
never *detects* the locale from the URL.

## 7 — Site plumbing: sitemap, robots, RSS, 404, root redirect

Five artifacts every astro-builder site ships. Init scaffolds them from `docs/init-templates/`
(plugin root); the audit checks all five.

| Artifact | Rule | Scaffold |
|---|---|---|
| Sitemap | `@astrojs/sitemap` in `astro.config.ts` integrations — never hand-rolled. Emits `/sitemap-index.xml`. | config edit |
| robots.txt | `public/robots.txt`, must reference the sitemap (`Sitemap: {site}/sitemap-index.xml`). | `robots.txt.template` |
| RSS | One feed per locale via `@astrojs/rss` at `src/pages/{locale}/rss.xml.ts`, advertised with `<link rel="alternate" type="application/rss+xml">` in BaseLayout. | `rss.xml.ts.template` |
| 404 | One per locale (`src/pages/{locale}/404.astro`), localized via `tl()`, page-views pattern. | `404.astro.template` |
| Root redirect | `redirects: { "/": "/{defaultLocale}" }` in `astro.config.ts` — explicit, with `redirectToDefaultLocale: false`. | config edit |

```ts
// ✅ Good: astro.config.ts — site is set, sitemap is official, redirect is explicit
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: "https://example.com",
  integrations: [sitemap()],
  i18n: { defaultLocale: "en", locales: ["en", "it"],
    routing: { prefixDefaultLocale: true, redirectToDefaultLocale: false } },
  redirects: { "/": "/en" },
});
```

```ts
// 🔴 Bad: no site (canonicals and sitemap can't resolve), custom sitemap endpoint,
// implicit root behavior left to the host
export default defineConfig({
  integrations: [],
});
```

---

## Verify before finishing

After touching any page-view, the layout `<head>`, or `astro.config.ts`, confirm:

- [ ] Every page-view passes `title` and `description` to BaseLayout — and articles also pass
      `type="article"`, `publishedAt`, and `image` when one exists.
- [ ] No `<meta>`, `<title>`, `<link rel="canonical">`, `og:*`/`twitter:*`, or JSON-LD block
      exists outside `BaseLayout.astro`.
- [ ] Titles are unique across pages; the site-name suffix is appended only by the layout.
- [ ] Descriptions are ~70–160 characters and read as the page's one-sentence pitch.
- [ ] `Astro.site` is set in `astro.config.ts`; no hardcoded origin anywhere.
- [ ] `@astrojs/sitemap` is in the integrations; `public/robots.txt` references
      `/sitemap-index.xml`.
- [ ] Every configured locale has an RSS endpoint and a 404 page; `/` redirects to the default
      locale explicitly.
- [ ] hreflang alternates (including `x-default`) derive from the i18n config — no alternate
      data passed as props.
- [ ] Nothing here consumed GSC data, keyword research, or briefs — that work belongs to the
      `content-seo` plugin.

---

## Constraints

- This skill owns **technical/structural SEO only**. Search-performance data, keyword research,
  and content briefs belong to the `content-seo` plugin — never duplicate its territory here.
- `BaseLayout.astro` owns the entire SEO `<head>`; the page-view contract is exactly
  `title`, `description`, `image?`, `type?`, `publishedAt?`. New SEO behavior extends the
  layout's derivation, never a single page.
- Only official Astro integrations: `@astrojs/sitemap` and `@astrojs/rss` — never hand-rolled
  sitemaps or feed XML.
- The mechanical checks for this skill live in `references/audit.md`, run by
  `/astro-builder:audit`. When a rule here changes, update its check there.
- Always follow the Astro 6 documentation: https://docs.astro.build/llms-small.txt
