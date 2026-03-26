# astro-lsp

Astro language server for Claude Code, with diagnostics, navigation, and formatting for `.astro` files.

`astro-lsp` is part of [content-stack](https://github.com/pcamarajr/content-stack) and is intended to make Astro editing predictable in local and remote environments.

## Supported Extension

`.astro`

## Installation

```bash
/plugin marketplace add pcamarajr/content-stack
/plugin install astro-lsp@content-stack
```

The plugin auto-installs `@astrojs/language-server` at session start when needed, so it works out of the box in cloud and remote development setups.

## Capabilities

- Diagnostics and error checking for `.astro` files
- Go-to-definition across components
- Find references and hover documentation
- TypeScript/JavaScript intellisense inside frontmatter and script blocks
- CSS/SCSS/Less support inside `<style>` blocks

## When To Use

- You build with Astro and want LSP support in Claude Code
- You need stable diagnostics for `.astro` during iterative changes
- You work in environments where manual language server setup is inconvenient

## References

- [Astro Language Tools on GitHub](https://github.com/withastro/astro/tree/main/packages/language-tools/language-server)
- [`@astrojs/language-server` on npm](https://www.npmjs.com/package/@astrojs/language-server)
- [Astro Documentation](https://docs.astro.build/)
