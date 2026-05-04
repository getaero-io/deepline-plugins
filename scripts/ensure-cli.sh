#!/usr/bin/env bash
# TEST BRANCH: shiv is bundled in the repo, so this hook only handles PATH
# wiring and the auth nudge. No fetch.
set -e

# Prepend plugin bin/ to PATH so our shim wins over any pre-existing standalone
# install of `deepline` that may live in ~/.local/bin or similar.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${CLAUDE_PLUGIN_ROOT%/}/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

BUNDLED_SHIV="${CLAUDE_PLUGIN_ROOT%/}/vendor/deepline.pyz"
if [ ! -x "$BUNDLED_SHIV" ]; then
  printf '\033[33m[deepline]\033[0m Bundled shiv missing at %s\n' "$BUNDLED_SHIV" >&2
  exit 0
fi

# Auth nudge — runs the bundled shiv without invoking PATH-resolved binary.
if ! DEEPLINE_SKIP_SELF_UPDATE=1 DEEPLINE_SKIP_SKILLS_SYNC=1 "$BUNDLED_SHIV" auth status --json 2>/dev/null | grep -q '"authenticated"[[:space:]]*:[[:space:]]*true'; then
  printf '\033[36m[deepline]\033[0m Run \033[1mdeepline auth register --no-wait\033[0m to start auth.\n' >&2
fi

exit 0
