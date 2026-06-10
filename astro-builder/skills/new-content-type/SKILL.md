---
description: >
  Use this skill whenever adding a new kind of content to an astro-builder project — the user
  asks to "add tutorials/changelogs/case studies", "create a new collection", "add a content
  type", or wants entries that live in `src/content/` with their own schema. Trigger BEFORE
  editing `src/content.config.ts` by hand: every collection in this stack follows one contract
  (lang enum, translationKey, tags, draft), one query module (`src/lib/content.ts`), and one URL
  builder (`src/lib/urls.ts`) — this skill creates all three together plus example content.
  Arguments: content type name (e.g. "tutorials", "changelogs", "case-studies").
---

# /astro-builder:new-content-type $ARGUMENTS

You are adding a new Astro 6 content collection to this project. The argument is the collection
name (e.g. `tutorials`, `changelogs`, `case-studies`).

**Why this workflow exists:** a content type is not just a schema — it is a contract spread
across four files that must stay in agreement: the collection definition
(`src/content.config.ts`), the query helpers (`src/lib/content.ts`), the URL builder
(`src/lib/urls.ts`), and the content folders themselves. The contract fields (`lang`,
`translationKey`, `tags`, `draft`) are what make the rest of the architecture free: `lang` +
`translationKey` give every entry its translations and its hreflang alternates, `draft` keeps
unpublished work out of listings and feeds, and routing all queries through `getXByLang()`
keeps the three site-wide rules — filter by locale, exclude drafts, sort newest first — in
exactly one place (information hiding: page-views ask for "this locale's tutorials" and stay
ignorant of storage and ordering). A collection defined ad hoc drops one of these fields and the
breakage shows up far away — an untranslatable entry, a draft in the RSS feed, a URL built three
different ways.

---

## Step 1 — Read project context

1. Read `CLAUDE.md` and `.astro-builder/content-schema.md` for the existing content types.
2. Read `src/content.config.ts` for the existing collection definitions and the `locales` tuple.
3. Read `src/lib/content.ts` and `src/lib/urls.ts` for the helper and builder patterns.
4. Read `astro.config.ts` for the i18n configuration (locales, default locale).
5. Look at an existing collection folder (e.g. `src/content/articles/`) for the folder layout.

## Step 2 — Interview the user

Ask questions **one at a time** using the `AskUserQuestion` tool:

1. What fields does this content type have beyond the skeleton (title, description, date,
   tags)? — author, image, difficulty, version, etc.
2. Which extra fields are required, which optional?
3. Does it reference other collections (e.g. tutorials reference glossary entries)?
4. What is the URL pattern for individual entries? (default: `/{locale}/{name}/{slug}/`)

Do **not** ask whether it should be translatable or whether it needs `tags` — every collection
gets the full contract (`lang`, `translationKey`, `tags`, `draft`). A type that is only authored
in one locale today simply has entries in one locale folder; the contract costs nothing and
keeps the door open.

## Step 3 — Define the collection

### 3.1 — Schema in `src/content.config.ts`

Add the collection with the Astro 6 `glob()` loader, following the contract every collection in
this stack shares. The `locales` tuple already at the top of the file is the single source of
truth for the `lang` enum — reuse it, never restate the locales:

```typescript
const tutorials = defineCollection({
  loader: glob({ pattern: "**/*.{md,mdx}", base: "./src/content/tutorials" }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    tags: z.array(z.string()).default([]),
    translationKey: z.string(),
    lang: z.enum(locales),
    draft: z.boolean().default(false),
    // interview-specific fields go here
  }),
});
```

Export it in the `collections` object.

| Bad | Good | Why |
|---|---|---|
| `tutorialsEn` + `tutorialsIt` collections | one collection, locale subfolders | one type = one schema; `lang` discriminates |
| `lang: z.enum(["en", "it"])` restated inline | `lang: z.enum(locales)` | the tuple mirrors `astro.config.ts` once |
| `translationKey: z.string().optional()` | `translationKey: z.string()` | optional linkage = entries that silently can't be translated |
| `category: z.enum(["guide", "news"])` | `tags: z.array(z.string()).default([])` | fixed enums need a schema change per new label |
| no `draft` field | `draft: z.boolean().default(false)` | drafts must be excludable from listings, feeds, sitemaps |

### 3.2 — Content folders and example entries

Create one folder per configured locale: `src/content/tutorials/en/`, `src/content/tutorials/it/`,
etc. Write one example `.md` entry in the default locale with every required field populated with
realistic content (the build fails on an empty collection referenced by a page, and an example
documents the frontmatter for authors).

### 3.3 — Query helpers in `src/lib/content.ts`

Add one `getXByLang()` following the module's pattern — filtering **inside** `getCollection()`
so the locale filter and draft exclusion can't be separated, sorted newest first:

```typescript
export async function getTutorialsByLang(lang: string | undefined) {
  const entries = await getCollection(
    "tutorials",
    ({ data }) => data.lang === lang && !data.draft,
  );
  return entries.toSorted(
    (a, b) => b.data.date.valueOf() - a.data.date.valueOf(),
  );
}
```

Add narrower helpers (`getTutorialBySlug()`, `getAllTutorialTags()`) **only** when a page-view
actually needs them — unused helpers are interface surface with no functionality behind it.

```typescript
// 🔴 Bad: a page-view querying the collection itself — the three rules
// (lang filter, draft exclusion, sort) get reimplemented and forgotten
const all = await getCollection("tutorials");
const visible = all.filter((t) => t.data.lang === Astro.currentLocale);

// ✅ Good: one call, all three rules applied in one place
const tutorials = await getTutorialsByLang(Astro.currentLocale);
```

### 3.4 — URL builder in `src/lib/urls.ts`

Add one builder delegating to the `buildLocaleUrl` primitive. Entry ids from `glob()` loaders
include the locale folder (`"en/my-tutorial"`) — strip it; the URL prefix carries the locale:

```typescript
export function buildTutorialUrl(slug: string, locale: string): string {
  return buildLocaleUrl(locale, "tutorials", slug.replace(`${locale}/`, ""));
}
```

```typescript
// 🔴 Bad: hand-concatenated path — no trailing slash, locale shape duplicated
export function buildTutorialUrl(slug: string, lang: string): string {
  return `/${lang}/tutorials/${slug}`;
}
```

### 3.5 — Document the type

Add the new content type — fields, relationships, URL pattern — to
`.astro-builder/content-schema.md`, which is the human-readable index of `src/content.config.ts`
(the same way `design-system.md` indexes `global.css`).

## Step 4 — Scaffold pages (optional)

Ask the user: "Do you want me to scaffold the listing page and detail page for this content
type?" If yes, run `/astro-builder:new-page` for each — the detail page-view passes
`type="article"` + `publishedAt` to BaseLayout (see `seo-conventions`). If this type becomes the
site's primary dated collection, point the per-locale `rss.xml.ts` feeds at it; otherwise no
feed work is needed.

## Step 5 — Verify

Run `pnpm build` and `tsc --noEmit`. Fix any errors before finishing.

Report:

- Updated and created files.
- Schema summary (contract fields + interview fields).
- Example entry locations, helpers, and URL builder added.

Before reporting, confirm:

- [ ] The collection lives in `src/content.config.ts` (never `src/content/config.ts`), uses the
      `glob()` loader, and is exported in `collections`.
- [ ] The schema carries the full contract: `lang: z.enum(locales)` (shared tuple), required
      `translationKey`, `tags: z.array(z.string()).default([])`, `draft` defaulting to `false`.
- [ ] One folder per configured locale exists, with at least one realistic example entry in the
      default locale.
- [ ] `src/lib/content.ts` has a `getXByLang()` filtering `lang` + `!draft` inside
      `getCollection()` and sorting newest first.
- [ ] `src/lib/urls.ts` has a builder delegating to `buildLocaleUrl`, stripping the locale
      folder from the entry id.
- [ ] `.astro-builder/content-schema.md` documents the new type.
- [ ] `pnpm build` and `tsc --noEmit` pass.

## Constraints

- Never create separate collections per language — one collection with locale subfolders;
  `lang` discriminates.
- Never use `src/content/config.ts` — always `src/content.config.ts`.
- Always use the `glob()` loader (Astro 6 pattern).
- Always use flexible `tags: string[]` — never fixed category enums.
- Always link locales via a **required** `translationKey`.
- Page-views never call `getCollection()` — all queries go through `src/lib/content.ts`; all
  internal URLs come from `src/lib/urls.ts`.
- The init scaffolds for these contracts are `docs/init-templates/content.config.ts.template`,
  `lib/content.ts.template`, and `lib/urls.ts.template` (plugin root) — keep this skill in sync
  with them.
- Always follow the Astro 6 documentation: https://docs.astro.build/llms-small.txt
