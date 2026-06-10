# Round: Project Setup

Initialize an Astro 6 project for Claude Code. Deeply understand the project, then generate a `CLAUDE.md` and `.astro-builder/` folder that will guide all future development sessions — and scaffold the site code those files promise, so the project builds the moment init finishes.

---

## Phase 1 — Scan the repo

Before asking the user anything, silently scan the project for existing context:

1. Read `package.json` — check Astro version, installed integrations, and scripts.
2. Read `astro.config.ts` or `astro.config.mjs` if present.
3. Read `src/content.config.ts` or `src/content/config.ts` if present.
4. Look for any `README.md`, `CLAUDE.md`, `docs/`, or `.astro-builder/` folder.
5. Scan `src/styles/` for CSS variables, color tokens, or design tokens.
6. Look for `src/i18n/` or any locale JSON files.
7. Check for existing content in `src/content/` or `src/pages/`.

Summarize what you found to the user in 3-5 bullet points, then begin the interview.

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
This plugin defaults to custom CSS. Ask the user if they plan to use a different approach. Do not suggest or recommend any library — only mention that custom CSS is the default. Accept whatever the user answers and record it; do not block or warn unless they name a JS-first framework (Next UI, Chakra, etc.), in which case note that heavy JS-first libraries conflict with the Astro 6 + minimal JS constraint.

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

**`.astro-builder/anti-patterns.md`** — Project-specific anti-patterns derived from the Astro 6 canonical list plus any project-specific rules the user defined.

**`src/styles/global.css`** — Site-wide CSS. Use `docs/init-templates/global.css.template`. Defines all six token namespaces (`--color-*`, `--font-*`, `--text-*`, `--space-*`, `--radius-*`, `--shadow-*`) under `@layer tokens`, plus the four-layer cascade (`reset`, `tokens`, `base`, `utilities`). Derive `--color-primary-dark` via `color-mix(in oklch, var(--color-primary) 80%, black)`. Populate dark-mode overrides if the user opted in. This file is the source of truth for tokens — component CSS in `<style>` blocks references these.

## Phase 4 — Scaffold the site code

Everything `CLAUDE.md` promises must exist when this round finishes — the contract written is the contract created. Code that is identical for every astro-builder site ships as a literal template in `docs/init-templates/` (plugin root); only interview-dependent parts are filled in, exactly where each template's `{{...}}` markers say so. Do not improvise structure the templates already define.

### 4.1 — Ensure a base project

1. If `package.json` does not exist, scaffold a new Astro 6 project:
   ```bash
   pnpm create astro@latest . -- --template minimal --no-install
   ```
2. Ensure dependencies (add with `pnpm add` / `pnpm add -D`, never npm or yarn):
   - `@astrojs/sitemap` and `@astrojs/rss` (runtime)
   - the adapter package for the deployment target, if it needs one (`@astrojs/vercel`, `@astrojs/netlify`, `@astrojs/cloudflare`); static hosting needs none
   - `@biomejs/biome` (dev) if the user kept the Biome quality gate

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
| 2 | `astro.config.ts` | `astro.config.ts.template` | `{{SITE_URL}}`, `{{DEFAULT_LOCALE}}`, `{{LOCALES_TUPLE}}` (e.g. `"en", "it"`), adapter markers per deployment target (delete both markers for static hosting) |
| 3 | `src/lib/i18n.ts` | `lib/i18n.ts.template` | `{{SITE_NAME}}`, `{{DEFAULT_LOCALE}}` |
| 4 | `src/lib/urls.ts` | `lib/urls.ts.template` | placeholders + one builder per content type at the `{{CONTENT_TYPE_URL_BUILDERS}}` marker, following the in-file pattern |
| 5 | `src/lib/format.ts` | `lib/format.ts.template` | `{{SITE_NAME}}`, `{{DEFAULT_LOCALE}}` |
| 6 | `src/content.config.ts` | `content.config.ts.template` | `{{LOCALES_TUPLE}}` + one `defineCollection()` per content type from the interview at the `{{COLLECTIONS}}` marker (keep the contract fields: `lang`, `translationKey`, `tags`, `draft`); export all at `{{COLLECTION_EXPORTS}}` |
| 7 | `src/lib/content.ts` | `lib/content.ts.template` | one `getXByLang()` per collection at the `{{CONTENT_HELPERS}}` marker |
| 8 | `src/i18n/<locale>.json` — one per configured locale | `i18n.json.template` | default locale: verbatim; other locales: same keys, translated values. Then add the `nav.*` (and any footer) keys the BaseLayout fill below introduces — to EVERY locale file |
| 9 | `src/layouts/BaseLayout.astro` | `BaseLayout.astro.template` | `{{SITE_NAME}}`, `{{NAV_LINKS}}` (hrefs from `src/lib/urls.ts` builders, labels via `tl()`), `{{FOOTER_CONTENT}}` |
| 10 | `src/page-views/NotFoundPageView.astro` + `src/pages/<locale>/404.astro` per locale | `404.astro.template` | thin wrappers only, per the template's header comment |
| 11 | `src/pages/<locale>/rss.xml.ts` per locale | `rss.xml.ts.template` | `{{SITE_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{DEFAULT_LOCALE}}`; point the feed at the site's primary dated collection |
| 12 | `public/robots.txt` | `robots.txt.template` | `{{SITE_NAME}}`, `{{SITE_URL}}` |
| 13 | `src/content/<type>/<locale>/` folders per collection per locale, plus one example entry per collection in the default locale | — | realistic frontmatter covering every required schema field |
| 14 | `src/page-views/HomePageView.astro` + `src/pages/<locale>/index.astro` per locale | — | minimal homepage written by the model: page-views pattern, `<h1>` + short intro via `tl()` keys added to every locale file. Skip if an index page already exists |

`src/styles/global.css` was already written in Phase 3 — verify BaseLayout imports it (`import "../styles/global.css"`).

### 4.4 — Cross-check before building

1. Every `tl()` key used in any scaffolded `.astro` file exists in EVERY `src/i18n/<locale>.json`.
2. Every structure `CLAUDE.md` promises now exists: the four `src/lib/` modules, the path aliases in `tsconfig.json`, `src/content.config.ts`, the locale JSONs, BaseLayout, per-locale 404 and RSS, `public/robots.txt`.
3. No unreplaced `{{...}}` marker remains: `grep -rn "{{" src astro.config.ts tsconfig.json public` must return nothing.
4. `src/styles/global.css` contains `@layer reset, tokens, base, utilities;` plus all six token namespaces (`--color-*`, `--font-*`, `--text-*`, `--space-*`, `--radius-*`, `--shadow-*`).

### 4.5 — Install and verify

1. Run `pnpm install`.
2. Run `pnpm build` — the scaffold is not done until it passes. Fix errors autonomously and re-run.

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

- Always follow the Astro 6 documentation: https://docs.astro.build/llms-small.txt
- Always follow MDN Web API references for any browser/web API usage.
- Never use `src/content/config.ts` — always `src/content.config.ts`.
- Never use `astro.config.mjs` — always `astro.config.ts`.
- Never use ESLint or Prettier — always Biome.
- Never parse URLs to detect locale — always use `Astro.currentLocale`.
- Never use `redirectToDefaultLocale: true` — use explicit `redirects` config.
- Always use `prefixDefaultLocale: true`.
- Never thread `lang` or `tl` as props — each component resolves its own locale.
- Pages are thin wrappers only — all data fetching and markup lives in page-views.
