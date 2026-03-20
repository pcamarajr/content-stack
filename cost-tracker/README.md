# cost-tracker

Track Claude Code token usage and estimated API cost per session. Logs are scoped to your project and stored in `.cost-log/`.

## What it does

- Fires a `SessionStart` hook to capture the session transcript path for live tracking
- Shows a live running cost in the Claude Code status bar as the session progresses
- Fires a `Stop` hook after every session ends — appends a record to `.cost-log/sessions.jsonl` and shows a notification:

```
[cost-tracker] Session: ~$0.0432 | 30d total: ~$1.24
```

- When no session is active, the status bar shows the 30-day accumulated project total

## Installation

Add `cost-tracker` to your project's `.claude/settings.json` plugins list or install via the marketplace:

```bash
claude plugin install cost-tracker
```

## Log location

```
<your-project>/
└── .cost-log/
    └── sessions.jsonl    ← one JSON record per session
```

Each record looks like:

```json
{
  "session_id": "abc123",
  "timestamp": "2026-03-18T14:22:00Z",
  "model": "claude-sonnet-4-6",
  "input_tokens": 12000,
  "output_tokens": 800,
  "cache_write_tokens": 3000,
  "cache_read_tokens": 45000,
  "cost_usd": 0.04320,
  "pricing": "standard"
}
```

`pricing` is `"standard"` when the model was recognized, `"estimated"` when it fell back to Sonnet rates.

Add `.cost-log/` to your `.gitignore` if you don't want to commit session logs.

## On-demand report

Run `/cost-tracker:report` in any Claude Code session to see:

- All-time total cost and session count
- Last 30 days total
- Per-model breakdown
- Daily spend for the last 7 days
- Cache hit rate and estimated savings vs. no cache

## Limitations

- **Web sessions not tracked.** `claude.ai` sessions do not expose a transcript to hooks.
- **Estimates, not billing.** Costs are calculated from public API pricing and will differ from your actual Anthropic invoice, especially if you have a subscription or custom pricing.
- **Haiku 4 pricing is a placeholder.** The Haiku 4 rate in the pricing table is based on Haiku 3.5 rates — update `post-session-cost.sh` when Anthropic publishes official Haiku 4 pricing.
- **No budget enforcement.** This plugin is observability-only and never blocks sessions.

## Pricing table

| Model | Input | Output | Cache write | Cache read |
|---|---|---|---|---|
| claude-opus-4-* | $15.00/M | $75.00/M | $18.75/M | $1.50/M |
| claude-sonnet-4-* | $3.00/M | $15.00/M | $3.75/M | $0.30/M |
| claude-haiku-4-* | $0.80/M | $4.00/M | $1.00/M | $0.08/M |
| Unknown / fallback | $3.00/M | $15.00/M | $3.75/M | $0.30/M |

To update rates, edit the pricing section in `hooks-handlers/post-session-cost.sh`.
