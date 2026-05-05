#!/usr/bin/env bash
# SessionStart hook: ensure the Deepline CLI shiv is cached, prepend the
# plugin's bin/ to PATH so our shim wins over any pre-existing standalone
# install.
set -e

CACHE_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/deepline-plugin"
CACHE_DIR="$CACHE_ROOT/cli"
SHIV="$CACHE_DIR/deepline.pyz"

SHIV_FETCH_URL="${DEEPLINE_CLI_FETCH_URL:-https://code.deepline.com/api/v2/cli/python}"

mkdir -p "$CACHE_DIR"

# Prepend plugin bin/ to PATH so the shim wins over any pre-existing
# standalone install of `deepline` that may live in ~/.local/bin or similar.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${CLAUDE_PLUGIN_ROOT%/}/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

if [ ! -x "$SHIV" ]; then
  TMP="$(mktemp "${TMPDIR:-/tmp}/deepline-shiv.XXXXXX")"
  if curl -fsSL "$SHIV_FETCH_URL" -o "$TMP"; then
    chmod +x "$TMP"
    mv "$TMP" "$SHIV"
  else
    rm -f "$TMP"
    printf '\033[33m[deepline]\033[0m Failed to fetch CLI shiv — `deepline` commands may not work this session.\n' >&2
    exit 0
  fi
fi

exit 0
