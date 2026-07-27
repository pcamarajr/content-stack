# Astro 7 Canonical Patterns and Anti-Patterns

This document is the authoritative reference for Astro 7 architectural patterns enforced by the astro-builder plugin.

**Target version**: Astro 7.1.x — requires Node >= 22.12.0 (and npm >= 9.6.5 if npm is used at all; this stack uses pnpm).

**Always verify against the live docs**: https://docs.astro.build/llms-small.txt

**Migrating from Astro 6**: https://docs.astro.build/en/guides/upgrade-to/v7/

---

## Canonical Patterns

### Project configuration

```typescript
// astro.config.ts — always TypeScript, never .mjs
import { defineConfig } from "astro/config";
import vercel from "@astrojs/vercel";
import sitemap from "@astrojs/sitemap";
// Only when custom remark/rehype plugins are needed:
// import { unified } from "@astrojs/markdown-remark";

export default defineConfig({
  site: "https://example.com",
  output: "static",
  adapter: vercel(),
  integrations: [sitemap()],
  // Astro 7 default is 'jsx' (JSX-style whitespace stripping between elements).
  // Setting it explicitly is allowed: 'jsx' | true (v6 HTML-aware collapsing) | false.
  compressHTML: "jsx",
  // markdown: { processor: unified() },  ← opt-in only; required before any
  //   remarkPlugins / rehypePlugins take effect (default processor is Sätteri).
  i18n: {
    defaultLocale: "en",
    locales: ["en", "it"],
    routing: {
      prefixDefaultLocale: true,
      redirectToDefaultLocale: false,
    },
  },
  redirects: {
    "/": "/en",
  },
});
```

Every key above is still valid in Astro 7. Three things about the surrounding config surface:

- `logger`, `cache` and `routeRules` are **top-level** keys in Astro 7 — they graduated out of `experimental` and must never be written as `experimental.logger` / `experimental.cache` / `experimental.routeRules`.
- `fetchFile` controls the reserved `src/fetch.ts` advanced-routing entrypoint: point it elsewhere (`fetchFile: './src/router.ts'`) or disable it (`fetchFile: null`). A static content site ships neither the file nor the option.
- `markdown.processor` selects the markdown pipeline. The default is Sätteri (native Rust); `@astrojs/markdown-remark` is not installed unless you add it.

### Content collections (Astro 7)

```typescript
// src/content.config.ts — at project root, NOT src/content/config.ts
import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const articles = defineCollection({
  loader: glob({ pattern: "**/*.{md,mdx}", base: "./src/content/articles" }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    tags: z.array(z.string()).default([]),
    translationKey: z.string().optional(),
    lang: z.enum(["en", "it"]).default("en"),
    draft: z.boolean().default(false),
  }),
});

export const collections = { articles };
```

`glob()` accepts an optional `deferRender` flag (added in Astro 7.1, default `false`). With the default, Markdown entries are rendered **eagerly during content sync**; `deferRender: true` defers each entry's rendering until it is actually rendered on a page. That keeps build memory bounded — the documented fix for large collections whose rendered HTML is big enough to run `astro build` out of memory — at the cost of the rendered HTML no longer being cached.

Content folder structure — single collection, locale subfolders:
```
src/content/
└── articles/
    ├── en/
    │   └── my-article.md
    └── it/
        └── my-article.md   ← same slug, different lang
```

### Page-views pattern

```
src/pages/en/about.astro          ← thin wrapper (≤5 lines)
src/page-views/AboutPageView.astro ← all markup and data
src/layouts/BaseLayout.astro      ← page shell
```

**Page file** (`src/pages/en/about.astro`):
```astro
---
import AboutPageView from "@page-views/AboutPageView.astro";
---
<AboutPageView />
```

**Page-view** (`src/page-views/AboutPageView.astro`):
```astro
---
import { createTranslator } from "@lib/i18n";
import BaseLayout from "@layouts/BaseLayout.astro";

const tl = createTranslator(Astro.currentLocale);
const locale = Astro.currentLocale ?? "en";

const { data } = await getEntry("pages", `${locale}/about`);
---
<BaseLayout title={tl("about.title")} description={tl("about.description")}>
  <!-- markup here -->
</BaseLayout>
```

### i18n

```typescript
// src/lib/i18n.ts
import en from "@i18n/en.json";
import it from "@i18n/it.json";

const translations = { en, it } as const;
type Locale = keyof typeof translations;
type TranslationKey = keyof typeof en;

export function createTranslator(locale: string | undefined) {
  const lang = (locale ?? "en") as Locale;
  const t = translations[lang] ?? translations.en;
  return (key: TranslationKey): string => t[key] ?? en[key] ?? key;
}
```

Usage in components — never passed as props:
```astro
---
// In any component or page-view
import { createTranslator } from "@lib/i18n";
const tl = createTranslator(Astro.currentLocale);
---
<h1>{tl("about.title")}</h1>
```

### Dynamic routes with content collections

```astro
---
// src/page-views/ArticlePageView.astro
import { getCollection } from "astro:content";
import { render } from "astro:content";

export async function getStaticPaths() {
  const articles = await getCollection("articles");
  return articles.map((article) => ({
    params: { slug: article.id.split("/").pop() },
    props: { article },
  }));
}

const { article } = Astro.props;
const { Content } = await render(article);
---
```

### URL builders

```ts
// src/lib/urls.ts
export function createUrls(locale: string | undefined) {
  const lang = locale ?? "en";
  const path = (...segments: string[]) => `/${[lang, ...segments].join("/")}/`;
  return {
    path,
    home: () => path(),
    rss: () => `/${lang}/rss.xml`,
    article: (id: string) => path("articles", id.replace(`${lang}/`, "")),
    tag: (tag: string) => path("tags", encodeURIComponent(tag)),
  };
}
```

A locale-bound factory, exactly like `createTranslator` — the locale is bound once per component, so no call site ever passes `lang` around:
```astro
---
import { createUrls } from "@lib/urls";
const url = createUrls(Astro.currentLocale);
---
<a href={url.article(article.id)}>{article.data.title}</a>
```

### Path aliases (tsconfig.json)

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"],
      "@layouts/*": ["./src/layouts/*"],
      "@styles/*": ["./src/styles/*"],
      "@lib/*": ["./src/lib/*"],
      "@page-views/*": ["./src/page-views/*"],
      "@i18n/*": ["./src/i18n/*"]
    }
  }
}
```

---

## Astro 7 migration notes

Upgrade guide: https://docs.astro.build/en/guides/upgrade-to/v7/

| Change | What it affects | Action |
|---|---|---|
| Rust compiler (`@astrojs/compiler-rs`) is the only `.astro` compiler; `experimental.rustCompiler` removed | Unclosed tags now throw build errors; semantically invalid HTML (block element inside `<p>`) is no longer auto-corrected and ships as authored | Close every tag, fix nesting; drop the experimental flag. Cosmetic CSS output differences (named colors as hex, `url()` quoting) are harmless |
| Markdown/MDX default processor is Sätteri (native Rust); `@astrojs/markdown-remark` is not installed by default | GFM, smart punctuation and heading IDs are built in; `markdown.remarkPlugins` / `rehypePlugins` / `remarkRehype` are deprecated but still work — they now require `@astrojs/markdown-remark` plus the `unified()` processor, and have no effect under the default Sätteri processor | Need custom plugins? `pnpm add @astrojs/markdown-remark`, then `import { unified } from "@astrojs/markdown-remark"` and set `markdown: { processor: unified() }` |
| `compressHTML` default changed from `true` to `'jsx'` | Newlines/whitespace between elements are stripped — `<span>hello</span>\n<em>world</em>` renders with no space | Add a literal space or `{' '}` between inline elements, or set `compressHTML: true` / `false` explicitly |
| Advanced routing is stable; `experimental.advancedRouting` removed | `src/fetch.ts` is a RESERVED entrypoint — a pre-existing one is read as routing config and will likely error. `state.provide()`, `state.resolve()`, `state.finalizeAll()`, `App.Providers` removed | Rename the file, or set `fetchFile: './src/router.ts'` / `fetchFile: null` |
| `experimental.logger` → top-level `logger` | Built-in handlers `json`, `node`, `console`; `context.logger` is always available in API routes and middleware; new `--json` CLI flag | Move the key to the top level |
| `experimental.cache` / `experimental.routeRules` → top-level `cache` / `routeRules` | Plus a platform-agnostic `Astro.cache` API and experimental CDN cache-provider adapters (Netlify/Vercel/Cloudflare) | Move the keys to the top level |
| `experimental.queuedRendering` removed | The stack-based queued rendering engine (~2.4x faster) is always on | Delete the flag |
| `@astrojs/db` fully removed, with the `astro db` CLI and `astro login` / `logout` / `link` / `init` | Any DB-backed feature | Migrate to `node:sqlite` (Node 22.5+), Drizzle ORM, or a hosted DB (Turso, PlanetScale, Neon) |
| `astro:transitions` removals | Constants `TRANSITION_BEFORE_PREPARATION`, `TRANSITION_AFTER_PREPARATION`, `TRANSITION_BEFORE_SWAP`, `TRANSITION_AFTER_SWAP`, `TRANSITION_PAGE_LOAD` and helpers `isTransitionBeforePreparationEvent()`, `isTransitionBeforeSwapEvent()`, `createAnimationScope()` | Use the lifecycle event-name strings directly: `'astro:before-preparation'`, `'astro:before-swap'`, … |
| Vite 8 (Rust Rolldown bundler) is required and bundled | Custom Vite plugins and integrations | Update plugin/integration deps to Vite 8-compatible versions |
| `getContainerRenderer` moved to a dedicated subpath | Container API usage in tests/integrations | `import { getContainerRenderer } from '@astrojs/react/container-renderer'` (same for preact / solid-js / svelte / vue / mdx) |
| `astro dev` auto-detects AI coding agents and runs detached | The dev server no longer blocks the agent's shell | `astro dev --background` forces it; manage with `astro dev stop` / `status` / `logs`. `--ignore-lock` (Astro 7.1) starts a server without reading or writing the dev-server lock file, so a second one can run alongside the first instead of erroring — it cannot be combined with `--background` or `--force`, and servers started with it are not tracked by `stop` / `status` / `logs` |
| Content collections | `glob()` gained `deferRender` (Astro 7.1, default `false`) — defers rendering Markdown entries until a page renders them instead of eagerly during content sync, bounding build memory but giving up the cached rendered HTML; experimental `collectionStorage: 'chunked'` splits the data store across files | Opt in only when a build actually runs out of memory |

Unchanged and still canonical: `src/content.config.ts` + Content Layer (`defineCollection`, `z`, `glob`, `reference()`, `render()`, `getCollection`, `getEntry`), `getStaticPaths`, `Astro.currentLocale` / `Astro.site` / `Astro.url` / `Astro.generator`, `astro:i18n`, `astro:config/client`, `@astrojs/sitemap`, `@astrojs/rss`, `@astrojs/mdx`, `astro:assets` `<Image />`, `astro/tsconfigs/strict`, `.astro/types.d.ts`, and the `i18n` / `redirects` / adapter config shape.

---

## Anti-Patterns

These are explicitly forbidden. Any code matching these patterns must be refactored.

| Anti-pattern | Why | Correct pattern |
|---|---|---|
| `src/content/config.ts` | Legacy pre-Content-Layer location — not used by Astro 7 | `src/content.config.ts` |
| `astro.config.mjs` | JavaScript config loses type safety | `astro.config.ts` |
| Any `experimental.rustCompiler` / `advancedRouting` / `queuedRendering` / `logger` / `cache` / `routeRules` key | Removed in Astro 7 — the features are stable or always on | Delete the flag; move `logger` / `cache` / `routeRules` to the top level |
| `@astrojs/db` or an `astro db` script | Package and CLI removed in Astro 7 | `node:sqlite`, Drizzle ORM, or a hosted DB (Turso, PlanetScale, Neon) |
| `markdown.remarkPlugins` / `rehypePlugins` without `@astrojs/markdown-remark` | The options still work in Astro 7, but only with that package installed and `processor: unified()` set — otherwise the default Sätteri processor runs and they have no effect | `pnpm add @astrojs/markdown-remark` + `markdown: { processor: unified() }` |
| Unclosed tag, or invalid nesting (`<div>` / `<ul>` / heading inside `<p>`) | Rust compiler errors on unclosed tags and no longer restructures invalid HTML — the browser gets it as authored | Close every tag; keep only phrasing content inside `<p>` |
| Newline-only whitespace between inline elements | Stripped by `compressHTML: 'jsx'` — words run together | Literal space or `{' '}` |
| A stray `src/fetch.ts` | Reserved advanced-routing entrypoint in Astro 7 | Rename the file, or set `fetchFile` (`'./src/router.ts'` or `null`) |
| `import { getContainerRenderer } from '@astrojs/react'` | Top-level import deprecated in Astro 7 | `@astrojs/react/container-renderer` subpath |
| `TRANSITION_*` constants or `createAnimationScope()` from `astro:transitions` | Removed in Astro 7 | Plain event-name strings (`'astro:before-swap'`, …) |
| Separate collections per language | Duplicates schema, breaks `reference()` | Single collection with lang subfolders |
| Fixed `category` enum | Inflexible, hard to extend | `tags: string[]` |
| Hardcoded UI strings in `.astro` | Breaks i18n, untranslatable | `tl('key')` from JSON |
| Logic/data in page files | Breaks page-views pattern | Move to page-view |
| `lang` or `tl` as props | Creates tight coupling across component tree | Each component calls `createTranslator(Astro.currentLocale)` |
| Parse `Astro.url` for locale | Fragile, breaks on URL changes | `Astro.currentLocale` |
| `prefixDefaultLocale: false` | Default locale has no prefix, links break | `prefixDefaultLocale: true` |
| `redirectToDefaultLocale: true` | Causes redirect flash in production | `redirectToDefaultLocale: false` + explicit `redirects` |
| ESLint + Prettier | Two tools for one job, config conflicts | Biome (replaces both) |
| `npm install` or `yarn add` | Inconsistent lockfile | `pnpm install` / `pnpm add` |
| Custom sitemap | Maintenance burden | `@astrojs/sitemap` |
| Custom RSS | Maintenance burden | `@astrojs/rss` |
| JS-heavy UI frameworks in page-views | Breaks SSG, inflates bundle | Astro components + vanilla JS only |
| Relative imports across `src/` | Brittle path strings | Path aliases (`@lib/`, `@components/`, etc.) |
| `// @ts-ignore` in new code | Hides real errors | Fix the type error |
| `git add .` in commits | May include unintended files | Stage specific files |

---

## Quality gate commands

```bash
pnpm build          # Zero build errors required
tsc --noEmit        # Zero TypeScript errors required
biome check .       # Zero lint/format errors required
biome check --write . # Auto-fix formatting (run before committing)
```

---

## Official integrations (use only these)

| Purpose | Package |
|---|---|
| Sitemap | `@astrojs/sitemap` |
| RSS feed | `@astrojs/rss` |
| MDX support | `@astrojs/mdx` |
| Vercel deployment | `@astrojs/vercel` |
| Netlify deployment | `@astrojs/netlify` |
| Cloudflare deployment | `@astrojs/cloudflare` |
| Custom remark/rehype markdown pipeline | `@astrojs/markdown-remark` (opt-in only; the default processor is Sätteri) |
| Image optimization | Built-in `<Image />` from `astro:assets` |

Never install community adapters when an official one exists.
