# /astro-builder:init lighthouse

Set up automated Lighthouse performance auditing on `git push` for this Astro project.

---

## Prerequisite check

Before doing anything else, verify that project init has been run:

- Check that the `.astro-builder/` directory exists.
- If it does **not** exist, stop immediately and tell the user:

  ```
  Project init has not been run yet.
  Run `/astro-builder:init` first, then come back to set up Lighthouse.
  ```

Do not proceed past this point until the prerequisite is met.

---

## Phase 1 — Read existing config

Before asking anything, silently scan:

1. Read `.astro-builder/lighthouse.json` if present → extract `thresholds`, `urlMap`, `staticPages`, `port`, `fallbackMaxPages`, `locales`, `categories`.
2. Read `.astro-builder/content-schema.md` → scan for URL pattern lines (e.g. `/{locale}/articles/{slug}`) → pre-populate `urlMap` keyed by collection name inferred from context.
3. Read `astro.config.ts` → extract `i18n.locales` array if present → use as `locales` default.

If `.astro-builder/content-schema.md` has no URL pattern lines, skip pre-population and let the user enter patterns manually during Q2.

---

## Phase 1b — Detection

If `.astro-builder/lighthouse.json` exists with both `thresholds` and `urlMap` keys set:

```
AskUserQuestion:
  question: "Found existing .astro-builder/lighthouse.json:
    Thresholds:  performance=[N], accessibility=[N], best-practices=[N], seo=[N]
    URL map:     [N] patterns
    Port:        [N]

  What would you like to do?"
  header: "Existing config"
  options:
    - "Keep as-is" → stop here; remind user: run `git push` to test the hook
    - "Review and update" → continue with pre-filled values shown during interview
    - "Other — specify overrides" → accept free text describing overrides, apply, then continue
```

---

## Phase 2 — Interview (4 questions, one at a time)

### Q1 — Thresholds

```
AskUserQuestion:
  question: "What minimum Lighthouse score should block a push?"
  header: "Score thresholds"
  options:
    - "90 for all (Recommended)" → perf=90 acc=90 bp=90 seo=90
    - "Strict — 95 for all" → perf=95 acc=95 bp=95 seo=95
    - "Relaxed — 75 for all" → perf=75 acc=75 bp=75 seo=75
    - "Custom — specify per category" → parse free text as perf=N acc=N bp=N seo=N
```

### Q2 — URL map

Show pre-populated patterns discovered from `content-schema.md`, then:

```
AskUserQuestion:
  question: "Confirm URL patterns for mapping changed files to audit URLs.

  I found in .astro-builder/content-schema.md:
    [list each: src/content/<collection>/** → /<locale>/<collection>/{slug}]
    [or: "No patterns found — please enter them manually"]

  Are these correct?"
  header: "URL map"
  options:
    - "Yes — use these patterns"
    - "Edit — I'll update in Other field" → accept JSON patch (e.g. {"src/content/articles/**": "/{locale}/articles/{slug}"})
    - "Enter full map manually" → accept full JSON object
```

After confirming/editing, ask for `staticPages`:

```
AskUserQuestion:
  question: "Which static pages (not driven by content collections) should always be included in fallback audits?
  
  Enter as a comma-separated list or one per line (e.g. /en/, /en/about)."
  header: "Static pages"
  (free text, default "/" if user presses enter)
```

### Q3 — Preview port

```
AskUserQuestion:
  question: "Which port for the Astro preview server during Lighthouse runs?"
  header: "Preview port"
  options:
    - "14321 (Recommended — avoids conflict with pnpm dev on 4321)"
    - "4321 (Astro default)"
    - "Other — specify"
```

### Q4 — Fallback max pages

```
AskUserQuestion:
  question: "When a layout or component change affects all pages, how many pages max should the fallback audit?"
  header: "Fallback cap"
  options:
    - "10 pages (Recommended)"
    - "5 pages (faster)"
    - "All pages (thorough, slow)" → set fallbackMaxPages to a very large number (999)
```

---

## Phase 3 — Dependency check and install

Check silently, then print a status block:

```
Checking prerequisites...
  [✅|⬜] playwright installed
  [✅|⬜] Chromium downloaded
  [✅|⬜] lighthouse installed
  [✅|⬜] jq available (system tool)
  [✅|⬜] Husky configured
```

**playwright**: run `node -e "require('playwright')"` — if it fails, not installed.  
**Chromium**: run `node -e "const { chromium } = require('playwright'); chromium.executablePath()"` — if it fails, not downloaded.  
**lighthouse**: run `pnpm exec lighthouse --version` — if it fails, not installed.  
**jq**: run `command -v jq` — if it fails, not available (system tool, cannot auto-install).  
**Husky**: check `package.json` for `"prepare": "husky"` in scripts.

Install anything missing:

- If playwright or lighthouse missing: `pnpm add -D playwright lighthouse`
- If Chromium not downloaded: `pnpm exec playwright install chromium`
- If jq missing: warn — "Install jq to enable score parsing: `brew install jq` (macOS) or `apt install jq` (Linux). The hook will skip score thresholds without it." Do NOT block setup.
- If Husky not configured:
  1. Add `"prepare": "husky"` to `scripts` in `package.json`
  2. Run `pnpm install` (triggers husky init via the prepare script)
  3. If `.husky/` directory does not exist after install, create it: `mkdir -p .husky`

---

## Phase 4 — Write pre-push hook

> **Why two files?** Husky v9 runs hooks with `sh -e`, ignoring the shebang. The audit
> script uses bash-only syntax (`pipefail`, process substitution, here-strings), so it
> must be executed by bash explicitly. The solution is a thin POSIX sh wrapper in
> `.husky/pre-push` that delegates to a bash script stored in `.astro-builder/`.

1. Read the template at `${CLAUDE_PLUGIN_ROOT}/docs/lighthouse-templates/pre-push.sh`.
2. Substitute all placeholders:
   - `__PORT__` → interview Q3 answer (e.g. `14321`)
   - `__CATEGORIES__` → comma-separated categories from config (default: `performance,accessibility,best-practices,seo`)
   - `__PERF_THRESHOLD__` → interview Q1 performance value
   - `__ACC_THRESHOLD__` → interview Q1 accessibility value
   - `__BP_THRESHOLD__` → interview Q1 best-practices value
   - `__SEO_THRESHOLD__` → interview Q1 seo value
3. Write the substituted script to `.astro-builder/pre-push.sh`.
4. Run `chmod +x .astro-builder/pre-push.sh`.
5. Write the following POSIX sh wrapper to `.husky/pre-push`:
   ```sh
   #!/bin/sh
   exec bash .astro-builder/pre-push.sh "$@"
   ```
6. Run `chmod +x .husky/pre-push`.

---

## Phase 5 — Write config file

Write `.astro-builder/lighthouse.json` with all values from the interview and detection phases:

```json
{
  "thresholds": {
    "performance": 90,
    "accessibility": 90,
    "best-practices": 90,
    "seo": 90
  },
  "categories": ["performance", "accessibility", "best-practices", "seo"],
  "port": 14321,
  "urlMap": {
    "src/content/articles/**": "/{locale}/articles/{slug}"
  },
  "staticPages": ["/en/"],
  "fallbackToAll": true,
  "fallbackMaxPages": 10,
  "locales": ["en"]
}
```

All values are replaced with the actual interview answers and detected locales. Use locales detected from `astro.config.ts` or ask if not found.

Also append `.lighthouseci/` to `.gitignore` if not already present.

---

## Phase 6 — Completion summary

```
✅ Lighthouse CI configured

  Thresholds:   performance=N, accessibility=N, best-practices=N, seo=N
  Categories:   [list]
  Port:         N
  URL map:      N patterns
  Hook:         .husky/pre-push → .astro-builder/pre-push.sh

Created/updated:
  • .astro-builder/lighthouse.json
  • .astro-builder/pre-push.sh  (chmod +x)  ← bash audit script
  • .husky/pre-push              (chmod +x)  ← POSIX sh wrapper (Husky v9 compat)
  • .gitignore       (added .lighthouseci/)
  [• package.json    (added "prepare": "husky")  — if changed]

How it works:
  git push → Husky fires .husky/pre-push (sh) → exec bash .astro-builder/pre-push.sh →
  changed files mapped to URLs → pnpm build → preview on port N →
  Lighthouse audit → scores compared → exit 1 (blocked) or exit 0 (push proceeds)

Test it:
  git add .astro-builder/lighthouse.json .astro-builder/pre-push.sh .husky/pre-push
  git commit -m "chore: add Lighthouse CI pre-push hook"
  git push
```

What's next? Run `/astro-builder:audit` for architecture and i18n checks.
