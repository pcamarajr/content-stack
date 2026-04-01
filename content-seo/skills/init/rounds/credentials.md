# Round: Credentials

Goal: Verify that credentials for GSC and DataForSEO are accessible and working.

---

## Phase 1: Check GSC credentials

Read `.content-seo/config.md` to get `gsc_credentials_path` (if set).

Check credentials in this order:

```bash
# Check config-specified path
[ -n "[gsc_credentials_path]" ] && [ -f "[gsc_credentials_path]" ] && echo "config_path_ok" || echo "config_path_missing"

# Check env var
[ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ] && echo "env_ok" || echo "env_missing"
```

**Determine GSC credential status:**

- `config_path_ok` → credentials resolved from config path ✅
- `env_ok` (and config path not set or missing) → credentials resolved from env var ✅
- Both missing → show setup instructions (Phase 2a)

---

## Phase 2a: GSC setup instructions (if credentials missing)

```text
⬜ GSC credentials not found

  gsc_credentials_path in config — [set and file exists | not set | file not found]
  GOOGLE_APPLICATION_CREDENTIALS  — [set and file exists | not set | file not found]

To set up GSC access:

1. Go to Google Cloud Console → IAM & Admin → Service Accounts
2. Create a new service account (e.g., "content-seo-reader")
3. Grant it no project roles — it only needs GSC access, not GCP
4. Create a JSON key: Actions → Manage keys → Add key → Create new key → JSON
5. Save the downloaded JSON file to a secure location outside your repo
   (e.g., ~/.secrets/gsc-sa.json)
6. In Google Search Console → your property → Settings → Users and permissions
   → Add user → paste the service account email (ends in @...iam.gserviceaccount.com)
   → Set permission: Full or Restricted (read-only is enough)

Then either:
  A — Add to .content-seo/config.md:
      gsc_credentials_path: "/path/to/sa.json"
  B — Set environment variable:
      export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa.json"

Re-run: /seo init credentials
```

Stop here. Do not continue until the user re-runs `/seo init credentials`.

---

## Phase 2b: Offer GSC test (if credentials found)

```text
✅ GSC credentials found

  Source: [config path: /path/to/sa.json | GOOGLE_APPLICATION_CREDENTIALS]

Verify they can access your GSC property? (recommended)
```

Use AskUserQuestion with options: "Yes, test it" / "Skip — I know they work".

- If yes → Phase 3 (test GSC connection).
- If skip → Phase 4 (check DataForSEO).

---

## Phase 3: Test GSC connection

Spawn the `gsc-reporter` agent with a minimal site-wide query:

```text
Use the gsc-reporter agent.

gsc_property: [from .content-seo/config.md]
credentials_path: [gsc_credentials_path from config, or "" to use env var]
query_type: site-wide
date_range: last_7_days
dimensions: page
include_comparison: false
```

**If the agent returns data or an empty result with no error:**

```text
✅ GSC connection verified

  Property: [gsc_property]
  [If data returned: "Last 7 days: [total_clicks] clicks, [total_impressions] impressions"]
  [If no data: "No data returned yet — the property may be new or have no recent traffic."]
```

**If the agent returns an authentication or property error:**

```text
❌ GSC connection failed

  Error: [error message from agent]

  Common causes:
  — Service account email not added to GSC property users
  — Wrong property URL (check /seo init project to update it)
  — Service account JSON key has been revoked or deleted

Re-run /seo init credentials after fixing the issue.
```

Stop on error.

---

## Phase 4: Check DataForSEO credentials

Run:

```bash
[ -n "$DATAFORSEO_LOGIN" ] && echo "login_set" || echo "login_missing"
[ -n "$DATAFORSEO_PASSWORD" ] && echo "password_set" || echo "password_missing"
```

**If both are set:** offer to test (Phase 5).

**If either is missing:**

```text
⬜ DataForSEO credentials not set

  DATAFORSEO_LOGIN    — [set | not set]
  DATAFORSEO_PASSWORD — [set | not set]

DataForSEO is used only for /seo brief (keyword discovery before writing).
If you don't plan to use /seo brief, you can skip this.

To set credentials:
  export DATAFORSEO_LOGIN="your@email.com"
  export DATAFORSEO_PASSWORD="your_api_password"

  Or add permanently to ~/.zshrc (or ~/.bashrc).
  Get your API password at: https://app.dataforseo.com/api-access
  (The API password is different from your login password.)
```

Ask: "Continue without DataForSEO?" with options: "Yes, skip" / "I'll set them now — re-run after".

- If yes → Phase 6 (complete, note DataForSEO not configured).
- If "re-run after" → stop.

---

## Phase 5: Test DataForSEO connection

```bash
curl -s \
  --user "${DATAFORSEO_LOGIN}:${DATAFORSEO_PASSWORD}" \
  -X GET "https://api.dataforseo.com/v3/appendix/user_data" \
  -H "Content-Type: application/json"
```

**If response contains `"status_code": 20000`:**

```text
✅ DataForSEO connection verified

  Account: [login from response]
```

Continue to Phase 6.

**If auth error:**

```text
❌ DataForSEO connection failed

  Error: [status_message from response]

  Common cause: the API password is NOT your login password.
  Get it at: https://app.dataforseo.com/api-access

Re-run /seo init credentials after fixing your credentials.
```

Stop.

---

## Phase 6: Complete

```text
✅ Credentials configured

  GSC:          ✅ [source: config path or env var]
  DataForSEO:   [✅ verified | ⬜ not configured — /seo brief will be unavailable]

→ Next: /seo init strategy
  Define per-content-type SEO rules.
```
