---
name: version-plugin
description: This skill should be used when the user asks to "version a plugin", "register a new plugin", "add a plugin to the marketplace", "update plugin version", "bump the version", "release a new version of a plugin", or runs "/version-plugin". Guides the semver decision, updates marketplace.json, scaffolds plugin.json if missing, syncs the root README, and scaffolds the plugin README if new.
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write, AskUserQuestion
---

You are running the `version-plugin` skill. Correctly version a plugin in this marketplace, update all registries, and ensure documentation is in sync.

---

## Step 1 — Determine the operation

Ask (or infer from context):

> Is this a **new plugin** being added to the marketplace, or an **update** to an existing plugin?

- **New plugin** → go to [New plugin flow](#new-plugin-flow)
- **Update** → go to [Update flow](#update-flow)

---

## New plugin flow

### 1.1 Confirm the plugin directory exists

Check that the plugin folder exists under the repo root and contains at minimum a `README.md`. If not, stop and tell the user to create the plugin first.

### 1.2 Set version to `1.0.0`

New plugins always start at `1.0.0`.

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

### 1.8 Commit the changes

Stage and commit all modified files:

```
chore: register <plugin-name>@1.0.0 in marketplace
```

### 1.9 Confirm and summarize

Show the user what was changed:

- Entry added to `marketplace.json`
- `plugin.json` created (if applicable)
- Section added to root `README.md`
- Plugin `README.md` created or updated (if applicable)

---

## Update flow

### 2.1 Identify the plugin

Ask which plugin is being updated, or infer from the current working context.

### 2.2 Read the current version

Read `.claude-plugin/marketplace.json` and find the plugin's current `version`.

### 2.3 Determine the version bump

Ask the user to describe what changed, then apply these rules:

| Change type | Bump |
| --- | --- |
| Bug fix, wording correction, documentation update, skill text tweak | **patch** (x.x.N) |
| New skill, new agent, new hook, new command, new optional feature | **minor** (x.N.0) |
| Breaking config change, removed/renamed skill or agent, architecture overhaul | **major** (N.0.0) |

If unsure, ask: _"Is this a fix, a new feature, or a breaking change?"_

Show the proposed new version and ask for confirmation before proceeding.

### 2.4 Update `.claude-plugin/marketplace.json`

Update the `version` field for the plugin to the new version.

### 2.5 Update plugin `README.md` if needed

If skills or agents were added/removed, update the skills/agents table in the plugin's README.

### 2.6 Update root `README.md` if needed

If the plugin's description, skills list, or agents list changed, update the corresponding section in the root `README.md`.

### 2.7 Commit the changes

Stage and commit all modified files:

```
chore: bump <plugin-name> to <new-version>
```

### 2.8 Suggest a git tag

For `minor` and `major` bumps, suggest creating a git tag:

```bash
git tag <plugin-name>@<new-version>
```

Ask if the user wants to create it now.

### 2.9 Confirm and summarize

Show the user exactly what was changed.

---

## Rules

- Never downgrade a version
- Never skip semver components (e.g. `1.0` is not valid — use `1.0.0`)
- Version lives exclusively in `marketplace.json` — do not add or update `version` in `plugin.json`
- Always read the current state of `marketplace.json` before making changes
