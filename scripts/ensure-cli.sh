#!/usr/bin/env bash
# SessionStart hook. Caches the Deepline CLI shiv at a deterministic path
# under $XDG_DATA_HOME (default ~/.local/share/deepline-plugin/cli/), not
# under $CLAUDE_PLUGIN_DATA — that variable is only reliable inside the
# plugin's own hook context, not in general Bash tool env, and the shim
# can't read it back.
set -e

PLUGIN_VERSION_FILE="${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json"
PLUGIN_VERSION="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_VERSION_FILE" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"

CACHE_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/deepline-plugin"
CACHE_DIR="$CACHE_ROOT/cli"
SHIV="$CACHE_DIR/deepline.pyz"
VERSION_FILE="$CACHE_DIR/version"

mkdir -p "$CACHE_DIR"

# Prepend plugin bin/ to PATH so our shim wins over any standalone install
# of `deepline` that may live in ~/.local/bin or similar.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${CLAUDE_PLUGIN_ROOT%/}/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

CACHED_VERSION="$(cat "$VERSION_FILE" 2>/dev/null || true)"

if [ ! -x "$SHIV" ] || [ "$CACHED_VERSION" != "$PLUGIN_VERSION" ]; then
  printf '\033[36m[deepline]\033[0m Fetching CLI shiv (plugin %s)...\n' "$PLUGIN_VERSION" >&2
  TMP="$(mktemp "${TMPDIR:-/tmp}/deepline-shiv.XXXXXX")"
  if curl -fsSL "https://code.deepline.com/api/v2/cli/python" -o "$TMP"; then
    chmod +x "$TMP"
    mv "$TMP" "$SHIV"
    printf '%s' "$PLUGIN_VERSION" > "$VERSION_FILE"
    printf '\033[32m[deepline]\033[0m CLI ready at %s\n' "$SHIV" >&2
  else
    rm -f "$TMP"
    printf '\033[33m[deepline]\033[0m Failed to fetch CLI shiv — deepline commands will not work this session.\n' >&2
    exit 0
  fi
fi

# Auth nudge
if [ -x "$SHIV" ]; then
  if ! "$SHIV" auth status --json 2>/dev/null | grep -q '"authenticated"[[:space:]]*:[[:space:]]*true'; then
    printf '\033[36m[deepline]\033[0m Run \033[1mdeepline auth login\033[0m once to authenticate.\n' >&2
  fi
fi

exit 0
