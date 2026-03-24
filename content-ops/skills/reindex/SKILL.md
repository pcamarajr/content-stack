---
name: reindex
description: Rebuild the content index by scanning all content files and writing .content-ops/content-index.json. Use after bulk content changes, migrations, or when the user asks to reindex.
argument-hint: ""
user-invocable: true
allowed-tools: Read, Glob, Write
---

# Reindex Content

Rebuild the content index by scanning all content files, extracting frontmatter, and writing `.content-ops/content-index.json`. No MCP, no embeddings, no API calls.

## When to use

- After initial plugin setup (first-time index)
- After bulk content edits or migrations
- After creating or modifying articles or glossary entries
- When the user explicitly asks to reindex

## Procedure

1. **Read config** from `.content-ops/config.md`:
   - `content_types` — each type's `path` (e.g., `article.path`, `glossary.path`)
   - `languages` — list of language codes to scan
   - `content_index_path`

2. **Scan content directories** for each content type and language:
   - Use Glob to find all `.md` and `.mdx` files under `{type.path}/{lang}/`
   - For each file: Read it and extract **frontmatter only** (the YAML between `---` delimiters). Do not include the body.

3. **Build the index structure** — use the **stable minimal schema** for every entry (all content types):

   Per entry:
   - `slug`: filename without extension
   - `path`: relative path to file (for traceability and linking edits)
   - `type`: content type key (e.g. `article`, `glossary`)
   - `lang`: language code from directory
   - `title`: articles → frontmatter `title`; glossary → frontmatter `term`
   - `excerpt`: articles → frontmatter `excerpt`; glossary → frontmatter `definition` (first 1–2 sentences)
   - `tags`: from frontmatter if present (default `[]`)
   - `translationKey`: from frontmatter if present (omit if absent)

4. **Write the JSON file** to `content_index_path` from config:

```json
{
  "generated_at": "<ISO 8601 timestamp>",
  "config_fingerprint": {
    "default_language": "<from config>",
    "languages": ["<from config>"],
    "content_types": { "article": { "path": "..." }, "glossary": { "path": "..." } }
  },
  "content": {
    "article": { "en": [...], "it": [...] },
    "glossary": { "en": [...], "it": [...] }
  }
}
```

5. **Ensure the directory exists**: If `.content-ops/` does not exist, create it before writing.

6. **Report results**: List how many items were indexed per type and language.

## Important notes

- This process only reads files and writes JSON. No external APIs or MCP tools.
- Items with missing or invalid frontmatter should be reported but should not stop the overall process.
- Re-indexing is idempotent — running again overwrites the index with current content.
