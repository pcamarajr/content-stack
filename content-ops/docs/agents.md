# Agents

Agents are specialized sub-processes spawned by the `/write-content` and `/translate` skills. Each agent owns a specific part of the pipeline and operates independently — reading from files, doing its job, and writing results back.

You don't invoke agents directly. They're coordinated by the skill orchestrator.

---

## content-researcher

**Phase:** 4 (Research)

Handles fact-finding before drafting begins. Uses a file-based cache to avoid redundant web searches.

**What it does:**
1. Reads the research cache for the current topic (`research-cache/<topic>.json`)
2. If cache exists and is fresh (within `research_cache_ttl_days`), uses cached findings
3. If stale or missing, runs web research and writes new findings to cache
4. Returns a structured research brief: key facts, sources, claims to verify

**Cache behavior:** Cache files are JSON with a timestamp and TTL. Findings are reused across sessions. The cache is committed to git — portable across machines and Claude Code web sessions.

---

## draft-writer

**Phase:** 5 (Draft)

Writes the actual content file — article or glossary entry.

**What it does:**
- Reads the research brief from Phase 4
- Reads your style guidelines and reference articles (for tone calibration)
- Reads the content strategy and relevant pillar file
- Writes the file to the correct path with full frontmatter

**Inputs:** research brief, config, guidelines file, reference articles, strategy context
**Output:** the drafted `.md` file written to the configured content path

---

## image-generator

**Phase:** 5.5 (Images, optional)

Generates article images using the configured AI provider. Only runs if `image_generation` is set in config.

**What it does:**
1. Reads the drafted article to extract context (title, key points, tone)
2. Reads the image style guide (`content-image-style` skill)
3. Builds a detailed image prompt
4. Calls the configured API (Gemini or OpenAI)
5. Saves image files (webp) to `output_path`
6. Writes alt text and updates frontmatter with image paths

**Placement modes:**
- `hero-only` — one hero image per article
- `hero-plus-sections` — hero + one image per H2
- `ai-driven` — agent decides based on content length and structure

**Requires:** `GEMINI_API_KEY` or `OPENAI_API_KEY` environment variable.

---

## style-enforcer

**Phase:** 6 (Style Review)

Reviews the drafted article against your style guide and reference content. Applies fixes directly.

**What it checks:**
- Sentence length — flags anything over ~20 words, hard limit ~25
- Paragraph length — flags paragraphs over 4 sentences
- Plain language — complexity appropriate for your audience
- H2 structure — 2-4 sections, no H3 headings
- **The Scope Rule** — if a concept gets 2+ sentences, it probably warrants its own article with an internal link instead

**What it does:** Edits the file in place. Doesn't ask — applies changes according to the style guide, then reports what was changed.

---

## glossary-creator

**Phase:** 7 (Glossary Check)

Scans the drafted article for terms that appear in your content but don't yet have a glossary entry.

**What it does:**
1. Reads the content index to see existing glossary entries
2. Scans the article for technical or domain-specific terms
3. Creates missing glossary entries (full pipeline: draft → style → link)
4. Updates the content index

This runs automatically after every article — your glossary grows organically as you publish.

---

## content-linker

**Phase:** 8 (Bidirectional Linking)

Adds internal links to the new article, and updates existing articles to link back to it.

**What it does:**
1. Reads `content-index.json`, filters candidates by language and type (max `linking_max_candidates`)
2. Runs a single LLM ranking pass to select the most relevant matches (max `linking_max_links`)
3. Reads only the selected files
4. Adds links in both directions:
   - In the new article: inline links to related articles
   - In existing articles: updated frontmatter `relatedArticles` array and inline links where appropriate

**Why this approach:** Reading every content file to find links would be slow and expensive on large sites. The index-filter-rank pattern keeps linking fast regardless of how many articles you have.
