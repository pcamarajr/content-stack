---
description: >
  Use this skill whenever adding a route to an astro-builder project — the user asks to "add a
  page", "create an about/pricing/contact page", "add a listing page", "scaffold a route", or
  names a path like `blog/archive` or `tags/[tag]`. Trigger BEFORE creating any file under
  `src/pages/` by hand: in this stack every route is a thin wrapper (≤5 lines) around a
  page-view, created once per configured locale, with its strings registered in every locale
  JSON. Creates the page files, the page-view, and the i18n keys, then verifies the build.
  Arguments: page name or path (e.g. "about", "blog/archive", "tags/[tag]").
---

# /astro-builder:new-page $ARGUMENTS

You are scaffolding a new page in this Astro 6 project. The argument is the page name or path
(e.g. `about`, `blog/archive`, `tags/[tag]`).

**Why this workflow exists:** a page in this stack is three artifacts that must agree — one thin
route file per locale, one page-view holding all logic and markup, and one set of i18n keys
present in every locale JSON. The page-view is where the architecture's deep modules meet:
`BaseLayout` receives `title` + `description` and derives the entire SEO `<head>`
(seo-conventions), the layout owns the landmarks while the page-view supplies the single `<h1>`
(html-conventions), `tl()` resolves every visible string (ux-writing), and `src/lib/` answers
every data and URL question. A page created by hand tends to skip one of these agreements — a
locale without the route, a key missing from one JSON, an `<h1>` that never appears — and each
skipped agreement is a broken page in production. This workflow makes the agreements mechanical.

---

## Step 1 — Read project context

Before writing any code:

1. Read `CLAUDE.md` and `.astro-builder/content-schema.md` to understand the project.
2. Read `astro.config.ts` for the i18n config (locales, default locale, routing).
3. Read the default locale file in `src/i18n/` (e.g. `src/i18n/en.json`) — keys are **flat and
   dotted** (`"about.title"`), never nested objects.
4. Read one existing page in `src/pages/` and one page-view in `src/page-views/` to match the
   established pattern.
5. If the page renders collection entries, read `src/lib/content.ts` (query helpers) and
   `src/lib/urls.ts` (URL builders).

## Step 2 — Plan

From `$ARGUMENTS`, determine:

- The page slug and any dynamic segments (e.g. `[tag]`, `[...slug]`).
- Whether the page needs data from a content collection — if so, which `getXByLang()` helper
  serves it (page-views never call `getCollection()` directly; if no helper exists, the content
  type is missing — run `/astro-builder:new-content-type` first).
- Whether this is a **content page** (renders one dated entry → `type="article"` +
  `publishedAt` to BaseLayout) or an **index/landing page** (default `type="website"`).
- The i18n keys to add: at minimum `{pageName}.title` and `{pageName}.description`, plus one key
  per UI string on the page.

Announce the plan: list the files you will create and the i18n keys you will add.

## Step 3 — Create files

### 3.1 — Page files: one thin wrapper per locale

For each configured locale, create `src/pages/{locale}/{path}.astro`:

```astro
---
import AboutPageView from "@page-views/AboutPageView.astro";
---

<AboutPageView />
```

That is all — ≤5 lines, no data, no props, no logic. One file per locale; never collapse
locales into a single `getStaticPaths`-driven page.

```astro
<!-- 🔴 Bad: a "page" doing page-view work — locale logic, data, markup in the route file -->
---
import { getCollection } from "astro:content";
const lang = Astro.url.pathname.split("/")[1];      // parsing the URL for locale
const articles = await getCollection("articles");    // data fetching in a page
---
<html lang={lang}>...</html>
```

```astro
<!-- ✅ Good: the route exists, everything else lives in the page-view -->
---
import AboutPageView from "@page-views/AboutPageView.astro";
---
<AboutPageView />
```

### 3.2 — The page-view

Create `src/page-views/{PageViewName}.astro`. The page-view resolves its own locale via
`Astro.currentLocale` (never as a prop, never from the URL), passes the SEO contract to
BaseLayout, and supplies the page's single `<h1>` — the layout already owns `<html lang>`, the
skip link, `header`/`nav`/`main`/`footer`; the page-view fills `<main>` and never re-declares
landmarks (see html-conventions).

Index/landing page (strings via `tl()`):

```astro
---
import BaseLayout from "@layouts/BaseLayout.astro";
import { createTranslator } from "@lib/i18n";

const tl = createTranslator(Astro.currentLocale);
---

<BaseLayout title={tl("about.title")} description={tl("about.description")}>
  <h1>{tl("about.title")}</h1>
  <!-- page markup -->
</BaseLayout>
```

Content page (one dated entry — the SEO contract grows to `type` + `publishedAt`, and `image`
when the entry has one):

```astro
---
import BaseLayout from "@layouts/BaseLayout.astro";
const { entry } = Astro.props;
---

<BaseLayout
  title={entry.data.title}
  description={entry.data.description}
  type="article"
  publishedAt={entry.data.date}
>
  <h1>{entry.data.title}</h1>
  <!-- entry markup -->
</BaseLayout>
```

| Bad | Good | Why |
|---|---|---|
| `<meta>` / canonical / OG tags in the page-view | pass `title`, `description` (+ `type`, `publishedAt`) to BaseLayout | the `<head>` is a deep module — seo-conventions §1 |
| article page without `type="article"` | `type="article"` + `publishedAt={entry.data.date}` | drives `article:published_time` + Article JSON-LD |
| no `<h1>`, or `<h1>` in a component | exactly one `<h1>` in the page-view, inside `<main>` | the page-view owns the page title — html-conventions §1 |
| `const lang = Astro.url.pathname.split("/")[1]` | `Astro.currentLocale` | the framework already knows the locale |
| `href={\`/${locale}/articles/${slug}\`}` | builders from `@lib/urls` (`buildLocaleUrl`, `buildArticleUrl`, …) | one module knows the URL shape |
| `<p>Read more</p>` hardcoded | `tl("about.readMore")` | every visible string routes through i18n — ux-writing |

### 3.3 — i18n keys, in every locale file

Add the new keys to **every** `src/i18n/{locale}.json` — flat dotted keys, same key set in every
file (a key present in one locale and missing in another is a contract violation; `MessageKey`
is typed from the default locale, so a missing default-locale key is a TypeScript error):

```json
{
  "about.title": "About us",
  "about.description": "Who we are and why we build in the open."
}
```

The `description` value is the page's SERP pitch — ~70–160 characters (seo-conventions §2).
Write the default-locale copy first under the `ux-writing` skill, then translate the same keys
for the other locales (or run `/astro-builder:translate src/i18n/{default}.json {locale}`).

### 3.4 — Dynamic pages

For dynamic segments (e.g. `tags/[tag]`), `getStaticPaths()` lives in the page-view; the page
file stays thin by re-exporting it:

```astro
---
import TagPageView from "@page-views/TagPageView.astro";
export { getStaticPaths } from "@page-views/TagPageView.astro";
---

<TagPageView />
```

Inside the page-view, read the segment from `Astro.params` and fetch entries through the
`@lib/content` helpers. `getStaticPaths` enumerates the segment values only — the locale comes
from the folder, never from a path param.

## Step 4 — Verify

Run `pnpm build`. Fix any TypeScript or build errors before finishing.

Report what was created:

- All new files (pages + page-view).
- All i18n keys added, confirming they exist in every locale file.
- The URL(s) the page is available at, one per locale (e.g. `/en/about/`, `/it/about/`).

Before reporting, confirm:

- [ ] One page file per configured locale exists; each is ≤5 lines with no logic.
- [ ] The page-view passes `title` and `description` to BaseLayout — and `type="article"` +
      `publishedAt` (+ `image` when available) if it renders a dated content entry.
- [ ] No SEO tag (`<meta>`, canonical, OG/Twitter, JSON-LD) was written outside BaseLayout.
- [ ] The page-view renders exactly one `<h1>` and re-declares no landmark.
- [ ] Every new i18n key exists in **every** locale JSON, flat dotted format.
- [ ] All visible strings route through `tl()` — nothing hardcoded.
- [ ] Internal links use `@lib/urls` builders; collection data comes from `@lib/content` helpers.
- [ ] `pnpm build` passes.

## Constraints

- Never put data fetching, props, or logic in page files — pages are thin wrappers only.
- Never hardcode UI strings in `.astro` files — always `tl("key")` (see `ux-writing`).
- Never parse `Astro.url` to detect locale — always `Astro.currentLocale`, and never thread the
  locale (or `tl`) down as a prop.
- Always create one page file per locale — never use `getStaticPaths` to fan out locales.
- Never call `getCollection()` in a page-view — go through `src/lib/content.ts`.
- Follow the path aliases from `tsconfig.json` (`@page-views/*`, `@layouts/*`, `@lib/*`, …).
- Markup, SEO, copy, and CSS rules come from the convention skills: `html-conventions`,
  `seo-conventions`, `ux-writing`, `css-conventions`.
- Always follow the Astro 6 documentation: https://docs.astro.build/llms-small.txt
