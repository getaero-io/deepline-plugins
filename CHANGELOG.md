# Changelog

## 1.0.0 — 2026-05-04

Initial public release.

- Ships the Deepline GTM skill set (`deepline-gtm`, `deepline-quickstart`, `deepline-feedback`, plus recipe wrappers) under the `/deepline:*` namespace.
- Self-healing CLI shim at `bin/deepline` — fetches the latest Deepline CLI Python shiv from `https://code.deepline.com/api/v2/cli/python` on first invocation, caches it at `~/.local/share/deepline-plugin/cli/deepline.pyz`, then `exec`s it with the same env wiring (`DEEPLINE_API_BASE_URL`, `DEEPLINE_CONFIG_SCOPE`, `DEEPLINE_INSTALL_METHOD`) as the standalone bash installer. Auth state is shared with the standalone CLI on machines that have both.
- `SessionStart` hook (`scripts/ensure-cli.sh`) that warms the shiv cache eagerly and prepends the plugin's `bin/` to `$PATH` via `$CLAUDE_ENV_FILE` so the plugin shim wins over any pre-existing standalone install inside Claude Code's Bash tool.
- Optional cross-session auth persistence in cloud sandboxes: the shim sources `${CLAUDE_PROJECT_DIR}/.deepline/.env` if present, so users with a connected workspace can persist `DEEPLINE_API_KEY` across Cowork sandbox teardowns.

### Companion CLI changes (deepline-api)

- New `deepline auth wait [--timeout SECONDS]` subcommand — completes the claim flow in cloud sandboxes after `deepline auth register --no-wait` + browser approval, without an inline curl/python redeem block.
- Context-aware auth-failure messages — when a `DEEPLINE_CLAIM_TOKEN` is pending, the CLI directs users at `auth wait` instead of redundantly suggesting `auth register`.
- Cleaner claim URLs — server-side trailing-slash bug fixed in `/api/v2/auth/cli/register`.
