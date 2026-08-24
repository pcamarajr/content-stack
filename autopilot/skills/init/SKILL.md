---
name: init
description: Run /autopilot:init to scaffold a target site repo for the autopilot loop — labels, intention/task issue templates, .autopilot/config.yml, and the executor/gates/metrics GitHub Actions workflows.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Scaffolds the current repo so the autopilot loop can run on it: labels, `.github/ISSUE_TEMPLATE/` forms, `.autopilot/config.yml`, and three GitHub Actions workflows (executor, gates, metrics). Run this **inside the target site repo**, not inside content-stack.

Everything created here is infrastructure. This skill never writes an intention, never applies `intention:approved`, and never pushes to the default branch — it opens a PR like any other change.

---

## Step 0 — Preflight & detection

Run these checks before touching anything. Stop and explain if any hard requirement fails.

1. **Inside a git repo:**
   ```bash
   git rev-parse --is-inside-work-tree
   ```
   If this errors, stop: "Not a git repository. Run `git init` and add a GitHub remote first."

2. **Has a GitHub remote:**
   ```bash
   git remote get-url origin
   ```
   Must succeed and contain `github.com`. If it fails or points elsewhere, stop: "No GitHub remote named `origin` found. Add one (`git remote add origin <url>`) before running init."

3. **`gh` is installed and authenticated:**
   ```bash
   command -v gh && gh auth status
   ```
   If `gh` is missing, stop: "Install the GitHub CLI: https://cli.github.com/". If installed but not authenticated, stop: "Run `gh auth login` first."

4. **Clean working tree** (init is about to create a branch and commit on it):
   ```bash
   git status --porcelain
   ```
   If non-empty, stop: "Working tree has uncommitted changes. Commit or stash them before running init."

5. **Detect the default branch** — this fills `{{DEFAULT_BRANCH}}` everywhere below:
   ```bash
   gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
   ```
   Fall back to `git remote show origin | grep 'HEAD branch' | awk '{print $NF}'` if the `gh` call fails (e.g. rate limit).

6. **Detect existing labels:**
   ```bash
   gh label list --json name --jq '.[].name'
   ```
   Diff against the required set (see Step 2). Record which already exist.

7. **Detect existing files** — file existence depends on which branch you look at: a
   prior run may have committed everything to `autopilot/init` without the PR being
   merged yet, so checking only the current checkout gives false "missing" reports.
   Check the remote scaffold branch first:
   ```bash
   if git ls-remote --exit-code origin autopilot/init >/dev/null 2>&1; then
     git fetch origin autopilot/init
     # detect against the prior run's branch
     git cat-file -e origin/autopilot/init:<path> 2>/dev/null && echo "exists" || echo "missing"
   else
     test -f <path> && echo "exists" || echo "missing"
   fi
   ```
   Run the detection for every target path in the Step 3 table and record which already
   exist. If `origin/autopilot/init` exists, say so in the summary — Step 4 will reuse
   that branch instead of creating a new one.

8. **Report the detection summary** before moving on, e.g.:
   ```text
   Preflight — pcamarajr/lista-de-leitura, default branch: main

   Labels:   7/10 already present — will create: autopilot:content, autopilot:code, autopilot:strategy
   Files:    0/6 already present — will create all 6

   Continuing to the interview.
   ```
   This report is what makes re-runs safe to reason about: nothing here is destructive, and anything already present is skipped later, not recreated.

---

## Step 1 — Interview

Ask one question at a time with `AskUserQuestion`. Use Step 0 detections to skip questions whose answer is already implied (e.g. a config file that already sets `metrics.property`).

### Q1 — GSC property

```
AskUserQuestion:
  question: "What is your Google Search Console property? It fills .autopilot/config.yml's metrics.property, used by the nightly metrics workflow (e.g. sc-domain:example.com)."
  header: "GSC property"
  options:
    - "Enter it now" → free text; store as GSC_PROPERTY
    - "Skip for now" → leave metrics.property empty in the config; add a line to the Step 5 follow-up checklist noting metrics won't run until it's set
```

### Q2 — Build & install commands

```
AskUserQuestion:
  question: "How does this site install dependencies and build?"
  header: "Build & install"
  options:
    - "npm — npm ci / npm run build (default)" → PACKAGE_MANAGER_INSTALL=npm ci, BUILD_COMMAND=npm run build
    - "pnpm — pnpm install --frozen-lockfile / pnpm build" → set accordingly
    - "yarn — yarn install --frozen-lockfile / yarn build" → set accordingly
    - "Other — I'll specify both" → free text for PACKAGE_MANAGER_INSTALL and BUILD_COMMAND
```

### Q3 — Merge policy defaults

Show the v1 default table, then ask:

```
AskUserQuestion:
  question: "Autopilot's merge policy: content and translation PRs auto-merge once gates (build, audit, anti-slop) are green. Code and strategy PRs always wait for a human, even if gates pass. Keep these defaults?"
  header: "Merge policy"
  options:
    - "Keep v1 defaults (recommended)" → merge_policy unchanged: content=auto, translate=auto, code=manual, strategy=manual
    - "Customize — I understand the risk" → ask which of code/strategy to flip to auto; before applying, restate explicitly: "Loosening code or strategy to auto-merge is not recommended for v1 — these PRs can touch site behavior or the autopilot boundary itself with no human in the loop. Proceed anyway?" and require an explicit yes
```

Record the three answers (`GSC_PROPERTY`, `BUILD_COMMAND` + `PACKAGE_MANAGER_INSTALL`, `merge_policy`) — they feed the placeholders in Step 3.

---

## Step 2 — Labels

Create only the labels Step 0 found missing. Colors and descriptions below are fixed — reuse them verbatim so re-runs stay idempotent (a label that already exists with a different color is left alone; this skill never edits an existing label).

| Label | Color | Description |
|---|---|---|
| `intention` | `5319E7` | Pinned goal issue for the autopilot loop |
| `intention:approved` | `0E8A16` | Human-approved — activates task execution under this intention. Only a maintainer applies this. |
| `task` | `1D76DB` | A task sub-issue under an approved intention |
| `autopilot:run` | `FBCA04` | Trigger label — applying it fires the executor |
| `autopilot:blocked` | `B60205` | Executor failed twice (one retry) — needs strategist/human triage |
| `autopilot:done` | `2EA043` | Task completed and its PR merged |
| `autopilot:content` | `C2E0C6` | PR change type: content — eligible for auto-merge under the default policy |
| `autopilot:translate` | `BFD4F2` | PR change type: translation — eligible for auto-merge under the default policy |
| `autopilot:code` | `F9D0C4` | PR change type: code — manual merge under the default policy |
| `autopilot:strategy` | `E99695` | PR change type: strategy — touches .autopilot/, workflows, or gates; manual merge |

For each missing label:
```bash
gh label create "<name>" --color "<color>" --description "<description>"
```
Descriptions must stay ≤100 characters — GitHub's label API rejects longer ones with a 422.
For each label Step 0 already found, print `skipped (already exists): <name>` instead of calling `gh label create`.

### Enable repo auto-merge

The gates workflow's `gh pr merge --squash --auto` requires the repo setting
`allow_auto_merge`. Enable it, then verify — on some plans/repo types the PATCH
returns 200 without actually flipping the setting, so never trust the status code alone:
```bash
gh api -X PATCH repos/{owner}/{repo} -f allow_auto_merge=true
gh api repos/{owner}/{repo} --jq .allow_auto_merge
```
The second command must print `true`. This requires admin on the repo. Note: private
repos on the GitHub Free plan cannot enable this setting at all (the PATCH silently
no-ops) — the gates workflow handles it by falling back to a direct squash merge once
its own gates are green, so this is informational, not blocking. If it 403s OR still
reads `false` after the PATCH, don't stop the run — print it as a manual follow-up
instead (add it to the Step 5 checklist):
```text
[ ] Enable "Allow auto-merge" in repo Settings → General (requires admin) — needed for
    the gates workflow's `gh pr merge --squash --auto` to succeed.
```

---

## Step 3 — Scaffold files from templates

Templates live in the plugin at `${CLAUDE_PLUGIN_ROOT}/docs/init-templates/`. For each row: if Step 0 found the target file missing, read the template, substitute its placeholders, and write the result. If the target already exists, diff it against what you'd generate — identical means skip silently; different means stop and ask the user (`AskUserQuestion`: keep existing / overwrite / show diff) before writing.

| # | Target file | Template | Placeholders |
|---|---|---|---|
| 1 | `.autopilot/config.yml` | `config.yml.template` | `{{GSC_PROPERTY}}`, `{{BUILD_COMMAND}}`, plus the `merge_policy` block written directly from the Q3 answer (not a placeholder — the four values are substituted literally) |
| 2 | `.github/ISSUE_TEMPLATE/intention.yml` | `intention.yml.template` | none |
| 3 | `.github/ISSUE_TEMPLATE/task.yml` | `task.yml.template` | none |
| 4 | `.github/workflows/autopilot-executor.yml` | `autopilot-executor.yml.template` | `{{DEFAULT_BRANCH}}` |
| 5 | `.github/workflows/autopilot-gates.yml` | `autopilot-gates.yml.template` | `{{BUILD_COMMAND}}`, `{{PACKAGE_MANAGER_INSTALL}}`, `{{DEFAULT_BRANCH}}` |
| 6 | `.github/workflows/autopilot-metrics.yml` | `autopilot-metrics.yml.template` | `{{GSC_PROPERTY}}`, `{{DEFAULT_BRANCH}}` |

After writing (or skipping) all six, verify no init placeholder survived in what you actually wrote this run. Init placeholders are `{{UPPER_SNAKE}}` tokens — GitHub Actions' own `${{ ... }}` expressions legitimately contain `{{` and must NOT be flagged:
```bash
grep -rEn '\{\{[A-Z_]+\}\}' .autopilot .github/ISSUE_TEMPLATE .github/workflows 2>/dev/null
```
This must return nothing. If it finds a match, fix the offending file before continuing — do not open a PR with an unfilled template.

---

## Step 4 — Commit and open a PR

Init never pushes to the default branch. Everything lands on `autopilot/init`.

1. Sync and branch — check the REMOTE first, not just the local repo, so a prior run's
   pushed branch is picked up instead of recreated (which would conflict on push):
   ```bash
   git fetch origin "$DEFAULT_BRANCH"
   git checkout "$DEFAULT_BRANCH"
   git pull --ff-only origin "$DEFAULT_BRANCH"

   if git ls-remote --exit-code origin autopilot/init >/dev/null 2>&1; then
     echo "autopilot/init already exists on origin — a prior run got this far."
     EXISTING_PR=$(gh pr list --head autopilot/init --json number,url --jq '.[0].url')
     if [ -n "$EXISTING_PR" ]; then
       echo "Existing PR: $EXISTING_PR"
     fi
     git fetch origin autopilot/init
     git checkout -B autopilot/init origin/autopilot/init
   elif git rev-parse --verify autopilot/init >/dev/null 2>&1; then
     git checkout autopilot/init
   else
     git checkout -b autopilot/init
   fi
   ```
2. Stage only the files this run actually created or updated (never `git add -A`):
   ```bash
   git add .autopilot/config.yml \
     .github/ISSUE_TEMPLATE/intention.yml .github/ISSUE_TEMPLATE/task.yml \
     .github/workflows/autopilot-executor.yml .github/workflows/autopilot-gates.yml .github/workflows/autopilot-metrics.yml
   ```
   (Drop any path that was skipped because it already existed and was left untouched.)
3. Commit:
   ```bash
   git commit -m "chore(autopilot): scaffold autopilot loop"
   ```
4. Push:
   ```bash
   git push -u origin autopilot/init
   ```
5. Open the PR — check first whether one already exists from a prior run:
   ```bash
   gh pr list --head autopilot/init --json number --jq '.[0].number'
   ```
   If a number comes back, the push above already updated it — report the PR URL and stop. Otherwise write the body to a temp file and create it:
   ```bash
   PR_BODY=$(mktemp)
   cat > "$PR_BODY" <<'EOF'
   ## Autopilot scaffold

   This PR sets up the autopilot loop on this repo:
   - Labels: intention, intention:approved, task, autopilot:run, autopilot:blocked, autopilot:done, autopilot:content, autopilot:translate, autopilot:code, autopilot:strategy
   - Issue templates: `.github/ISSUE_TEMPLATE/intention.yml`, `.github/ISSUE_TEMPLATE/task.yml`
   - Config: `.autopilot/config.yml`
   - Workflows: `.github/workflows/autopilot-executor.yml`, `autopilot-gates.yml`, `autopilot-metrics.yml`

   ## Manual follow-up required before the loop can run
   - [ ] Add repo secret `ANTHROPIC_API_KEY` (dedicated, capped workspace recommended — ~$50/mo)
   - [ ] Add repo secret `AUTOPILOT_PAT` — fine-grained PAT scoped to this repo only, with Contents (read/write), Pull requests (read/write), and Issues (read/write) permissions. No admin. Required so executor-opened branches/PRs trigger this workflow (the default `GITHUB_TOKEN` never does). If its owner is a machine account, that account must NOT be able to apply `intention:approved`.
   - [ ] Add repo secret `GSC_SERVICE_ACCOUNT` (optional — only blocks the nightly metrics job, not the executor/gates)
   - [ ] Enable branch protection on the default branch: require a PR before merging, require status checks `path-guard`, `build`, `audit`, `anti-slop`, disallow force pushes:
     ```bash
     gh api --method PUT repos/{owner}/{repo}/branches/<default-branch>/protection \
       -F required_status_checks.strict=true \
       -f 'required_status_checks.contexts[]=path-guard' \
       -f 'required_status_checks.contexts[]=build' \
       -f 'required_status_checks.contexts[]=audit' \
       -f 'required_status_checks.contexts[]=anti-slop' \
       -F enforce_admins=true \
       -F required_pull_request_reviews.required_approving_review_count=0 \
       -F restrictions=null \
       -F allow_force_pushes=false \
       -F allow_deletions=false
     ```
     (replace `<default-branch>` with this repo's default branch)
   - [ ] Write and pin the first intention issue (goal / metric / horizon / constraints)
   - [ ] Apply `intention:approved` to that issue to activate it — a maintainer must do this by hand
   EOF
   gh pr create --base "$DEFAULT_BRANCH" --head autopilot/init \
     --title "chore(autopilot): scaffold autopilot loop" \
     --body-file "$PR_BODY"
   ```

---

## Step 5 — Report

Print the same follow-up checklist that went into the PR body, plus the enforcement reminder:

```text
✅ Autopilot scaffold PR opened: <PR URL>

Before the loop can run:
  [ ] Add repo secret ANTHROPIC_API_KEY — dedicated, capped workspace recommended (~$50/mo)
  [ ] Add repo secret AUTOPILOT_PAT — fine-grained PAT scoped to this repo only, with
      Contents (read/write), Pull requests (read/write), Issues (read/write). No admin.
      Required so executor-opened branches/PRs trigger the gates workflow (the default
      GITHUB_TOKEN never does). If its owner is a machine account, that account must NOT
      be able to apply intention:approved.
  [ ] Add repo secret GSC_SERVICE_ACCOUNT — optional; only the nightly metrics job needs it
  [ ] Enable branch protection on $DEFAULT_BRANCH — require a PR before merging, require
      status checks path-guard/build/audit/anti-slop, disallow force pushes:
        gh api --method PUT repos/{owner}/{repo}/branches/$DEFAULT_BRANCH/protection \
          -F required_status_checks.strict=true \
          -f 'required_status_checks.contexts[]=path-guard' \
          -f 'required_status_checks.contexts[]=build' \
          -f 'required_status_checks.contexts[]=audit' \
          -f 'required_status_checks.contexts[]=anti-slop' \
          -F enforce_admins=true \
          -F required_pull_request_reviews.required_approving_review_count=0 \
          -F restrictions=null \
          -F allow_force_pushes=false \
          -F allow_deletions=false
  [ ] Baseline audit: run /astro-builder:audit on the repo and clear every P0 BEFORE
      activating the loop — the audit gate reviews the whole repo, so any pre-existing
      P0 blocks every task PR, no matter how clean the PR itself is
  [ ] Write and pin the first intention issue (goal / metric / horizon / constraints)
  [ ] Apply intention:approved to that issue — only a maintainer applies this label

Remember: the brain proposes, the control plane enforces. A task never runs without an
approved parent intention, no matter who or what filed it — applying intention:approved
is the one action that turns proposals into work, and this skill never does it for you.
```

---

## Constraints

- Never push to the default branch. Every change from this skill lands on `autopilot/init` and goes through a PR.
- Never overwrite an existing file without asking first. Identical content is skipped silently; different content stops and asks (keep / overwrite / show diff).
- Never create or approve an intention issue. This skill scaffolds infrastructure only — it does not author intentions and it never applies `intention:approved`.
- The executor's machine identity (PAT or GitHub App) must never be granted permission to apply `intention:approved`. That label activates work and is reserved for a human maintainer — do not add it to any token's scope, workflow `permissions:` block, or automation this skill writes.
- Gate enforcement depends on branch protection; without it (see the Step 5 checklist) the path-guard/build/audit/anti-slop boundary is advisory, not enforced — anyone with push access can bypass it. Private repos on the GitHub Free plan cannot enable branch protection at all: acceptable for a single-maintainer private repo where the only writers are the maintainer and the executor PAT, but revisit before adding collaborators or going public.
- Re-running this skill must be safe: always detect what already exists (Step 0) before creating anything, and always report what was skipped, not just what was created.
