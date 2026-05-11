# Deepline Plugin for Claude Code

Deepline GTM skills + CLI for [Claude Code](https://code.claude.com), distributed as a single plugin. Works in local Claude Code on your laptop and in Cowork (cloud sandboxes).

## What you get

- **Skills** under the `/deepline:*` namespace — `deepline-gtm`, `deepline-quickstart`, `deepline-feedback`, plus recipe wrappers (`build-tam`, `portfolio-prospecting`, `linkedin-url-lookup`, etc.)
- **CLI** auto-installed on first invocation. The plugin's shim runs the standard Deepline installer from `code.deepline.com`, then delegates to the installed CLI — no separate install step.
- **Auth** handled via the standard browser-approval flow. Existing standalone-CLI auth state on your laptop is reused automatically; Cowork sandboxes complete a one-click claim per session.

## Install

```
/plugin marketplace add getaero-io/deepline-plugins
/plugin install deepline@deepline
/reload-plugins
```

After reload, Claude Code exposes the plugin's `bin/` directory to tool calls. The first `deepline ...` command bootstraps the canonical CLI automatically.

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

- `bin/deepline` — POSIX shim. On first run, invokes `https://code.deepline.com/api/v2/cli/install` with plugin-safe installer flags, then execs the canonical CLI at `~/.local/bin/deepline`.
- `skills/` — vendored at publish time from the upstream skill source in [`deepline-api`](https://github.com/getaero-io/deepline-api).

Plugin bootstrap skips shell profile edits, auth bootstrap, quickstart launch, and agent skill installation because Claude Code already loaded the plugin skills and owns plugin PATH wiring.

## License

MIT
