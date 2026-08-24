# content-stack

A community-facing marketplace of Claude Code plugins for building, maintaining, and evolving static content websites — initially Astro-based. Covers both infrastructure (site building, language servers) and content operations (writing, translation, linking, images).

---

## Repository structure

```text
content-stack/
├── .claude-plugin/
│   └── marketplace.json        ← plugin registry (name, version, description, source)
├── content-ops/                 ← content creation & management plugin
├── astro-builder/               ← Astro 7 site builder plugin
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

Versions are managed by **release-please** (manifest mode, one package per plugin) — never bump a `version` by hand. PRs are squash-merged, so the PR title must be a conventional commit scoped to the plugin (e.g. `feat(astro-builder): ...`); `feat`/`fix`/`!` trigger releases, `chore`/`docs`/`refactor`/`ci` do not — a refactor users will perceive as a feature should be titled `feat(...)`. Merging the release PR that release-please opens updates `marketplace.json` + the plugin's `CHANGELOG.md`/`version.txt` and cuts the tag (`<plugin>-v<version>`) and GitHub Release. Config: `release-please-config.json` + `.release-please-manifest.json`.

Commit messages and PR titles/descriptions are always written in English. Conventional-commit format is enforced locally by a husky `commit-msg` hook (commitlint — run `npm install` once to activate) and in CI by the PR-title lint.

---

## Adding a new plugin

1. Create the plugin directory with `README.md` and its components
2. Add the entry to `.claude-plugin/marketplace.json` with `version: "1.0.0"` — the only time a version is written by hand
3. Scaffold `<plugin>/.claude-plugin/plugin.json` (name, description, author, repository, license — no `version` field; version lives exclusively in `marketplace.json`)
4. Register in `release-please-config.json` (copy an existing `packages` entry, adjusting the plugin name in the key, `component`, and the jsonpath, and add `"bump-minor-pre-major": false` so the first release lands on `1.0.0`) and `.release-please-manifest.json` (`"<plugin>": "0.0.0"` — release-please computes the real first version itself; never seed the manifest with `1.0.0` by hand, or it will skip straight to `1.1.0` on the first `feat` commit). The `component` field is required for `release-type: simple` — without it, release-please treats the package as nameless and cuts bare `vX.Y.Z` tags instead of `<plugin>@X.Y.Z`.
5. Add the plugin name to the `scopes` list in `.github/workflows/lint-pr-title.yml`
6. Add the plugin section to the root `README.md`, in alphabetical order
7. Title the PR `feat(<plugin>): ...` — `feat` makes release-please cut the plugin's first release; starting from `0.0.0` with `bump-minor-pre-major: false`, it lands on `1.0.0`

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
