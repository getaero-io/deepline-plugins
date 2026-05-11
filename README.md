# Deepline Plugin

Deepline adds GTM skills and the `deepline` CLI to Claude Cowork and Claude Code.

Use it to build prospect lists, enrich CSVs, research accounts, write outbound, and run Deepline workflows from the same Claude session where you are working.

## What You Get

- Deepline skills under the `/deepline:*` namespace, including `/deepline:deepline-gtm`, `/deepline:deepline-quickstart`, and `/deepline:deepline-feedback`.
- A `deepline` command on Claude's tool `PATH`.
- Automatic CLI bootstrap on first use. The plugin shim runs the standard Deepline installer from `https://code.deepline.com/api/v2/cli/install`, then delegates to the installed CLI.
- Shared auth behavior across environments. Local Claude Code can reuse your existing Deepline CLI auth; Cowork can restore auth from the workspace `.deepline/.env` file or guide you through browser approval.

## Install In Claude Cowork

Cowork installs plugins through the Claude Desktop app. This is the recommended path if you use Cowork cloud sandboxes.

1. Download a Deepline plugin ZIP. Use a release asset if one was shared with you, or create one from this repository.
2. Open Claude Desktop and switch to **Cowork**.
3. Open **Customize** in the left sidebar.
4. Choose **Browse plugins**.
5. Upload the Deepline plugin ZIP as a custom plugin.
6. Start a new Cowork task and type `/` to confirm the Deepline skills appear.

After install, ask Cowork to run:

```bash
command -v deepline
deepline --version
deepline auth status
```

The first `deepline` command may install the canonical CLI into the sandbox. That is expected.

### Creating A ZIP From This Repository

If you are testing from a local checkout, create the upload ZIP from the repository root:

```bash
zip -qr ../deepline-plugin.zip . -x '.git/*'
```

The ZIP must contain `.claude-plugin/plugin.json`, `bin/deepline`, and `skills/` at the archive root. Do not zip a parent folder that contains the plugin folder; Cowork expects the plugin files themselves at the top level of the archive.

## Install In Claude Code

Claude Code installs this plugin from the GitHub marketplace in this repository.

Inside Claude Code, run:

```text
/plugin marketplace add getaero-io/deepline-plugins
/plugin install deepline@deepline
/reload-plugins
```

Then verify:

```bash
command -v deepline
deepline --version
deepline auth status
```

If you installed from a local checkout while developing, use Claude Code's local path support instead:

```text
/plugin marketplace add /absolute/path/to/deepline-plugins/.claude-plugin/marketplace.json
/plugin install deepline@deepline
/reload-plugins
```

## Authenticate

### Claude Code On Your Laptop

If you already use the standalone Deepline CLI, the plugin should reuse that auth state.

If you need to log in:

```bash
deepline auth register
```

Approve the browser page that opens, then run:

```bash
deepline auth status
```

### Cowork

Cowork runs commands in a cloud sandbox, so browser auth is a two-step flow:

```bash
deepline auth register --no-wait
```

Open the printed approval URL in your browser, approve it, then run:

```bash
deepline auth wait --timeout 120
deepline auth status
```

If the workspace already has `.deepline/.env` with `DEEPLINE_API_KEY`, the plugin shim reads it before invoking the CLI. When Cowork completes auth successfully, the CLI writes the current key back to that workspace file so later sandbox commands can reuse it.

## Try It

Run the quickstart skill:

```text
/deepline:deepline-quickstart
```

Or test the CLI directly:

```bash
deepline tools execute run_javascript \
  --payload '{"code":"return {ok:true,message:\"deepline works\",value:42};"}' \
  --json
```

For CSV enrichment, ask Claude to use `/deepline:deepline-gtm` with a CSV path and the fields you want filled.

## How It Works

- `bin/deepline` is a small POSIX shim. Claude Code and Cowork add plugin `bin/` directories to tool `PATH`, so `deepline ...` works before the real CLI is installed.
- On first invocation, the shim runs the canonical Deepline installer.
- The installer skips duplicate agent-skill installation while running from the plugin, because the plugin already provides skills.
- `skills/` is vendored from Deepline's upstream skill sources.

## Troubleshooting

### `deepline: installing CLI...`

Expected on first use in a fresh environment. Re-run your original command after install if Claude stopped early.

### `deepline: failed to install CLI`

Check network access from the environment:

```bash
curl -I https://code.deepline.com/api/v2/cli/install
```

If you are testing a development backend, make sure the plugin ZIP was built with the correct public tunnel URL.

### Skills Do Not Appear

In Claude Code, run:

```text
/reload-plugins
```

In Cowork, start a new task after installing the plugin and type `/` to open the skill picker.

### Auth Error

Run:

```bash
deepline auth status
```

If the key is stale, run the auth flow again. In Cowork, prefer `deepline auth register --no-wait` followed by `deepline auth wait --timeout 120`.

## References

- [Claude Code plugin docs](https://code.claude.com/docs/en/discover-plugins)
- [Create plugins for Claude Code](https://code.claude.com/docs/en/plugins)
- [Use plugins in Claude Cowork](https://support.claude.com/en/articles/13837440-use-plugins-in-claude-cowork)

## License

MIT
