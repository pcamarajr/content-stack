---
description: >
  Use this skill whenever localizing anything in an astro-builder project — the user asks to
  "translate this article to Italian", "localize the site to French", "add the German version of
  this page", "translate the i18n file", or names a content file plus a target locale. Trigger
  BEFORE translating any `src/content/` entry or `src/i18n/` JSON by hand: translated entries
  must keep their slug, carry the right `lang`, and link to the source via `translationKey` —
  that linkage is what makes hreflang alternates and the locale's RSS feed appear with zero
  manual work. Arguments: file path and target locale (e.g.
  "src/content/articles/en/hello-world.md it" or "src/i18n/en.json it").
---

# /astro-builder:translate $ARGUMENTS

You are localizing content in this Astro 6 project. The argument format is
`{file-path} {target-locale}` (e.g. `src/content/articles/en/hello-world.md it`).

**Why this workflow exists:** in this architecture, translation is a *content* operation, never
a *plumbing* operation. Because every collection carries `lang` + `translationKey`, every route
is locale-prefixed, and BaseLayout derives hreflang alternates while `rss.xml.ts` feeds each
locale — a correctly placed translated file gets its URL, its hreflang alternates, and its RSS
entry automatically. No `<link>` to add, no feed to touch, no route to register. The entire
job is therefore *quality of localization* plus *three frontmatter facts kept true*: same slug,
target `lang`, matching `translationKey`. Get those wrong and the architecture silently
disconnects the translation from its source; get them right and everything else is derived.
And localization means localization: a word-for-word translation reads machine-made and betrays
the voice that `.astro-builder/style-guide.md` defines — adapt, don't transliterate.

---

## Step 1 — Parse arguments and read context

Parse `$ARGUMENTS` to extract:

- `sourcePath`: the file to translate
- `targetLocale`: the target language code (e.g. `it`, `fr`, `de`)

Then read:

1. `CLAUDE.md` and `.astro-builder/style-guide.md` — voice, tone, and the project's
   translation/localization rules (the style guide has a dedicated section; follow it).
2. `astro.config.ts` — confirm the target locale is configured.
3. The source file at `sourcePath`.
4. Existing translations in the target locale folder — match their established style and
   terminology.
5. `src/i18n/{targetLocale}.json` — the already-translated UI strings are the project's de facto
   glossary for recurring terms (reference only).

## Step 2 — Validate

- The target locale exists in `astro.config.ts` `i18n.locales`. If not, stop and tell the user —
  adding a locale is a config + i18n-file change, not a translation.
- The source file exists. If not, stop and inform the user.
- A translation does not already exist (same slug in the target locale folder). If it does, ask
  the user whether to overwrite.

## Step 3 — Translate the content

This is **localization**, not word-for-word translation:

- Match the voice and tone defined in `.astro-builder/style-guide.md` — translation must not
  flatten it.
- Adapt idioms, cultural references, and examples to feel native in the target language.
- Keep technical terms consistent: translate a term only if a widely accepted translation exists;
  otherwise keep the original. Follow any glossary in `.astro-builder/`.
- Preserve all markdown formatting: headings, emphasis, code blocks, links, lists.
- Do **not** translate code blocks — only comments inside them.
- Preserve relative links as-is (slugs never change across locales, so paths stay valid).

| Bad | Good | Why |
|---|---|---|
| literal, word-order-preserving translation | natural phrasing a native writer would choose | machine-sounding copy betrays the voice |
| translating an idiom literally | an equivalent idiom or plain restatement | idioms don't cross languages |
| translating identifiers in a code block | code untouched, comments translated | code is not prose |
| inventing new terminology per file | reuse terms from existing translations and `src/i18n/{targetLocale}.json` | one term per concept, everywhere |

Frontmatter rules:

- Translate: `title`, `description`, and any other prose fields. Keep `description` at
  ~70–160 characters — it is the page's SERP pitch (see `seo-conventions`).
- Do **not** translate: `date`, `translationKey`, tag slugs (`tags` stay identical across
  locales so tag pages aggregate correctly), or any field that is an identifier.
- Set: `lang: {targetLocale}`. Preserve `draft` exactly as the source has it.

## Step 4 — Create the translated file

The output path mirrors the source with only the locale folder changed — **the slug (filename)
never changes**:

```text
🔴 Bad:  src/content/articles/en/hello-world.md → src/content/articles/it/ciao-mondo.md
✅ Good: src/content/articles/en/hello-world.md → src/content/articles/it/hello-world.md
```

A translated slug breaks the `translationKey` symmetry readers and tooling rely on — the locale
prefix in the URL is the only thing that differs between language versions.

Frontmatter linkage:

- `lang: {targetLocale}`.
- `translationKey` identical to the source's. The schema requires it; if a legacy source file is
  missing it, generate one from the slug and add it to **both** files.

Write the translated file. That is the whole job: because the file now sits in the right locale
folder with the right `lang` and `translationKey`, the architecture derives the rest — the page
appears at `/{targetLocale}/...`, BaseLayout emits its hreflang alternates, and the locale's
`rss.xml.ts` picks it up. Adding any of those by hand is a violation, not a favor.

## Step 5 — Verify

1. Source and target frontmatter have **identical** `translationKey` values.
2. Run `pnpm build`. Fix any errors before finishing.

Report:

- Source file translated and output file created.
- The `translationKey` linking them.
- Notable localization decisions (adapted idioms, kept-original technical terms, cultural
  substitutions).

Before reporting, confirm:

- [ ] The target file sits in the target locale folder with the **same slug** as the source.
- [ ] `lang` is the target locale; `translationKey` matches the source exactly; `draft` status
      is preserved.
- [ ] `date`, tag slugs, and identifiers are untouched; prose fields are localized.
- [ ] `description` is ~70–160 characters and reads naturally in the target language.
- [ ] Markdown structure is intact; code blocks untranslated; relative links unchanged.
- [ ] No hreflang, RSS, or routing work was done by hand — the architecture derives it.
- [ ] `pnpm build` passes.

## Translating i18n UI strings

If `$ARGUMENTS` points at an i18n JSON (e.g. `src/i18n/en.json it`), translate the string
*values* into a new `src/i18n/{targetLocale}.json`:

- **Keys are identical across locales** — same flat dotted keys (`"layout.skipToContent"`),
  same key set, nothing added, nothing dropped. `MessageKey` is typed from the default locale;
  a missing key in another locale falls back to the default at runtime, which is a translation
  hole, not a feature.
- Keep placeholders like `{count}` and `{name}` byte-identical.
- UI copy follows the `ux-writing` skill: keep labels verb+object, keep terminology consistent
  with the strings already in the file.

```json
// 🔴 Bad: keys "translated", one key dropped
{ "layout.saltaAlContenuto": "Salta al contenuto" }

// ✅ Good: same keys, localized values, placeholders intact
{ "layout.skipToContent": "Salta al contenuto", "notFound.title": "Pagina non trovata" }
```

## Constraints

- Never machine-translate mechanically — localize for natural reading in the target language.
- Never change slugs/filenames or tag slugs when translating.
- Always link source and target via an identical `translationKey`.
- Always follow `.astro-builder/style-guide.md` for voice, tone, and terminology.
- Never hand-write hreflang links, RSS items, or routes for a translation — placement +
  frontmatter make the architecture derive them (see `seo-conventions`).
- i18n JSONs keep identical flat dotted key sets across all locales; placeholders unchanged.
- Follow MDN Web API references for any web-related terminology; always follow the Astro 6
  documentation: https://docs.astro.build/llms-small.txt
