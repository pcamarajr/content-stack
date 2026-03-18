---
name: cost-tracker:report
description: Show token usage and estimated API cost for this project. Reads .cost-log/sessions.jsonl and presents a summary.
argument-hint: ""
user-invocable: true
allowed-tools: Bash
---

Run the cost report script and present the results to the user.

1. Execute: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/report.sh"`
2. Present the output conversationally — highlight totals, model breakdown, daily trend, and cache savings
3. Offer to analyse trends or answer questions if the user wants
