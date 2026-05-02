# Deepline Plugin (spike)

Local validation spike. Not for distribution.

## What this tests

1. `bin/deepline` is on the Bash tool's PATH after install.
2. `SessionStart` hook fires and writes the CLI shiv into `${CLAUDE_PLUGIN_DATA}/cli/`.
3. Cached shiv survives across sessions; re-fetched only on plugin version bump.
4. Existing per-host auth (`~/.local/deepline/<host>/.env`) is reused — no re-login.

## Install

In a fresh Claude Code session:

```
/plugin marketplace add ~/code/deepline-plugin-spike
/plugin install deepline@deepline
/reload-plugins
```

Open a new session to fire the SessionStart hook.

## Verify

In the new session, ask Claude to run:

```bash
which deepline
deepline --version
deepline auth status
echo "$CLAUDE_PLUGIN_DATA"
ls -la "$CLAUDE_PLUGIN_DATA/cli"
```
