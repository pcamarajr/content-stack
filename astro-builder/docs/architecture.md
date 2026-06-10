# Architecture — the design criteria behind astro-builder

Every structural decision in this plugin — in the sites it generates and in the plugin itself —
is justified by the criteria in John Ousterhout's *A Philosophy of Software Design* (APoSD).
This document makes those criteria explicit so that future decisions can be argued from them,
not from taste. Two audiences:

1. **Code the builder generates** — what a well-designed astro-builder site looks like and why.
2. **The plugin itself** — why the audit, skills, and scaffolds are shaped the way they are.

The unit of judgment throughout is the **module**: anything with an interface (what callers must
know) and an implementation (what it hides). A layout, a `lib/` file, a skill, the audit — all
modules.

---

## Part 1 — The code the builder generates

### 1.1 — Deep modules: small interface, large functionality

A module's cost to its callers is its interface; its value is the functionality behind it. A
**deep** module gives a lot for a little. A **shallow** module makes you learn an interface
nearly as big as the implementation it fronts.

The canonical deep module in every generated site is the **BaseLayout `<head>`**
(`docs/init-templates/BaseLayout.astro.template`, rules in `skills/seo-conventions/SKILL.md`).
Its entire interface is five props:

```ts
interface Props {
  title: string;
  description: string;
  image?: string;
  type?: "website" | "article";
  publishedAt?: Date;
}
```

Behind those five props: the full title format, the canonical URL, the complete OG/Twitter set,
JSON-LD (`WebSite` / `Article`), hreflang alternates including `x-default`, and the RSS and
sitemap `<link>`s — all derived from `Astro.site`, `Astro.url`, `Astro.currentLocale`, and the
i18n config.

```astro
<!-- 🔴 Shallow: the interface restates the implementation — every page must know
     everything the layout knows, and each page can get it differently wrong -->
<BaseLayout
  title={title}
  canonical={`https://example.com/en/articles/${slug}`}
  ogTags={{ "og:title": title, "og:url": `https://example.com/en/articles/${slug}`, ... }}
  alternates={[{ lang: "en", href: "..." }, { lang: "it", href: "..." }]}
  jsonLd={{ "@type": "Article", headline: title, ... }}
>
```

```astro
<!-- ✅ Deep: pages state the five facts only they know; the layout derives the rest -->
<BaseLayout title={title} description={description} type="article" publishedAt={date}>
```

The test: **does the caller pass anything the module could derive?** If yes, the interface is
leaking implementation. The five props are exactly the facts only the page knows.

### 1.2 — Narrow interfaces pull complexity downward

When complexity must exist, put it inside the module so callers don't carry it. The generated
`src/lib/` layer is built on this:

- **`lib/i18n.ts`** — `createTranslator(Astro.currentLocale)` returns `tl(key)`. Nothing else
  knows where strings live, the fallback order, or the default locale. The `MessageKey` union
  turns a typo into a compile error instead of a blank string in production.
- **`lib/urls.ts`** — `buildLocaleUrl(locale, ...segments)` is the one place that knows every
  route carries a locale prefix and a trailing slash. Components never concatenate paths.

```astro
<!-- 🔴 Every component re-derives routing policy; change the URL scheme, sweep the codebase -->
<a href={`/${Astro.currentLocale}/articles/${article.id.replace(`${Astro.currentLocale}/`, "")}/`}>

<!-- ✅ Policy lives once, behind one function -->
<a href={buildArticleUrl(article.id, locale)}>
```

The complexity (locale prefixes, slug stripping, trailing slashes) didn't disappear — it moved
down, where it is written once and tested once.

### 1.3 — Information hiding: one decision, one place

Each design decision should live in exactly one module; everything else consumes its result.
In generated sites: `prefixDefaultLocale: true` is *known* only by `lib/urls.ts` (building
prefixes) and BaseLayout's `localePath` strip (removing the one the framework reports). No
component parses a URL to detect the locale — that would copy the routing decision into every
parser.

The same principle shapes this plugin: **a convention rule and its mechanical check live
together.** Each convention skill defines its rules in `SKILL.md` and ships their checks in
`references/audit.md`, side by side in one directory. Changing a rule is a one-directory edit.
If the audit owned the checks, every rule change would be a two-place edit that someone forgets
half of — the classic information leak.

### 1.4 — When NOT to create an abstraction

Depth cuts both ways: an abstraction that adds interface without adding functionality is pure
cost.

- **One adapter is a hypothetical seam.** Don't introduce an interface/port until at least two
  real implementations exist (e.g. production + test). With one, the "seam" is just
  indirection — collapse it.

  ```ts
  // 🔴 A ContentSource interface with exactly one implementation, "in case we
  // swap the CMS later" — callers now learn two surfaces to reach one behavior
  interface ContentSource { getArticles(lang: string): Promise<Article[]> }
  class CollectionContentSource implements ContentSource { ... }

  // ✅ The concrete function, until a second source is real
  export async function getArticlesByLang(lang: string): Promise<Article[]> { ... }
  ```

- **Passthrough wrappers are shallow by definition.** A function that forwards to another
  function with the same signature gives callers nothing.

  ```ts
  // 🔴 New surface, zero new functionality
  export function getTranslation(locale: string, key: MessageKey): string {
    return createTranslator(locale)(key);
  }
  ```

- **Real plugin example: there is no `new-component` skill.** Writing a component is already
  fully governed by `css-conventions`, `html-conventions`, and `ux-writing` — they auto-apply.
  A `new-component` skill would restate their rules behind a second entry point: a shallow
  wrapper over three deep modules. The decision *not* to build it was an architecture decision.

### 1.5 — Design it twice

Your first interface is unlikely to be the best one. Before fixing any interface — a `lib/`
function, a layout prop contract, a new skill — sketch **at least two radically different**
designs and compare them by depth (leverage per entry point), locality (where future change
concentrates), and what callers must know.

The BaseLayout contract went through exactly this. Alternatives considered:

| Design | Verdict |
|---|---|
| Per-tag props (`canonical`, `ogImage`, `alternates`, ...) | Shallow — interface grows with every SEO feature; callers restate derivable facts |
| One `seo: SeoConfig` object prop | Same width, hidden in a bag — and invites pages to construct policy |
| **Five scalar props, everything else derived** | Deep — interface only grows when a page learns a genuinely new fact |

Write the comparison down (a few lines in the plan is enough). If the second design never beats
the first, you at least know *why* the first is right.

### 1.6 — Comments are part of the design

A comment earns its place by saying what the code *cannot* say: intent, invariants, the reason a
derivation is shaped the way it is. The generated templates practice this:

```ts
// ✅ States an invariant the signature can't express (from urls.ts):
/** RSS feed for a locale: `/en/rss.xml`. No trailing slash — it is a file, not a page. */

// ✅ States the design rule and its boundary (from BaseLayout):
// Hand-written SEO tags anywhere else are a violation.
```

```ts
// 🔴 Restates the code — noise that will drift
// loop over the locales and create a link for each
locales.map((locale) => ...)
```

If you can't write a comment that adds information, the abstraction may not need one — or the
abstraction itself may be too thin to describe.

---

## Part 2 — Evolving the plugin

The plugin is judged by the same criteria as the code it generates.

### 2.1 — The audit is a thin orchestrator

`skills/audit/SKILL.md` defines the report contract, the run order, and the checks that have no
backing skill (architecture, i18n, schema, build). It never restates a convention rule. Each
domain's rules live in its skill's `SKILL.md`; the mechanical checks live in that skill's
`references/audit.md`; the audit reads a table and runs what it finds.

**The cost target is the design's acceptance test: adding a domain to the audit costs one
row in one table.** When the css-conventions skill shipped, the audit gained one line. If a
future change makes a new domain cost more than that, the orchestrator has started absorbing
knowledge that belongs in a skill — that is the regression to catch in review.

### 2.2 — Skills are deep modules

A skill's frontmatter `description` is its interface — it must carry everything the trigger
decision needs, because it is all the model sees before loading the body. The body is the
implementation: rules, rationale, good/bad contrasts, verification list. The same shallow-module
smell applies: a skill whose body merely restates other skills (see the `new-component`
non-decision, §1.4) should not exist.

### 2.3 — Checklist for any structural change

Before adding a skill, agent, scaffold template, or audit domain:

- [ ] Is the new module deep — interface meaningfully smaller than what it hides?
- [ ] Does each piece of knowledge it introduces live in exactly one place?
- [ ] Did you sketch at least two interface designs and record why the winner won?
- [ ] If it wraps something that exists, what functionality does the wrapper *add*?
- [ ] Does "add the next instance of this" still cost one line / one file / one row?

---

## Attribution

The concepts here — deep vs. shallow modules, information hiding, pulling complexity downward,
design it twice, comments as design — are from **John Ousterhout, *A Philosophy of Software
Design*** (Yaknyam Press). This document adapts them to the astro-builder domain; read the book
for the full argument.

The seam/adapter framing in §1.4 and the compare-by-depth/locality process in §1.5 are adapted
from the `improve-codebase-architecture` skill (`DEEPENING.md`, `INTERFACE-DESIGN.md`) in
[mattpocock/skills](https://github.com/mattpocock/skills) (MIT). See `NOTICE.md` at the plugin
root.
