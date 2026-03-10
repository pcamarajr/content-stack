---
name: internal-linking
description: Bidirectional linking rules and conventions for content cross-references
user-invocable: false
disable-model-invocation: false
---

# Internal Linking Rules

This skill defines how content cross-referencing works. It is preloaded into the `content-linker` agent and referenced by content creation skills.

## Link Syntax

### Inline Links (in article/glossary body)

```markdown
<!-- Glossary term (first mention only) -->
[some term](/en/glossary/some-term)

<!-- Related article -->
[related article](/en/articles/related-article)
```

### Frontmatter References (use lang prefix)

**Articles** have these frontmatter fields:

```yaml
relatedGlossary: ["en/some-term", "en/another-term"]
relatedArticles: ["en/related-article", "en/another-article"]
```

**Glossary entries** have these frontmatter fields:

```yaml
relatedTerms: ["en/related-term", "en/another-term"]
relatedArticles: ["en/related-article", "en/another-article"]
```

Note: `relatedGlossary` is article-only. `relatedTerms` is glossary-only. `relatedArticles` exists on both.

## Bidirectional Linking Rules

Bidirectional linking is **strongly recommended** for discoverability, but not mandatory in every case. Use judgment — there are situations where a back-link may not make sense (e.g., a broad foundational article doesn't need to link to every niche article that references it).

When content A references content B, content B should also reference content A:

| New Content | References | Action on Referenced Content |
| ---- | ----- | ----- |
| Article | Glossary term (inline link) | Add article to glossary's `relatedArticles` |
| Article | Another article (inline or frontmatter) | Add to each other's `relatedArticles` |
| Glossary | Another glossary term | Add to each other's `relatedTerms` |
| Glossary | Article | Add to each other's `relatedArticles`/`relatedGlossary` |

### Inline Back-Links in Body Text

If the new content's topic is mentioned in an existing article's body text WITHOUT a link:

- Add an inline link on the first mention
- ONLY if it reads naturally — don't force it
- Light rewrites are acceptable to integrate links naturally, as long as the style guide rules (sentence length, tone, scope) are respected. The goal is readability, not minimal diff.

## Editing Rules When Linking

1. **Only change specific frontmatter arrays** — append the new ID to the array
2. **Only change specific lines** — add link markup around existing text, or lightly rewrite for natural link integration (respecting style guide rules)
3. **Never reformat** existing content (indentation, line breaks, frontmatter order)
4. **Never restructure** paragraphs or sections
5. **Check before adding** — don't duplicate IDs already in arrays

## Linking Checklist for New Content

After creating any new article or glossary entry:

- [ ] All glossary terms in the body are linked (first mention only)
- [ ] All related articles are linked in the body where natural
- [ ] `relatedGlossary` includes glossary terms linked in body, and may also include terms relevant to the topic even if not explicitly linked in the body (these represent "related reading" for the reader)
- [ ] `relatedArticles` includes all related articles — both those linked in body and those relevant to the topic even without an inline link
- [ ] Referenced glossary entries have this content in their `relatedArticles` (strongly recommended, use judgment)
- [ ] Referenced articles have this content in their `relatedArticles` (strongly recommended, use judgment)
- [ ] No orphaned references (pointing to non-existent content)
- [ ] No duplicate links (same term linked twice in same article)

## For Translated Content

Translated articles use the target language prefix:

- `<lang>/<slug>` — e.g., `es/getting-started`
- Links: `[term](/<lang>/glossary/<term-slug>)` — use the URL pattern from config `url_patterns` if configured for the target language
- `relatedGlossary: ["<lang>/<term>"]`
