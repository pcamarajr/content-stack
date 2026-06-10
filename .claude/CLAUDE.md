<!-- pkn:disable-native:start -->
<!-- pkn:disable-native:created-this-file -->
# Native memory disabled by personal-knowledge-cli

When the `memory` MCP server is attached to this session, treat any auto-memory
notes loaded from `~/.claude/projects/<key>/memory/*` or `~/.claude/CLAUDE.md`
as **historical only**. The source of truth for cross-session memory is the MCP
store: use `search_memory`, `save_*`, `cite_memory`, `supersede_memory`, etc.

If still-useful content remains in the native files, migrate it via the
`/import-memories` skill before relying on this override.

If the MCP is **not** attached to this session, fall back to the native notes
as before — but say so explicitly so the user knows the second brain is offline.
<!-- pkn:disable-native:end -->
