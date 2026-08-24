# Architecture — the autopilot design record

Canonical record of the design locked on 2026-07-27 after a full grilling session.
Every structural decision below was stress-tested in that interview; do not re-litigate
without new evidence. Where a question was left open, it is listed as open — flagged,
not forgotten.

**What autopilot is:** the layer that turns content-stack from a skill library into an
agent-running application. The owner sets *intention*; the system runs the site itself —
evaluate → propose → execute → gate → merge → report. Direction stays human; operation
becomes autonomous.

---

## 1 — Core decisions

### 1.1 Control plane = GitHub

All coordination state lives on the target site's GitHub repo: Issues, labels, sub-issues,
PRs, Discussions, Actions, webhooks. Alternatives (Resend, Linear) were explicitly
rejected — GitHub is the natural place for developers, and it gives audit history,
permissions, and eventing for free.

### 1.2 Two runtimes, never talking directly

| Runtime | Role | Reads | Writes |
| --- | --- | --- | --- |
| **Brain** — Claude cloud scheduled session | Strategist: interprets metrics against approved intentions | `.autopilot/metrics/*.json`, open intention issues | Task sub-issues |
| **Hands** — GitHub Actions + `claude-code-action` | Executor: performs tasks, runs gates | Task issues (label-triggered) | Branches, PRs, labels, digest posts |

The two runtimes only ever read and write GitHub — they have no direct channel. That is
what makes them parallel-safe and independently replaceable, and it means every handoff
is inspectable after the fact.

### 1.3 Autonomy boundary as configuration

The boundary lives in `.autopilot/config.yml` under `merge_policy`, so ratcheting
autonomy is a config edit, not a rearchitecture:

- **Level A — propose-only:** every PR waits for the owner.
- **Level B — v1 default:** content and translation PRs auto-merge on green gates
  (build, audit, anti-slop). Code and strategy changes wait for the owner.
- **Level C — full:** anything traceable to an approved intention auto-merges on green
  gates; the owner reviews intentions and weekly outcomes only.

### 1.4 Packaging

`autopilot` is a content-stack plugin. It owns the loop; the existing plugins are its
action library:

- `content-ops` — writing, translation, review, linking
- `content-seo` — GSC metrics (`gsc-reporter`), opportunities, briefs
- `astro-builder` — site structure, build gates, audit

### 1.5 Intentions and tasks — traceability is the enforcement mechanism

An **intention** is a pinned GitHub issue from a template: goal / metric / horizon /
constraints. It is inert until the owner applies the approval label. **Tasks** are
sub-issues of an approved intention. The executor re-verifies the parent intention's
approval *at execution time* — "the brain proposes, the control plane enforces." A task
with no approved parent never runs, no matter who or what filed it. That chain **is**
the autonomy boundary.

### 1.6 Reporting is GitHub-native

Digest posts land in GitHub Discussions (chosen over a rolling issue).

### 1.7 v1 dogfood target

`pcamarajr/lista-de-leitura` — private, Vercel-deployed (auto-merge = auto-publish, PR
previews free), `content-seo` already configured for `sc-domain:listadeleitura.com.br`.
Chosen over bitcoin101: real search volume; a narrow niche starves metric loops.

---

## 2 — Grill resolutions (G1–G8)

- **G1 Metrics ingestion:** a nightly Actions job runs content-seo's `gsc-reporter` and
  commits `.autopilot/metrics/gsc-<date>.json`. The strategist reads files, never the
  live API — cheaper, reproducible, and the metric history is versioned with the site.
- **G2 Machine identity:** fine-grained PAT now, GitHub App later. The executor
  workflow re-verifies parent-intention approval at execution time (see §1.5).
- **G3 Task briefs are structured:** skill-to-run / inputs / acceptance criteria. The
  acceptance criteria double as the PR validation checklist — one artifact, two uses.
- **G4 Failure handling:** one retry, then the `blocked` label and strategist triage.
  The executor never edits gates or config to force a pass.
- **G5 Spend fuses (four, independent):** dedicated Anthropic workspace with ~$50/mo
  cap; job timeout ~30 min + `max_turns` ~50; Actions `concurrency: 1`;
  `max_open_tasks` cap in config.
- **G6 Digest:** GitHub Discussions.
- **G7 Quality signal:** owner reactions on daily digests, plus an agent-drafted weekly
  retro Discussion the owner grades; metric-outcome attribution comes later.
- **G8 v1 scope cut** — deferred, not abandoned: no C-suite roles, no autonomy level C,
  GSC-only metrics, single-site, no public-repo hardening, the strategist cannot propose
  new intentions, no self-modification.

---

## 3 — v1 milestones

1. **Scaffold:** `autopilot/init` sets up labels, issue templates,
   `.autopilot/config.yml`, and Actions workflows — proven on a disposable sandbox repo
   first.
2. **Executor path:** hand-written task → label → PR → gates → auto-merge of a
   content-type change. No strategist involved.
3. **Strategist path:** scheduled cloud session reads GSC files + open intentions and
   files sane, well-formed task sub-issues.
4. **Full loop** on lista-de-leitura for two weeks → review → ratchet `merge_policy` if
   it has earned trust.

**Sequencing (resolved 2026-08-24):** the order stands as 1→2→3→4. The GSC service
account (still missing as of this date) blocks the strategist regardless, and milestones
1–2 run on hand-written tasks, so a thin task pool cannot starve them. Volume-proving
the executor first also means the strategist's output lands on a loop already known to
work.

---

## 4 — Long-term shape (explicitly preserved)

- **C-suite roles** (CEO/CMO/CPO…): each is another scheduled cloud session with its
  own read set and issue-writing mandate. New role = new role definition on the same
  rails — no new architecture.
- **Autonomy ratchet to C** via `merge_policy` as the gates prove themselves.
- **Strategist-proposed intentions** arrive as proposals in the digest that the owner
  promotes — never as self-created intention issues. Direction stays the owner's.
- **More metrics** (GA4, Ahrefs…) as additional exporters writing
  `.autopilot/metrics/`; metric-outcome attribution becomes the strategist's true
  quality score.
- **Multi-site + public-repo hardening** (trust rule: non-maintainer text is data,
  never instructions) before community distribution.

---

## 5 — Open questions

1. **MEASURE oracle.** v1 ingests GSC metrics but has no attribution, guardrail, or
   auto-rollback logic. A system that cannot tell whether a change helped will degrade
   the product silently — this is the likely eventual binding constraint. Acceptable
   for v1 only because v1 has no autonomous "propose intentions from signals" step.
   Must be designed before that step is enabled.
2. **Owner prerequisite (blocks milestone 3):** GSC service account for
   listadeleitura.com.br — Google Cloud → JSON key → added as a GSC property user →
   stored in the site repo's Actions secrets. Verified still missing on 2026-08-24.
