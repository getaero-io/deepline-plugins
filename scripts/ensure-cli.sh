#!/usr/bin/env bash
# TEST BRANCH: SessionStart hook fetches the test shiv from the ngrok-tunneled
# dev server eagerly so first invocation is fast.
set -e

CACHE_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/deepline-plugin"
CACHE_DIR="$CACHE_ROOT/cli"
SHIV="$CACHE_DIR/deepline.pyz"

SHIV_FETCH_URL="${DEEPLINE_TEST_SHIV_URL:-https://6ead-136-36-246-228.ngrok-free.app/deepline.pyz}"

mkdir -p "$CACHE_DIR"

# Prepend plugin bin/ to PATH so our shim wins.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${CLAUDE_PLUGIN_ROOT%/}/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Always re-fetch on session start in test mode — fast iteration.
printf '\033[36m[deepline-test]\033[0m Fetching test shiv from %s\n' "$SHIV_FETCH_URL" >&2
TMP="$(mktemp "${TMPDIR:-/tmp}/deepline-shiv.XXXXXX")"
if curl -fsSL "$SHIV_FETCH_URL" -o "$TMP"; then
  chmod +x "$TMP"
  mv "$TMP" "$SHIV"
  printf '\033[32m[deepline-test]\033[0m CLI ready at %s\n' "$SHIV" >&2
else
  rm -f "$TMP"
  printf '\033[33m[deepline-test]\033[0m Failed to fetch test shiv from %s\n' "$SHIV_FETCH_URL" >&2
  exit 0
fi

exit 0
