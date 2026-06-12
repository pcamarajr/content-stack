---
name: version-plugin
description: This skill should be used when the user asks to "version a plugin", "register a new plugin", "add a plugin to the marketplace", "update plugin version", "bump the version", "release a new version of a plugin", or runs "/version-plugin". Registers new plugins (marketplace.json, release-please config/manifest, READMEs). Version bumps for existing plugins are automated by release-please — this skill explains the flow instead of bumping manually.
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write, AskUserQuestion
---

You are running the `version-plugin` skill. Correctly register a plugin in this marketplace, update all registries, and ensure documentation is in sync.

---

## Step 1 — Determine the operation

Ask (or infer from context):

> Is this a **new plugin** being added to the marketplace, or an **update** to an existing plugin?

- **New plugin** → go to [New plugin flow](#new-plugin-flow)
- **Update** → go to [Update flow](#update-flow)

> **Versioning is automated.** Releases are cut by release-please from conventional commits (squash-merge PR titles). Never bump a `version` field by hand — for updates, the job of this skill is to make sure the PR title has the right type/scope and the docs are in sync.

---

## New plugin flow

### 1.1 Confirm the plugin directory exists

Check that the plugin folder exists under the repo root and contains at minimum a `README.md`. If not, stop and tell the user to create the plugin first.

### 1.2 Set version to `1.0.0`

New plugins always start at `1.0.0`. This is the only time a version is written by hand — from here on, release-please owns it.

### 1.3 Collect metadata

If not already clear from context, ask for:

- **name** — lowercase, hyphenated (e.g. `my-plugin`)
- **description** — one sentence, what it does and who it's for
- **category** — one of: `content`, `development`, `productivity`, `design`
- **author.name** — defaults to `pcamarajr`

### 1.4 Register in `.claude-plugin/marketplace.json`

Add a new entry to the `plugins` array:

```json
{
  "name": "<name>",
  "description": "<description>",
  "version": "1.0.0",
  "author": {
    "name": "<author>"
  },
  "source": "./<name>",
  "category": "<category>"
}
```

### 1.5 Scaffold `.claude-plugin/plugin.json` if missing

Check for `<plugin-name>/.claude-plugin/plugin.json`. If absent, create the directory and file:

```json
{
  "name": "<name>",
  "description": "<description>",
  "author": {
    "name": "<author>"
  },
  "repository": "https://github.com/pcamarajr/content-stack",
  "license": "MIT"
}
```

Do not add a `version` field — version lives exclusively in `marketplace.json`.

### 1.6 Update root `README.md`

Add a new plugin section following the existing pattern:

````markdown
### [plugin-name](./plugin-name/README.md)

<description>

**Skills:** skill-a, skill-b  (omit if none)
**Agents:** agent-a, agent-b  (omit if none)

To install this plugin:

```bash
/plugin install plugin-name@content-stack
```
````

Scan the existing plugin sections and insert the new one in alphabetical order by plugin name.

### 1.7 Scaffold plugin `README.md` if missing or minimal

If the plugin has no README or a placeholder, generate a minimal README:

````markdown
# <plugin-name>

<description>

Part of the [content-stack](https://github.com/pcamarajr/content-stack) marketplace.

---

## Install

```shell
/plugin install <plugin-name>@content-stack
```

---

## Skills

| Skill | Description |
| ------- | ------------- |
| `/<skill>` | ... |

---

## License

MIT
````

### 1.8 Register in release-please

Add the plugin to both release automation files:

- `release-please-config.json` — new entry under `packages`, keyed by the plugin directory, following the existing pattern (`release-type: simple` + the `extra-files` jsonpath entry targeting the plugin's `version` in `/.claude-plugin/marketplace.json`)
- `.release-please-manifest.json` — `"<plugin-name>": "1.0.0"`

Also add the plugin name to the `scopes` list in `.github/workflows/lint-pr-title.yml`.

### 1.9 Commit the changes

Stage and commit all modified files:

```
feat(<plugin-name>): register <plugin-name> in marketplace
```

The `feat` type matters — it makes release-please cut the plugin's first release (the manifest anchors it at `1.0.0`).

### 1.10 Confirm and summarize

Show the user what was changed:

- Entry added to `marketplace.json`
- Entries added to `release-please-config.json`, `.release-please-manifest.json`, and the PR-title lint scopes
- `plugin.json` created (if applicable)
- Section added to root `README.md`
- Plugin `README.md` created or updated (if applicable)

---

## Update flow

Versions are bumped by **release-please** — never by hand. The squash-merged PR title is the conventional commit it reads:

| PR title | Effect on the scoped plugin |
| --- | --- |
| `fix(<plugin>): ...` | **patch** |
| `feat(<plugin>): ...` | **minor** (0.x plugins also bump minor on feat) |
| `feat(<plugin>)!: ...` or `BREAKING CHANGE:` footer | **major** |
| `chore`/`docs`/`refactor`/`ci` | no release |

release-please attributes commits to plugins by the files touched; the scope in the title is for humans and the changelog. After merge, it opens/updates a release PR per plugin — merging that PR updates `marketplace.json`, the plugin's `CHANGELOG.md`/`version.txt`, and cuts the tag (`<plugin>-v<version>`) and GitHub Release.

What this skill still does on updates:

### 2.1 Check the PR title

Confirm the PR title is a conventional commit with the right type for the intended bump (table above). A refactor that users will perceive as a feature should be titled `feat(...)`.

### 2.2 Update plugin `README.md` if needed

If skills or agents were added/removed, update the skills/agents table in the plugin's README.

### 2.3 Update root `README.md` if needed

If the plugin's description, skills list, or agents list changed, update the corresponding section in the root `README.md`.

---

## Rules

- Never bump a `version` field by hand — that's release-please's job (the only exception is registering a new plugin at `1.0.0`)
- Never skip semver components (e.g. `1.0` is not valid — use `1.0.0`)
- Version lives exclusively in `marketplace.json` — do not add or update `version` in `plugin.json`
- Always read the current state of `marketplace.json` before making changes
