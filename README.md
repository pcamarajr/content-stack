# content-stack

A curated collection of Claude Code plugins by [@pcamarajr](https://github.com/pcamarajr), covering content operations, SEO, and static site tooling.

## Installation

Add this marketplace to your Claude Code project:

```bash
/plugin marketplace add pcamarajr/content-stack
```

## Available Plugins

### [content-ops](./content-ops/README.md)

Content creation and management plugin for static site blogs. Handles writing, translation, research, internal linking, style review, and knowledge indexing.

**Agents:** content-linker, content-researcher, draft-writer, glossary-creator, image-generator, style-enforcer

**Skills:** write-content, translate, review-content, internal-linking, fact-check, suggest-content, content-style, content-image-style, content-inventory, reindex, update-trackers, init

To install this plugin:

```bash
/plugin install content-ops@content-stack
```

### [cost-tracker](./cost-tracker/README.md)

Track Claude Code token usage and estimated API cost per session. Shows a live running cost in the status bar and a session summary on stop. Logs are scoped to your project and stored in `.cost-log/`.

**Skills:** report

To install this plugin:

```bash
/plugin install cost-tracker@content-stack
```

### [astro-lsp](./astro-lsp/README.md)

Astro language server for Claude Code. Provides code intelligence, diagnostics, and formatting for `.astro` files. Automatically installs the language server binary at session start — works out of the box in remote and cloud environments.

To install this plugin:

```bash
/plugin install astro-lsp@content-stack
```

### [astro-builder](./astro-builder/README.md)

Astro 6 static content site builder. Enforces the page-views pattern, i18n via `Astro.currentLocale`, content collections with `glob()` loaders, Biome, and pnpm. Designed for markdown-based content sites: blogs, education platforms, documentation, and news sites.

**Agents:** astro-architect, astro-builder

**Skills:** init, new-page, new-content-type, translate, audit

To install this plugin:

```bash
/plugin install astro-builder@content-stack
```

## License

MIT
