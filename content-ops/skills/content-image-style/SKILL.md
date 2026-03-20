---
name: content-image-style
description: Image style reference — visual guidelines, prompt templates, placement rules, and file naming conventions for image generation. Reads project-specific values from plugin config.
user-invocable: false
disable-model-invocation: false
---

# Image Style Reference

This skill provides the image generation rules for content creation. It is auto-loaded during image generation tasks.

## Config Values

The following `image_generation` values are expected in your task prompt from the orchestrator:

- `image_generation.enabled`, `image_generation.provider`, `image_generation.model`, `image_generation.guidelines`
- `image_generation.output_path`, `image_generation.hero_dimensions`, `image_generation.inline_dimensions`
- `image_generation.placement`, `image_generation.min_word_count`, `image_generation.skip_types`
- `image_generation.max_inline_images` (optional — caps inline images per article)

For the full image style guide, read the file at `image_generation.guidelines` (e.g., `.content-ops/image-style-guide.md`). Below is the condensed reference for quick access.

## Pre-Flight Checks

Before generating any images, verify:

1. `image_generation.enabled` is `true` — if not, skip entirely and note "image generation is disabled"
2. The content type is not in `image_generation.skip_types` — if it is, skip entirely
3. The article word count is at or above `image_generation.min_word_count` — if below, skip entirely
4. The required API key environment variable is set — check **without printing the value**:
   ```bash
   test -n "${GEMINI_API_KEY}" && echo "set" || echo "missing"
   ```
   **Never echo, log, or include the API key in any output.** If missing, stop with a clear error:
   - Gemini: `GEMINI_API_KEY`
   - OpenAI: `OPENAI_API_KEY`

## Placement Decision Framework

When `placement` is `ai-driven`:

**Always add:**
- A hero image for every qualifying article (at the top, before the first paragraph)

**Add a section image when the H2 section:**
- Covers an abstract concept that benefits from visual representation
- Introduces a process, workflow, or comparison
- Is longer than ~150 words and not primarily a code block or numbered list

**Skip a section image when:**
- The section is a short factual statement
- The section already has code examples or step-by-step instructions (already visual enough)
- The section is the closing "next steps" or "related reading" section
- The section is very short (under 80 words)

**Default approach:** fewer, better-placed images beat one-per-section coverage. If `image_generation.max_inline_images` is set in config, respect that cap. Otherwise, use editorial judgment — typically 1–3 inline images for a standard article. Always defer to the image style guide at `image_generation.guidelines` for project-specific placement preferences.

## API Call Patterns

### Google Gemini (Nano Banana)

Use the model specified in `image_generation.model` from config. If not set, default to `imagen-3.0-generate-002`. Make API calls via Bash using curl:

```bash
# MODEL comes from image_generation.model in config (default: imagen-3.0-generate-002)
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:predict?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "instances": [{"prompt": "[your prompt here]"}],
    "parameters": {
      "sampleCount": 1,
      "aspectRatio": "[16:9 for inline | 1200:630 expressed as aspect ratio]",
      "outputMimeType": "image/webp"
    }
  }'
```

The response contains a base64-encoded image in `predictions[0].bytesBase64Encoded`. Decode and write to the output path.

### OpenAI GPT Image

```bash
curl -s -X POST \
  "https://api.openai.com/v1/images/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -d '{
    "model": "${MODEL}",  // from image_generation.model in config (default: gpt-image-1)
    "prompt": "[your prompt here]",
    "n": 1,
    "size": "1792x1024",
    "response_format": "b64_json"
  }'
```

The response contains a base64-encoded image in `data[0].b64_json`.

## Prompt Construction

Build prompts by combining three parts:

1. **Content description** — What the image should depict, derived from the article section's key concept
2. **Style modifiers** — From the `Visual Style` section of the image style guide
3. **Base prompt template** — From the `Base Prompt Template` section of the image style guide

Example assembled prompt:
```
A developer reviewing a distributed system architecture diagram on a laptop screen.
Flat illustration style, clean geometric shapes, bold outlines, minimal texture.
Primary color #1A1A2E accent color #E94560, neutral background, no text overlays,
no watermarks, professional quality, suitable for a blog article about microservices.
```

Keep prompts under 400 characters. Avoid vague terms like "beautiful" or "amazing" — be specific about what is depicted.

## File Naming and Output

```text
Output root:     {image_generation.output_path}/articles/{article-slug}/
Hero image:      hero.webp
Inline images:   {section-heading-slug}.webp (e.g., "## How Consensus Works" → how-consensus-works.webp)
Fallback format: .png (if API does not support webp)
```

Derive inline filenames by slugifying the H2 heading: lowercase, replace spaces and special characters with hyphens, collapse consecutive hyphens, trim leading/trailing hyphens. This makes filenames meaningful and aligned with the section content.

Write image bytes by piping the base64-decoded output via Bash:
```bash
echo "[base64 string]" | base64 -d > public/images/articles/{slug}/hero.webp
```

Always verify the file was written (check file size > 0) before returning the path.

## Alt Text Rules

- Describe what the image depicts, not what it "is"
- Include the article topic keyword naturally
- Keep under 125 characters
- Do not start with "image of", "photo of", or "picture of"
- Write for screen readers — a blind user should understand what visual information they are missing

Examples:
```
Good: "A diagram showing how validator nodes reach consensus in a proof-of-stake network"
Bad:  "Image showing blockchain consensus"
```

## Markdown Reference Format

Insert images as standard Markdown:

**Hero image** — insert after the closing `---` of the frontmatter, before the first paragraph:
```markdown
![{alt text}]({output_path}/articles/{slug}/hero.webp)
```

**Inline section images** — insert immediately before the `## Section Title` heading they illustrate:
```markdown
![{alt text}]({output_path}/articles/{slug}/{section-heading-slug}.webp)

## Section Title
```

## Error Handling

- **API rate limit (429):** Retry up to 3 times with exponential backoff (2s, 4s, 8s). If still failing, skip the image and note it in the output.
- **API key missing:** Stop immediately with a clear error message. Do not attempt to generate.
- **Network error:** Retry once. If still failing, skip and note.
- **Decode error (corrupted image):** Skip and note. Do not write a broken file.

Always report skipped images clearly in the output so the orchestrator can flag them.
