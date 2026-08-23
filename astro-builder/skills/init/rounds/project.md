# Round: Project Setup

Initialize an Astro 7 project for Claude Code. Deeply understand the project, then generate a `CLAUDE.md` and `.astro-builder/` folder that will guide all future development sessions — and scaffold the site code those files promise, so the project builds the moment init finishes.

---

## Phase 1 — Scan the repo

Before asking the user anything, silently scan the project for existing context:

1. Read `package.json` — report the detected `astro` version, installed integrations, and scripts.
   If `astro` resolves to **anything below 7**, do not scaffold on top of it silently: tell the user
   the detected version and point them at https://docs.astro.build/en/guides/upgrade-to/v7/ before
   continuing.
2. Run `node -v` and compare against Astro 7's `engines.node: ">=22.12.0"` (npm >= 9.6.5). If the
   local Node is older, stop with a clear message: Astro 7 will not install or build on this Node,
   upgrade to 22.12.0 or newer first.
3. Read `astro.config.ts` or `astro.config.mjs` if present.
4. Read `src/content.config.ts` or `src/content/config.ts` if present.
5. Look for any `README.md`, `CLAUDE.md`, `docs/`, or `.astro-builder/` folder.
6. Scan `src/styles/` for CSS variables, color tokens, or design tokens.
7. Look for `src/i18n/` or any locale JSON files.
8. Check for existing content in `src/content/` or `src/pages/`.

Then run the Astro 7 onboarding detections — each one, if it hits, is reported to the user with the
action to take:

| Detection | Action |
|---|---|
| `src/fetch.ts` exists for non-routing reasons | `src/fetch.ts` is a **reserved** advanced-routing entrypoint in Astro 7 (advanced routing is always on) and will be read as routing config — likely erroring. Rename the file (e.g. `src/fetchClient.ts`), or set `fetchFile: './src/router.ts'` / `fetchFile: null` in `astro.config.ts` |
| `@astrojs/db` in dependencies, or an `astro db` script | `@astrojs/db` is removed in Astro 7, along with `astro db` and the DB-studio commands (`astro login`, `astro logout`, `astro link`, `astro init`). Migrate to `node:sqlite` (Node 22.5+), Drizzle, or a hosted DB (Turso / PlanetScale / Neon) |
| An `experimental` block in the Astro config containing `logger`, `cache`, `routeRules`, `queuedRendering`, `rustCompiler` or `advancedRouting` | Move `logger`, `cache` and `routeRules` to the **top level** of the config (`logger` handlers: `json` / `node` / `console`; `context.logger` is always available). Delete `queuedRendering`, `rustCompiler` and `advancedRouting` — they are removed entirely |
| `markdown.remarkPlugins`, `markdown.rehypePlugins` or `markdown.remarkRehype` in the config | These keys are deprecated but **still work** in Astro 7 — they now require `@astrojs/markdown-remark` (no longer bundled) and `markdown: { processor: unified() }`; under the default Sätteri processor they have **no effect**. GFM, smart punctuation and heading IDs are built in — if the plugins add nothing beyond those, delete them. Otherwise `pnpm add @astrojs/markdown-remark`, then `import { unified } from "@astrojs/markdown-remark"` and set `markdown: { processor: unified() }` |
| `TRANSITION_*` constants, `isTransitionBeforePreparationEvent()`, `isTransitionBeforeSwapEvent()` or `createAnimationScope()` imported from `astro:transitions` | Removed in Astro 7 — use the lifecycle event-name strings directly (`'astro:before-preparation'`, `'astro:before-swap'`, …) |
| Top-level `getContainerRenderer` imports (`@astrojs/react`, preact, solid-js, svelte, vue, mdx) | Moved to a subpath: `@astrojs/react/container-renderer` |
| Custom Vite plugins in the config | Astro 7 bundles Vite 8 (Rolldown) — the plugins may need updating. See https://vite.dev/guide/migration |

Summarize what you found to the user in 3-5 bullet points (including every Astro 7 detection that
hit), then begin the interview.

## Phase 2 — Interview the user

Ask questions **one at a time** using the `AskUserQuestion` tool. Let each answer guide the next question. Do not ask more than one question per turn.

Follow this interview sequence, skipping questions where you already have the answer from Phase 1:

### 2.1 Purpose
Ask what this site is for: personal blog, product docs, education platform, news site, portfolio, etc. Ask for a one-sentence description of the site and its target audience.

### 2.2 Languages / i18n
Ask which languages the site will support. If multilingual, ask which is the default locale. Confirm the URL pattern preference (all locales prefixed, e.g. `/en/`, `/it/`).

### 2.3 Content types
Ask what types of content the site will publish. Examples: articles, tutorials, glossary entries, case studies, changelogs, documentation pages. For each type, ask:
- What fields does it have (title, date, author, tags, etc.)?
- Does it need to be translatable across locales?
- How is it related to other content types (e.g. articles reference glossary entries)?

Then ask one markdown question, so the `markdown.processor` decision is made here instead of later:
does any content need markdown behavior **beyond** what Astro 7 ships built in (GFM, smart
punctuation, heading IDs)? Examples of a "yes": footnotes via a custom remark plugin, math,
directives, a rehype pass over the HTML. A "no" (the default) keeps the native Sätteri processor and
installs nothing. A "yes" means `@astrojs/markdown-remark` is installed in Phase 4.1 and the
`markdown: { processor: unified() }` block is uncommented in `astro.config.ts`.

### 2.4 Design system

First, resolve the **register** and gather **product/brand context** — these steer every later
design decision and scope the audit's anti-slop step (see `docs/registers.md`):

- **Register** — is this surface primarily `brand` (marketing, landing, editorial — the page *is*
  the product) or `product` (app, dashboard, docs reader — the user is *in a task*)? Default `brand`
  for a marketing/content site, `product` for an app/docs site. Note per-section exceptions if the
  site has both.
- **Audience** + **primary use case** — one line each (often already captured in 2.1).
- **Brand voice** — three concrete physical-object words ("warm, mechanical, opinionated"), not
  "modern/elegant". Skip for a pure product register if the user has no brand stance.
- **Named aesthetic reference** + **anti-references** — what it should and shouldn't look like.

Then ask if they have a design reference (Figma, existing CSS, a brand guide URL, or a screenshot folder). If yes, read or fetch it. Otherwise gather the minimum set needed to populate the six token namespaces:

- **Primary color** (hex or description) — used as `--color-primary`; `--color-primary-dark` is derived via `color-mix(in oklch, primary 80%, black)`.
- **Visual style** — minimal, neobrutalist, editorial, clean SaaS, playful. Drives radius scale (`--radius-*`) and shadow scale (`--shadow-*`).
- **Display font** + **body font** (or "system defaults"). `--font-mono` always defaults to `ui-monospace, SFMono-Regular, Menlo, monospace`.
- **Dark mode**: ask if the site should respect `prefers-color-scheme: dark`. Default yes.

Derive the rest. Use OKLCH for all colors. Pick neutral defaults (`--color-bg: white`, `--color-text: #111`, etc.) unless the user provides specifics.

### 2.5 Component library
This plugin defaults to custom CSS. Ask the user if they plan to use a different approach. Do not suggest or recommend any library — only mention that custom CSS is the default. Accept whatever the user answers and record it; do not block or warn unless they name a JS-first framework (Next UI, Chakra, etc.), in which case note that heavy JS-first libraries conflict with the Astro 7 + minimal JS constraint.

### 2.6 Quality gates
Ask what quality gates they want enforced on every commit:
- `pnpm build` (zero build errors) — recommended
- `tsc --noEmit` (zero TypeScript errors) — recommended
- `biome check .` (zero lint/format errors) — recommended
- Custom scripts?

### 2.7 Deployment target
Ask where the site will be deployed: Vercel, Netlify, Cloudflare Pages, GitHub Pages, or self-hosted. This determines the Astro adapter.

## Phase 3 — Generate guidance artifacts

After completing the interview, generate the following files. Confirm with the user before writing: "I'm ready to generate your project. This will create `CLAUDE.md`, a `.astro-builder/` folder, `src/styles/global.css`, and scaffold the site code (config, layout, `src/lib/` utilities, i18n files, RSS, 404, robots.txt). Proceed?"

### Files to create:

**`CLAUDE.md`** — Project instructions for Claude Code. Use the template at `docs/init-templates/CLAUDE.md.template` as the base, substituting all `{{PLACEHOLDER}}` values with the user's answers.

**`.astro-builder/style-guide.md`** — Voice, tone, writing rules, and content conventions. Use `docs/init-templates/style-guide.md.template`.

**`.astro-builder/content-schema.md`** — All content types, their fields, relationships, and i18n strategy. Use `docs/init-templates/content-schema.md.template`.

**`.astro-builder/design-system.md`** — Token namespaces and component patterns. Use `docs/init-templates/design-system.md.template`. The human-readable index for `src/styles/global.css` — keep them in sync.

**`.astro-builder/anti-patterns.md`** — Project-specific anti-patterns derived from the Astro 7 canonical list plus any project-specific rules the user defined.

**`src/styles/global.css`** — Site-wide CSS. Use `docs/init-templates/global.css.template`. Defines all six token namespaces (`--color-*`, `--font-*`, `--text-*`, `--space-*`, `--radius-*`, `--shadow-*`) under `@layer tokens`, plus the four-layer cascade (`reset`, `tokens`, `base`, `utilities`). Derive `--color-primary-dark` via `color-mix(in oklch, var(--color-primary) 80%, black)`. Populate dark-mode overrides if the user opted in. This file is the source of truth for tokens — component CSS in `<style>` blocks references these.

## Phase 4 — Scaffold the site code

Everything `CLAUDE.md` promises must exist when this round finishes — the contract written is the contract created. Code that is identical for every astro-builder site ships as a literal template in `docs/init-templates/` (plugin root); only interview-dependent parts are filled in, exactly where each template's `{{...}}` markers say so. Do not improvise structure the templates already define.

### 4.1 — Ensure a base project

Astro 7 requires **Node >= 22.12.0** (`engines.node`) and npm >= 9.6.5. Confirm `node -v` satisfies
that before installing anything — Phase 1 already checked it, so this is just a guard for repos
scaffolded in a different shell.

1. If `package.json` does not exist, scaffold a new Astro 7 project:
   ```bash
   pnpm create astro@latest . -- --template minimal --no-install
   ```
   The resulting project must be Astro 7 — after the install in Phase 4.5, verify `astro` resolves to
   `7.x` (`pnpm list astro`). If it resolved to an older major, install Astro 7 explicitly before
   going further.
2. Ensure dependencies (add with `pnpm add` / `pnpm add -D`, never npm or yarn):
   - `@astrojs/sitemap` and `@astrojs/rss` (runtime)
   - the adapter package for the deployment target, if it needs one (`@astrojs/vercel`, `@astrojs/netlify`, `@astrojs/cloudflare`); static hosting needs none
   - `@biomejs/biome` (dev) if the user kept the Biome quality gate
   - `@astrojs/markdown-remark` (runtime) **only** if the Phase 2.3 markdown question surfaced a need
     for custom remark/rehype plugins. Astro 7's default Sätteri processor already covers GFM, smart
     punctuation and heading IDs, so the common case installs nothing here
   - never install `@astrojs/db` — it is removed in Astro 7
3. Declare the engine floor in `package.json` so the requirement is enforced by the package manager,
   not just documented:
   ```json
   "engines": { "node": ">=22.12.0" }
   ```
   If an `engines.node` range already exists and is lower than `>=22.12.0`, raise it. `/astro-builder:audit`
   flags a missing or lower floor, so this field is part of the scaffold, never an afterthought.

### 4.2 — Overwrite policy (re-runs and existing repos)

Before writing any file below, check whether the target already exists:

- **Missing** → write it.
- **Exists, identical** to what you would generate → skip silently (templates are deterministic, so re-running init over an untouched scaffold is a no-op).
- **Exists, different** → never overwrite silently. Collect all such files, then ask the user once (via `AskUserQuestion`) which to overwrite and which to keep. For `tsconfig.json`, prefer merging the path aliases into the existing file over replacing it.

### 4.3 — Scaffold every target, in this order

Config first (aliases and locales must exist before code that uses them), then the utility layer, then strings, then markup.

| # | Target | Template | Model fills |
|---|--------|----------|-------------|
| 1 | `tsconfig.json` | `tsconfig.json.template` | nothing — verbatim (or merge `paths` into an existing file) |
| 2 | `astro.config.ts` | `astro.config.ts.template` | `{{SITE_URL}}`, `{{DEFAULT_LOCALE}}`, `{{LOCALES_TUPLE}}` (e.g. `"en", "it"`), adapter markers per deployment target (delete both markers for static hosting). The template also carries the Astro 7 keys: `compressHTML` (default `'jsx'` — set `true`/`false` only to restore pre-7 behavior) and a commented `markdown.processor` block — uncomment it (and keep `@astrojs/markdown-remark` installed) only if the Phase 2.3 markdown answer was "yes" |
| 3 | `src/lib/i18n.ts` | `lib/i18n.ts.template` | `{{SITE_NAME}}`, `{{DEFAULT_LOCALE}}` |
| 4 | `src/lib/urls.ts` | `lib/urls.ts.template` | placeholders + one method per content type at the `{{CONTENT_TYPE_URL_BUILDERS}}` marker, following the in-file pattern. The file exposes the locale-bound `createUrls(locale)` factory — every content-type URL is a method on the object it returns, not a standalone `buildXUrl(slug, locale)` function (see `docs/init-templates/lib/urls.ts.template`). Delete the `/* … */` instruction block above `{{CONTENT_TYPE_URL_BUILDERS}}` once the marker is filled — it addresses the generator, not the site owner, and must not survive into `src/` |
| 5 | `src/lib/format.ts` | `lib/format.ts.template` | `{{SITE_NAME}}`, `{{DEFAULT_LOCALE}}` |
| 6 | `src/content.config.ts` | `content.config.ts.template` | `{{LOCALES_TUPLE}}` + one `defineCollection()` per content type from the interview at the `{{COLLECTIONS}}` marker (keep the contract fields: `lang`, `translationKey`, `tags`, `draft`); export all at `{{COLLECTION_EXPORTS}}` |
| 7 | `src/lib/content.ts` | `lib/content.ts.template` | one `getXByLang()` per collection at the `{{CONTENT_HELPERS}}` marker |
| 8 | `src/i18n/<locale>.json` — one per configured locale | `i18n.json.template` | default locale: verbatim; other locales: same keys, translated values. Then add the `nav.*` (and any footer) keys the BaseLayout fill below introduces — to EVERY locale file |
| 9 | `src/layouts/BaseLayout.astro` | `BaseLayout.astro.template` | `{{SITE_NAME}}`, `{{NAV_LINKS}}` (hrefs from `src/lib/urls.ts` builders, labels via `tl()`), `{{FOOTER_CONTENT}}`. Delete the `{/* … */}` instruction block above `{{NAV_LINKS}}` once the marker is filled — it addresses the generator, not the site owner, and must not survive into `src/` |
| 10 | `src/page-views/NotFoundPageView.astro` + `src/pages/<locale>/404.astro` per locale | `404.astro.template` | thin wrappers only, per the template's header comment |
| 11 | `src/pages/<locale>/rss.xml.ts` per locale | `rss.xml.ts.template` | `{{SITE_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{DEFAULT_LOCALE}}`, plus `{{FEED_COLLECTION}}` = the site's primary dated collection and `{{FEED_ENTRY_URL}}` = the `createUrls` method written for it in step 4 (e.g. `url.article`) — the two must agree, and the method must already exist in `src/lib/urls.ts`. Delete the `/* … */` instruction block above `{{FEED_ENTRY_URL}}` once the marker is filled — it addresses the generator, not the site owner, and must not survive into `src/` |
| 12 | `public/robots.txt` | `robots.txt.template` | `{{SITE_NAME}}`, `{{SITE_URL}}` |
| 13 | `src/content/<type>/<locale>/` folders per collection per locale, plus one example entry per collection in the default locale | — | realistic frontmatter covering every required schema field |
| 14 | `src/page-views/HomePageView.astro` + `src/pages/<locale>/index.astro` per locale | — | minimal homepage written by the model: page-views pattern, `<h1>` + short intro via `tl()` keys added to every locale file. Skip if an index page already exists |

`src/styles/global.css` was already written in Phase 3 — verify BaseLayout imports it (`import "@styles/global.css"`).

### 4.4 — Cross-check before building

1. Every `tl()` key used in any scaffolded `.astro` file exists in EVERY `src/i18n/<locale>.json`.
2. Every structure `CLAUDE.md` promises now exists: the four `src/lib/` modules, the path aliases in `tsconfig.json`, `src/content.config.ts`, the locale JSONs, BaseLayout, per-locale 404 and RSS, `public/robots.txt`.
3. No unreplaced `{{...}}` marker remains: `grep -rn "{{" src astro.config.ts tsconfig.json public` must return nothing.
4. `src/styles/global.css` contains `@layer reset, tokens, base, utilities;` plus all six token namespaces (`--color-*`, `--font-*`, `--text-*`, `--space-*`, `--radius-*`, `--shadow-*`).
5. No `src/fetch.ts` was created — it is Astro 7's reserved advanced-routing entrypoint and this
   scaffold never uses it.
6. `astro.config.ts` declares no `experimental` config key:
   `grep -nE "^\s*experimental\s*:" astro.config.ts` must return nothing (`logger`, `cache` and
   `routeRules` are top-level in Astro 7; `queuedRendering`, `rustCompiler` and `advancedRouting` no
   longer exist). Grep for the key, not the bare word — the template mentions `experimental` in a
   comment on purpose.
7. Every scaffolded `.astro` file has all tags closed and valid nesting — no block element inside a
   `<p>`. Astro 7's Rust compiler errors on an unclosed tag; invalid nesting it passes through
   as-is, so a passing build in 4.5 proves the first half of this check and nothing about the
   second — read the nesting.
8. `package.json` carries `"engines": { "node": ">=22.12.0" }` (Phase 4.1 step 3).
9. No template instruction block survived into `src/`: `grep -rn "DELETE THIS COMMENT" src` must
   return nothing.

### 4.5 — Install and verify

1. Run `pnpm install`.
2. Run `pnpm build` — the scaffold is not done until it passes. Fix errors autonomously and re-run.
   A build error naming an unclosed tag is Astro 7 compiler strictness, not a template bug — close
   the tag. Invalid nesting never surfaces here (the compiler ships it as authored), which is why
   4.4 step 7 asks you to read it. A build error naming a remark or rehype plugin
   means the default Sätteri processor is in use: `pnpm add @astrojs/markdown-remark`, then
   `import { unified } from "@astrojs/markdown-remark"` and set `markdown: { processor: unified() }`.

## Phase 5 — Completion summary

```
✅ Project setup complete — pnpm build passing

Guidance:
  • CLAUDE.md
  • .astro-builder/style-guide.md
  • .astro-builder/content-schema.md
  • .astro-builder/design-system.md
  • .astro-builder/anti-patterns.md

Site code:
  • astro.config.ts, tsconfig.json
  • src/styles/global.css
  • src/lib/i18n.ts, urls.ts, format.ts, content.ts
  • src/content.config.ts + src/content/<type>/<locale>/
  • src/i18n/<locale>.json (every locale)
  • src/layouts/BaseLayout.astro
  • src/page-views/ + src/pages/<locale>/ (home, 404, rss.xml)
  • public/robots.txt
```

(List only what was actually created or updated in this run.)

What's next? Run `/astro-builder:init lighthouse` to add automated Lighthouse auditing on git push.

---

## Constraints

- Always follow the Astro 7 documentation: https://docs.astro.build/llms-small.txt
- Always follow MDN Web API references for any browser/web API usage.
- Never use `src/content/config.ts` — always `src/content.config.ts`.
- Never use `astro.config.mjs` — always `astro.config.ts`.
- Never create `src/fetch.ts` — it is Astro 7's reserved advanced-routing entrypoint.
- Never install `@astrojs/db` — it is removed in Astro 7.
- Never use removed `experimental.*` flags — `logger`, `cache` and `routeRules` are top-level; `queuedRendering`, `rustCompiler` and `advancedRouting` are gone.
- Always close every tag (the Astro 7 compiler errors on an unclosed one) and keep nesting valid (it no longer corrects invalid nesting — the browser gets the markup as authored).
- Never use ESLint or Prettier — always Biome.
- Never parse URLs to detect locale — always use `Astro.currentLocale`.
- Never use `redirectToDefaultLocale: true` — use explicit `redirects` config.
- Always use `prefixDefaultLocale: true`.
- Never thread `lang` or `tl` as props — each component resolves its own locale.
- Pages are thin wrappers only — all data fetching and markup lives in page-views.
