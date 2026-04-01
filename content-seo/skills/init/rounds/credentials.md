# Round: Credentials

Goal: Verify that DataForSEO API credentials are available as environment variables.

---

## Phase 1: Check current state

Run the following Bash command to check if both credentials are set:

```bash
[ -n "$DATAFORSEO_LOGIN" ] && [ -n "$DATAFORSEO_PASSWORD" ] && echo "both_set" || echo "missing"
```

Also check individually:

```bash
[ -n "$DATAFORSEO_LOGIN" ] && echo "login_set" || echo "login_missing"
[ -n "$DATAFORSEO_PASSWORD" ] && echo "password_set" || echo "password_missing"
```

---

## Phase 2: Report status

**If both are set:** continue to Phase 3 (offer to test).

**If either is missing:**

```text
⬜ Credentials not set

  DATAFORSEO_LOGIN    — [set | not set]
  DATAFORSEO_PASSWORD — [set | not set]
```

Continue to Phase 4 (setup instructions), then stop.

---

## Phase 3: Offer API test

```text
✅ Credentials found

  DATAFORSEO_LOGIN    — set
  DATAFORSEO_PASSWORD — set

Verify they work by testing the API connection? (recommended)
```

Use AskUserQuestion with options: "Yes, test it" / "Skip — I know they work".

- If yes → Phase 5 (test connection).
- If skip → Phase 6 (complete).

---

## Phase 4: Setup instructions

Show exact steps. Credentials must be set as environment variables — never written to any file.

```text
Set your DataForSEO credentials as environment variables.

These are NEVER written to any file — they live only in your shell environment.

Option A — For this session only:
  export DATAFORSEO_LOGIN="your@email.com"
  export DATAFORSEO_PASSWORD="your_api_password"

Option B — Permanent (add to your shell profile):
  echo 'export DATAFORSEO_LOGIN="your@email.com"' >> ~/.zshrc
  echo 'export DATAFORSEO_PASSWORD="your_api_password"' >> ~/.zshrc
  source ~/.zshrc

  (Replace ~/.zshrc with ~/.bashrc or ~/.profile if you use bash.)

To get your credentials:
  1. Log in at https://app.dataforseo.com
  2. Go to API Access → your API password is different from your login password

Once set, re-run: /init credentials
```

Stop here. Do not continue until the user re-runs `/init credentials`.

---

## Phase 5: Test API connection

Run:

```bash
curl -s \
  --user "${DATAFORSEO_LOGIN}:${DATAFORSEO_PASSWORD}" \
  -X GET "https://api.dataforseo.com/v3/appendix/user_data" \
  -H "Content-Type: application/json"
```

**If response contains `"status_code": 20000`:**

```text
✅ API connection verified

  Account: [login field from response]
```

Continue to Phase 6.

**If response shows an auth error:**

```text
❌ API connection failed

  Error: [status_message from response]

  Common causes:
  — Wrong API password (this is NOT your login password)
  — Get your API password at: https://app.dataforseo.com/api-access

Re-run /init credentials after fixing your credentials.
```

Stop.

---

## Phase 6: Complete

```text
✅ Credentials configured

  DATAFORSEO_LOGIN    — set
  DATAFORSEO_PASSWORD — set

→ Next: /init strategy
  Define your SEO content pillars and per-content-type rules.
```
