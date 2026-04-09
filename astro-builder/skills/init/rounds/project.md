# Round: Project Setup

Initialize an Astro 6 project for Claude Code. Deeply understand the project, then generate a `CLAUDE.md` and `.astro-builder/` folder that will guide all future development sessions.

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
Ask the user if they have a design reference (Figma, existing CSS, a brand guide URL, or a screenshot folder). If yes, read or fetch it. If no, ask:
- Primary color (hex or description)?
- Typography: display font + body font (or "system defaults")?
- Visual style: minimal, neobrutalist, editorial, clean SaaS, playful?
- Border style: rounded, sharp, none?

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

## Phase 3 — Generate artifacts

After completing the interview, generate the following files. Confirm with the user before writing: "I'm ready to generate your configuration. This will create `CLAUDE.md` and a `.astro-builder/` folder. Proceed?"

### Files to create:

**`CLAUDE.md`** — Project instructions for Claude Code. Use the template at `docs/init-templates/CLAUDE.md.template` as the base, substituting all `{{PLACEHOLDER}}` values with the user's answers.

**`.astro-builder/style-guide.md`** — Voice, tone, writing rules, and content conventions. Use `docs/init-templates/style-guide.md.template`.

**`.astro-builder/content-schema.md`** — All content types, their fields, relationships, and i18n strategy. Use `docs/init-templates/content-schema.md.template`.

**`.astro-builder/design-system.md`** — Colors, typography, spacing, component patterns. Use `docs/init-templates/design-system.md.template`.

**`.astro-builder/anti-patterns.md`** — Project-specific anti-patterns derived from the Astro 6 canonical list plus any project-specific rules the user defined.

## Phase 4 — Validate and scaffold

After writing the files:

1. Check if `package.json` exists. If not, offer to scaffold a new Astro 6 project by running:
   ```bash
   pnpm create astro@latest . -- --template minimal --no-install
   ```
2. Verify that `astro.config.ts` (not `.mjs`) exists. If not, offer to create it.
3. Verify that `src/content.config.ts` exists. If not, offer to create it based on the content schema.
4. Run `pnpm install` if dependencies need updating.
5. Run `pnpm build` and report any errors. Fix them autonomously if possible.

## Phase 5 — Completion summary

```
✅ Project setup complete

  CLAUDE.md and .astro-builder/ generated.

Created:
  • CLAUDE.md
  • .astro-builder/style-guide.md
  • .astro-builder/content-schema.md
  • .astro-builder/design-system.md
  • .astro-builder/anti-patterns.md
```

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
