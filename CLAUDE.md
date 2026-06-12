# content-stack

A community-facing marketplace of Claude Code plugins for building, maintaining, and evolving static content websites — initially Astro-based. Covers both infrastructure (site building, language servers) and content operations (writing, translation, linking, images).

---

## Repository structure

```text
content-stack/
├── .claude-plugin/
│   └── marketplace.json        ← plugin registry (name, version, description, source)
├── content-ops/                 ← content creation & management plugin
├── astro-builder/               ← Astro 6 site builder plugin
├── astro-lsp/                   ← Astro language server plugin
└── README.md                    ← marketplace landing page (install commands, plugin list)
```

Each plugin directory follows this layout:

```text
plugin-name/
├── README.md                    ← user-facing docs (required)
├── agents/                      ← agent definition files (.md)
├── skills/                      ← skill definition files (SKILL.md per skill)
├── hooks/                       ← hooks.json + handler scripts
└── docs/                        ← extended documentation
```

---

## Marketplace registry

The single source of truth for registered plugins is `.claude-plugin/marketplace.json`.

Every plugin entry must have: `name`, `version` (semver), `description`, `author.name`, `source`, `category`.

---

## Releases

Versions are managed by **release-please** (manifest mode, one package per plugin) — never bump a `version` by hand. PRs are squash-merged, so the PR title must be a conventional commit scoped to the plugin (e.g. `feat(astro-builder): ...`); `feat`/`fix`/`!` trigger releases. Merging the release PR that release-please opens updates `marketplace.json` + the plugin's `CHANGELOG.md` and cuts the tag/GitHub Release. Config: `release-please-config.json` + `.release-please-manifest.json`.

---

## Adding a new plugin

1. Create the plugin directory with `README.md` and its components
2. Run `/version-plugin` — it registers the entry in `marketplace.json`, the release-please config/manifest, and updates the root `README.md`

---

## Conventions

- Plugin names are lowercase, hyphenated (e.g. `astro-builder`, `content-ops`)
- Skills use `SKILL.md` as the filename inside `skills/<skill-name>/`
- Agents use `<agent-name>.md` inside `agents/`

---

## Development plugins

The following plugins are enabled project-wide via `.claude/settings.json` — no global installation needed:

| Plugin | Why it's here |
| --- | --- |
| `plugin-dev` | End-to-end plugin authoring: skills, agents, hooks, commands, MCP, validation |
| `superpowers` | Structured planning, TDD, debugging, code review, and parallel agent dispatch |
| `feature-dev` | Feature exploration, architecture design, and implementation review for new plugins |
| `code-review` | Reviewing plugin PRs and contributions before merging |
