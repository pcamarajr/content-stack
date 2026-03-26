# content-stack

A plugin ecosystem for founders and marketers who want to run a serious content operation without hiring a full specialist team.

`content-stack` helps you build and maintain content websites with AI-assisted workflows across strategy, production, and publishing.

## Who This Is For

- Founders and marketers with limited time and budget
- Small teams that need repeatable content workflows
- Teams building markdown-first sites (especially Astro)
- Agencies that need to scale content operations with fewer manual steps

## What You Can Do With It

- Build a production-ready Astro content site
- Create and maintain SEO-focused blog content
- Standardize writing quality and style across content
- Scale content operations with reusable skills and agents

## Install Marketplace

Add this marketplace to your Claude Code project:

```bash
/plugin marketplace add pcamarajr/content-stack
```

Then install the plugin you need:

```bash
/plugin install content-ops@content-stack
/plugin install astro-builder@content-stack
/plugin install astro-lsp@content-stack
/plugin install cost-tracker@content-stack
```

## Quick Start Paths

### Path A: Start from a template (fastest)

Use the Astro starter generated with the current `astro-builder` plugin:

- [`pcamarajr/astro-template`](https://github.com/pcamarajr/astro-template)

Then adapt it to your project using:

```bash
/astro-builder:init
```

### Path B: Add content workflows to an existing site

Install `content-ops` and initialize:

```bash
/plugin install content-ops@content-stack
/init
/reindex
```

Run your first draft workflow:

```bash
/write-content article "Your topic"
```

## Plugins

### [`content-ops`](./content-ops/README.md)

Content operations plugin for markdown-based sites. It handles research, drafting, review, translation, linking, and indexing through a phase-based workflow.

- **Best for:** publishing better blog content with less manual work
- **Key skills:** `init`, `write-content`, `review-content`, `fact-check`, `reindex`

Install:

```bash
/plugin install content-ops@content-stack
```

### [`astro-builder`](./astro-builder/README.md)

Astro 6 site builder plugin that scaffolds and evolves static content sites using the page-views pattern, i18n, content collections, and quality gates.

- **Best for:** creating or restructuring Astro content architectures
- **Key skills:** `init`, `new-page`, `new-content-type`, `translate`, `audit`

Install:

```bash
/plugin install astro-builder@content-stack
```

### [`astro-lsp`](./astro-lsp/README.md)

Astro language server integration for Claude Code with diagnostics, formatting, and code intelligence for `.astro` files.

Install:

```bash
/plugin install astro-lsp@content-stack
```

### [`cost-tracker`](./cost-tracker/README.md)

Session-level token and cost tracking for Claude Code, including subagent runs.

Install:

```bash
/plugin install cost-tracker@content-stack
```

## Current Focus

This ecosystem follows a dogfood-first model: features are built through real usage on active projects and then generalized.

Current emphasis:

- SEO-ready blog workflows
- Better quality and consistency in published content
- Faster iteration with reusable skills/agents

## Public Validation Status

The project is in active public validation. Core workflows are usable and being expanded with real-world usage.

If you try it, share feedback and use cases:

- Open an issue: <https://github.com/pcamarajr/content-stack/issues>
- Send a DM: <https://linkedin.com/in/pcamarajr>

## 90-Day Direction

- Strengthen SEO skills and agents for blog workflows
- Improve install-to-first-value experience
- Publish reusable templates and examples
- Expand from blog workflows into broader content operations use cases

## License

MIT
