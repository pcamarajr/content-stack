# Round: Strategy

Goal: Define per-content-type SEO rules in `.content-seo/config.md`. Content pillars come from content-ops — this round only configures what's SEO-specific.

---

## Phase 1: Load context

Read silently:

- `.content-seo/config.md` → get `content_ops_config`, existing `seo_rules` if present
- Read content-ops config from `content_ops_config` path → extract `content_types` keys, `content_pillars_path`, `glossary` block
- `package.json` → site name for context

**Hard stop:** If `.content-seo/config.md` does not exist or `gsc_property` is not set → tell the user to run `/seo init project` first and stop.

---

## Phase 2: Existing strategy check

If `seo_rules` is already set in `.content-seo/config.md`:

```text
I found existing SEO rules:

  Content types configured: [list from seo_rules keys]

Want to:
  A — Keep it and skip this round
  B — Review and update
```

- If **A**: output "Strategy already set. Setup is complete — run `/seo status` to get started." and stop.
- If **B**: continue to Phase 3.

---

## Phase 3: Interview

**Determine which content types to configure:**

Read `content_types` from the content-ops config. Use only the keys actually defined there. If the content-ops config has a `glossary` block with `enabled: true`, include the glossary content type; otherwise skip it.

For each content type, ask once using AskUserQuestion:

```text
For [content type]: what's your minimum target word count for SEO?
```

Options:
- Short (50–300 words)
- Medium (600–1,000 words)
- Long (1,200–2,000 words) — in-depth guides and pillar pages

**Note:** Meta description length defaults and H1 keyword requirement are set automatically — no need to ask. The user only needs to confirm word count targets.

---

## Phase 4: Write config

Update `.content-seo/config.md` — append or replace the `seo_rules` section. Preserve all existing fields exactly.

```yaml
# Written by /seo init strategy
seo_rules:
  [content_type]:
    meta_description_length: [150, 160]
    h1_includes_keyword: true
  [glossary_type]:
    meta_description_length: [100, 160]
    h1_includes_keyword: true
```

**Note:** `min_word_count` is no longer stored in content-seo config — it is read from content-ops `content_types.<type>.word_range[0]` at runtime.

Add one `seo_rules` entry per content type collected.

---

## Phase 5: Confirm

```text
✅ Strategy saved to .content-seo/config.md

  SEO rules: [content types configured]

  Content pillars: read from content-ops at runtime ([content_pillars_path])

Setup complete. You can now use:
  /seo status           — Site-wide performance from GSC (last 28 days)
  /seo opportunities    — Pages in positions 4–20 with the most untapped traffic
  /seo diagnose <file>  — Deep-dive a specific page with GSC data + technical audit
  /seo brief <topic>    — Keyword research before writing (requires DataForSEO)
```
