# Changelog

## Unreleased

- Plugin packaging is now skills-only. Each shipped `SKILL.md` includes the npm CLI install, auth, and skill refresh commands.
- Removed the plugin `bin/deepline` bootstrap shim from the assembled Cowork/Claude Code plugin artifact.

## 1.0.0 — 2026-05-04

Initial public release.

- Ships the Deepline GTM skill set (`deepline-gtm`, `deepline-quickstart`, `deepline-feedback`, plus recipe wrappers) under the `/deepline:*` namespace.
- Self-healing CLI shim at `bin/deepline` — invokes the canonical Deepline installer from `https://code.deepline.com/api/v2/cli/install` on first invocation, then delegates to the installed CLI at `~/.local/bin/deepline`.
- Plugin bootstrap skips shell profile edits, quickstart launch, auth bootstrap, and duplicate agent skill installation because Claude Code owns plugin PATH wiring and already loaded the shipped skills.
- Plugin bootstrap delegates auth persistence to the SDK CLI. Project/org auth lives in `.env.deepline`; in Cowork-style cloud sandboxes, `deepline org set <org>` uses auth-scope `auto` to write that file to the mounted project folder when one is detected.

### Companion CLI changes (deepline-api)

- New `deepline auth wait [--timeout SECONDS]` subcommand — completes the claim flow in cloud sandboxes after `deepline auth register --no-wait` + browser approval, without an inline curl/python redeem block.
- Context-aware auth-failure messages — when a `DEEPLINE_CLAIM_TOKEN` is pending, the CLI directs users at `auth wait` instead of redundantly suggesting `auth register`.
- Cleaner claim URLs — server-side trailing-slash bug fixed in `/api/v2/auth/cli/register`.
