---
name: audit
description: Audit the live published page for a content file. Fixes technical SEO issues (title, meta, alt text) directly in the source markdown and reports content gaps for /optimize.
argument-hint: <file-path>
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch, Task, TodoWrite, AskUserQuestion
---

Fetch the live published page for a content file, fix technical SEO issues in the source markdown, and report what `/optimize` can address.

**File:** $ARGUMENTS

---

## Phase 1: Load config

Read `.content-seo/config.md` → parse YAML frontmatter.

**Hard stops:**
- If `.content-seo/config.md` does not exist → "Run `/init project` first."
- If `site_url` is not set → "Run `/init project` to set your site URL."

Extract:
- `site_url`
- `default_locale`
- `target_audience`
- `seo_rules` (find the entry matching the file's content type)
- `content_ops_config` (if present, read it to get `content_types` for URL derivation)

---

## Phase 2: Derive live URL

From the file path in `$ARGUMENTS` and `site_url`, derive the live published URL.

**If content-ops is configured** (`content_ops_config` is set):
- Read `content_types` from the content-ops config
- Match the file path against each `content_types.<type>.path` to find the content type and slug
- Derive the URL using the pattern inferred from `site_url` and the matched path

**If content-ops is not configured:**
- Strip the file extension and known prefixes (`src/content/`, `content/`)
- Derive URL as `{site_url}/{remaining_path}`

**If the derived URL is uncertain**, ask:

```text
I derived this live URL from your file path:

  [derived_url]

Is this correct?
```

Use AskUserQuestion with options: "Yes, use this URL" / "The URL is different — I'll provide it".

---

## Phase 3: Delegate to page-analyzer agent

Pass a detailed brief to the `page-analyzer` agent via Task:

```text
Audit the SEO of the following page.

Source file:   [file path from $ARGUMENTS]
Live URL:      [derived or confirmed URL]
Site URL:      [site_url]
Locale:        [default_locale]
Audience:      [target_audience]
SEO rules:     [seo_rules for this content type, serialized as YAML]

Perform a full SEO audit:
1. Fetch the live URL
2. Analyze the HTML for technical and content quality issues
3. Apply technical fixes to the source markdown file
4. Return a structured report in the FIXED / NEEDS_OPTIMIZATION / MANUAL_ACTION format
```

---

## Phase 4: Present report

After the agent completes, present the structured report:

```text
## SEO Audit: [title from file frontmatter]
URL: [audited URL]

### Fixed in source file
- [list of technical fixes applied, or "No technical fixes needed"]

### Needs optimization  (/optimize can help)
- [content quality issues: thin content, keyword gaps, etc.]

### Manual action required
- [issues needing template or code changes, e.g. missing schema markup in layout]
```

If nothing needs manual action, omit that section.

---

## Phase 5: Commit

If the agent applied any fixes to the source file:

```
seo: audit fixes for "[title]"
```

If no fixes were needed, skip the commit and say so.

---

→ If there are items under "Needs optimization", suggest: `Run /optimize [file-path] to address content quality issues with keyword data.`
