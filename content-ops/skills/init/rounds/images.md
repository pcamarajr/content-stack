# Round: Image Generation

Goal: Configure image generation for articles — visual style, color palette, placement rules, and output settings.

---

## Phase 1: Check existing state

Read `.content-ops/config.md`. Parse the YAML frontmatter.

Check if an `image_generation` section exists in config. If it does, check if the file at `image_generation.guidelines` exists on disk.

**If both the config section and guidelines file already exist:**

Read the guidelines file. Summarize it in 3–5 bullets (provider, style, palette, placement, skip conditions).

Use `AskUserQuestion` to ask:

```
question: "I found an existing image style guide at [path from config]. [summary bullets]. What would you like to do?"
options:
  - label: "Keep as-is"
    description: "Skip this round — current settings are fine"
  - label: "Update sections"
    description: "Change specific parts while keeping the rest"
  - label: "Replace entirely"
    description: "Start fresh with a new image style guide"
```

- If **Keep as-is**: stop and guide to the next incomplete round.
- If **Update sections**: use a follow-up `AskUserQuestion` to ask which sections to update (multiSelect). Then run only the relevant questions from Phase 2 for those sections.
- If **Replace entirely**: continue to Phase 2.

**If not yet configured:** continue to Phase 2.

---

## Phase 2: Image style interview

Ask questions **one at a time** using `AskUserQuestion`. Wait for each answer before asking the next. Each answer shapes subsequent questions — skip anything already implied.

### Question 1: Provider

```
question: "Which image generation provider should the plugin use?"
header: "Provider"
options:
  - label: "Google Gemini / Nano Banana (Recommended)"
    description: "Single SDK for text+image, ~$0.04/image, supports brand style reference via reference images"
  - label: "OpenAI GPT Image"
    description: "Highest quality benchmarks, ~$0.04/image, widely used API"
  - label: "I'll configure it manually"
    description: "Skip — I'll set the API details in config myself"
```

Store the answer. If manual: note `provider: manual`.

**Follow-up (if Google Gemini or OpenAI):** Ask whether they want to use a specific model or the default.

```
question: "Which model should we use? Leave as default unless you have a preference."
header: "Model"
options:
  - label: "Default (Recommended)"
    description: "imagen-3.0-generate-002 for Gemini, gpt-image-1 for OpenAI"
  - label: "Specify a model"
    description: "I want to use a specific model version"
```

If they pick "Specify a model", the "Other" free-text option lets them type it.

### Question 2: Visual style

```
question: "What visual style should generated images follow?"
header: "Style"
options:
  - label: "Flat illustration"
    description: "Clean shapes, modern, bold outlines — great for tech and product blogs"
  - label: "Photorealistic"
    description: "Realistic, stock-photo-like scenes and people"
  - label: "Minimalist diagram"
    description: "Clean lines, technical clarity, neutral tones — best for docs and tutorials"
  - label: "Watercolor / editorial"
    description: "Soft, artistic, magazine feel — best for lifestyle and narrative content"
```

The "Other" free-text option lets users describe a custom style. Capture their description verbatim — it becomes the style prompt modifier.

### Question 3: Color palette

```
question: "Should generated images follow a brand color palette?"
header: "Colors"
options:
  - label: "Yes — I'll provide hex codes"
    description: "Consistent brand colors across all generated images"
  - label: "No specific palette"
    description: "Let the AI choose colors based on content context"
```

If **Yes**: use a follow-up `AskUserQuestion`:

```
question: "Enter 2–4 hex codes for your brand palette. Label them if you like (e.g., '#1A1A2E primary, #E94560 accent')."
header: "Hex codes"
options:
  - label: "Enter colors"
    description: "Type your hex codes in the 'Other' field below"
```

The user will type their colors via the Other/free-text input.

### Question 4: Placement and density

```
question: "When should images be added to an article?"
header: "Placement"
options:
  - label: "AI decides based on content (Recommended)"
    description: "Context-aware — adds images where they enhance understanding, skips where they don't"
  - label: "Hero + one per H2 section"
    description: "Comprehensive coverage — every article section gets an image"
  - label: "Hero image only"
    description: "Minimal — one image at the top of each article"
```

**Follow-up:** Ask about the maximum inline image cap and minimum word count.

```
question: "How many inline images (besides the hero) should an article have at most?"
header: "Image cap"
options:
  - label: "No hard cap — let the AI decide"
    description: "Placement based purely on content analysis"
  - label: "Max 2 inline images"
    description: "Hero + up to 2 section images"
  - label: "Max 3 inline images"
    description: "Hero + up to 3 section images"
```

Then:

```
question: "What is the minimum article word count before images are generated?"
header: "Min words"
options:
  - label: "300 words (Recommended)"
    description: "Skip images for very short articles"
  - label: "500 words"
    description: "Only generate images for substantial articles"
  - label: "No minimum"
    description: "Generate images for all articles regardless of length"
```

### Question 5: Skip conditions

```
question: "When should image generation be skipped?"
header: "Skip rules"
multiSelect: true
options:
  - label: "Glossary entries"
    description: "Usually too short for images"
  - label: "Translation runs"
    description: "Images already exist from the original language"
  - label: "No skip conditions"
    description: "Generate images for everything"
```

### Question 6: Output settings

```
question: "Where should generated images be saved?"
header: "Output path"
options:
  - label: "public/images (Recommended)"
    description: "Standard static asset location for most frameworks"
  - label: "Custom path"
    description: "I'll specify a different directory"
```

If **Custom path**: the user types their path via the Other/free-text input.

---

## Phase 3: Create image style guide

Using the answers from Phase 2, create the image style guide at the path that will be set in config (default `.content-ops/image-style-guide.md`).

The guide must be **actionable** — it is read verbatim by the `image-generator` agent to build image prompts and make placement decisions.

Include these sections:

### Provider

Which API to use and the model.

```text
Provider: [google-gemini | openai-gpt-image | manual]
Model: [model name or "default"]
API key environment variable: [GEMINI_API_KEY | OPENAI_API_KEY | as specified]
```

### Visual Style

A clear, specific description the agent can embed directly into image prompts.

Include:
- Style name (e.g., "flat illustration")
- 3–5 adjective/descriptor keywords for prompt use (e.g., "clean lines, bold shapes, minimal texture")
- What to avoid (e.g., "no photorealism, no drop shadows, no gradients")
- One example prompt fragment showing how the style should be expressed

### Color Palette

If a palette was provided:
- List each color with its hex code and label (primary, accent, background, etc.)
- Instruction for the agent: "Always include these colors as dominant tones in generated images"

If no palette: "Let the API choose colors based on content context. Prefer clean, professional tones."

### Placement Rules

```text
Mode: [ai-driven | hero-plus-sections | hero-only]
Minimum word count: [N]
Max inline images: [N or "no cap"]
```

If mode is `ai-driven`, add guidance for the agent:
- Add a hero image for every article that passes the word count threshold
- Add a section image when a concept is abstract, visual, or benefits from illustration
- Skip section images when the content is already concrete (e.g., code examples, numbered steps, short factual sections)

### Skip Conditions

List the conditions under which the `image-generator` agent should do nothing:

- Content types to skip (e.g., glossary)
- Word count threshold
- Translation runs (if selected)
- Any user-specified additional conditions

### Output Settings

```text
Hero image dimensions: [W] × [H] px
Inline image dimensions: [W] × [H] px
Output format: webp (fallback: png)
Output path: [user-chosen path]/articles/{slug}/
Hero filename: hero.webp
Inline filename: {section-heading-slug}.webp
```

### Alt Text Convention

Instructions for generating SEO-friendly alt text:
- Describe what the image shows, not what it "is"
- Include the article topic keyword naturally
- Keep it under 125 characters
- No "image of" or "photo of" prefix

### Base Prompt Template

A reusable prompt fragment the agent should append to every generation call:

```text
[Style keywords from Visual Style section], [color palette instruction], white or neutral background,
no text overlays, no watermarks, professional quality, suitable for a blog article about [topic]
```

---

## Phase 4: Update config

Update `.content-ops/config.md` — add or update the `image_generation` block in the YAML frontmatter:

```yaml
# Image generation
image_generation:
  enabled: true
  provider: "[google-gemini | openai-gpt-image | manual]"
  model: "[model or omit for default]"
  guidelines: "[path to image style guide]"
  output_path: "[user-chosen output path]"
  hero_dimensions: [1200, 630]
  inline_dimensions: [800, 450]
  placement: "[ai-driven | hero-plus-sections | hero-only]"
  max_inline_images: [N or omit for no cap]
  min_word_count: [N]
  skip_types: ["glossary"]
```

Preserve all other existing config fields.

---

## Phase 5: Confirm and guide

```text
✅ Image style guide created at [guidelines path]

Settings:
  • Provider: [provider] ([model])
  • Style: [style name]
  • Placement: [placement mode]
  • Max inline images: [N or "no cap"]
  • Min word count: [N]
  • Output: [output_path]/articles/{slug}/

Config updated with image_generation settings.

Before running /write-content, set your API key:
  export [GEMINI_API_KEY | OPENAI_API_KEY]=[your-key]

→ Next: [next incomplete round, or "All rounds complete — run /reindex to build the content index"]
```
