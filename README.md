# Deepline Plugin for Claude Code

Deepline GTM skills + CLI for [Claude Code](https://code.claude.com), distributed as a single plugin. Works in local Claude Code on your laptop and in Cowork (cloud sandboxes).

## What you get

- **Skills** under the `/deepline:*` namespace — `deepline-gtm`, `deepline-quickstart`, `deepline-feedback`, plus recipe wrappers (`build-tam`, `portfolio-prospecting`, `linkedin-url-lookup`, etc.)
- **CLI** auto-installed on first invocation. The plugin's shim fetches the latest Deepline CLI from `code.deepline.com` and caches it locally — no separate install step.
- **Auth** handled via the standard browser-approval flow. Existing standalone-CLI auth state on your laptop is reused automatically; Cowork sandboxes complete a one-click claim per session.

## Install

```
/plugin marketplace add getaero-io/deepline-plugins
/plugin install deepline@deepline
/reload-plugins
```

Then start a fresh Claude Code session so the `SessionStart` hook fires.

## First use

### On your laptop

```
deepline auth register
```

Opens your browser, you approve, the CLI persists your API key. Subsequent skills and `deepline ...` commands just work.

### In Cowork (or any cloud sandbox)

```
deepline auth register --no-wait     # prints the claim URL
# Click the URL in your browser, approve.
deepline auth wait                    # auto-detects approval, persists key
```

After auth, invoke any skill, e.g. `/deepline:deepline-quickstart`.

## How it works

- `bin/deepline` — POSIX shim. On first run, fetches `https://code.deepline.com/api/v2/cli/python` to `~/.local/share/deepline-plugin/cli/deepline.pyz` and execs it with `DEEPLINE_CONFIG_SCOPE=code-deepline-com` so auth state is shared with any existing standalone install.
- `scripts/ensure-cli.sh` — `SessionStart` hook. Warms the shiv cache eagerly and prepends the plugin's `bin/` to `$PATH` via `$CLAUDE_ENV_FILE` so the shim wins over any older `~/.local/bin/deepline` from a previous standalone install.
- `skills/` — vendored at publish time from the upstream skill source in [`deepline-api`](https://github.com/getaero-io/deepline-api).

The Python shiv binary is **not** committed to this repo — it's fetched fresh per CLI release from `code.deepline.com`. Plugin version bumps invalidate the local cache so users automatically get the matching CLI.

## License

MIT
