# Changelog

## 1.0.0 — 2026-05-04

Initial public release.

- Ships the Deepline GTM skill set (`deepline-gtm`, `deepline-quickstart`, `deepline-feedback`, plus recipe wrappers) under the `/deepline:*` namespace.
- Self-healing CLI shim at `bin/deepline` — invokes the canonical Deepline installer from `https://code.deepline.com/api/v2/cli/install` on first invocation, then delegates to the installed CLI at `~/.local/bin/deepline`.
- Plugin bootstrap skips shell profile edits, quickstart launch, auth bootstrap, and duplicate agent skill installation because Claude Code owns plugin PATH wiring and already loaded the shipped skills.
- Optional cross-session auth persistence in Cowork-style cloud sandboxes: the shim reads `${CLAUDE_PROJECT_DIR}/.deepline/.env` or the discovered workspace `.deepline/.env` as data, never as shell, so users with a connected workspace can persist `DEEPLINE_API_KEY` across sandbox teardowns.

### Companion CLI changes (deepline-api)

- New `deepline auth wait [--timeout SECONDS]` subcommand — completes the claim flow in cloud sandboxes after `deepline auth register --no-wait` + browser approval, without an inline curl/python redeem block.
- Context-aware auth-failure messages — when a `DEEPLINE_CLAIM_TOKEN` is pending, the CLI directs users at `auth wait` instead of redundantly suggesting `auth register`.
- Cleaner claim URLs — server-side trailing-slash bug fixed in `/api/v2/auth/cli/register`.
