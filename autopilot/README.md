# autopilot

Autonomous operation layer for static content sites. You set intention; the system runs
the site — evaluate → propose → execute → gate → merge → report.

> **Status: design-complete, v1 in progress.** The architecture is locked
> (see [`docs/architecture.md`](./docs/architecture.md)); the skills and workflows are
> being built milestone by milestone. Not yet usable end to end.

## How it works

- **Control plane = GitHub.** Intentions are pinned issues (goal / metric / horizon /
  constraints) that you approve with a label. Tasks are sub-issues of approved
  intentions — that traceability chain is the autonomy boundary.
- **Brain:** a scheduled Claude cloud session reads committed metrics and open
  intentions, then files task sub-issues.
- **Hands:** GitHub Actions + `claude-code-action` execute tasks, open PRs, and run
  gates (build, audit, anti-slop).
- **Autonomy boundary as config:** `.autopilot/config.yml` `merge_policy` decides what
  auto-merges on green gates. v1 default: content and translation PRs auto-merge; code
  and strategy changes wait for you.
- **Action library:** `content-ops`, `content-seo`, and `astro-builder` do the actual
  writing, measuring, and building.

## Planned skills

| Skill | Purpose |
| --- | --- |
| `init` | Scaffold a target repo: labels, issue templates, `.autopilot/config.yml`, Actions workflows |

## Requirements

- A GitHub repo for the target site (the control plane)
- `content-ops`, `content-seo`, and `astro-builder` installed on the site
- A Google Search Console service account key in the repo's Actions secrets (for the
  metrics loop)

## Install

```bash
/plugin install autopilot@content-stack
```
