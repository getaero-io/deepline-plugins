# Deepline CLI launcher (`bin/`)

This directory bundles a **Node-independent launcher** for the Deepline CLI,
mirroring the design of [`clay-run/agent-plugins`](https://github.com/clay-run/agent-plugins).

## What it does

`bin/deepline` is a small POSIX `sh` script. On first use it:

1. reads the pinned CLI version from `cli-version`,
2. detects the host OS/arch (`deepline-darwin-arm64`, `deepline-linux-x64`, …),
3. downloads the matching standalone binary from the
   `getaero-io/deepline-api` **`sdk-v<version>`** GitHub release,
4. checksum-verifies it against `checksums.txt` (refusing to run on mismatch),
5. caches it under `$DEEPLINE_CONFIG_HOME`/`$XDG_CONFIG_HOME`/`$HOME/.config` and
   `exec`s it.

There is **no `npm install -g`, no Node hunt, and no global `npm prefix`
mutation** — the downloaded binary is a self-contained executable produced by
`bun build --compile`, so it runs on a host with no Node installed at all.

Claude Code automatically adds this `bin/` to `PATH` when the plugin is
installed, so `deepline` just works after `/plugin install deepline@deepline`.

## Files

| File | Purpose |
| --- | --- |
| `deepline` | the launcher (POSIX `sh`, no dependencies beyond `curl`/`wget` + `sha256sum`/`shasum`) |
| `cli-version` | the pinned CLI version; the launcher downloads the matching `sdk-v<version>` release |
| `checksums.txt` | `<sha256>  deepline-<os>-<arch>` for each platform binary in that release |

## Platform notes

- **x64 uses bun's `-baseline` compile target.** The default `bun-linux-x64` /
  `bun-darwin-x64` binaries require AVX CPU instructions and abort on hosts
  without them (older/budget cloud VMs, some shared tiers). The release workflow
  compiles the x64 assets with `bun-<os>-x64-baseline` so they run everywhere;
  the asset name stays `deepline-<os>-x64`, so this launcher is unaffected.
- **glibc only.** The binaries are glibc-linked; the launcher fails with a clean
  categorical error on musl (Alpine) rather than a cryptic loader crash.

## Keeping this in sync with the CLI

`cli-version` + `checksums.txt` are produced by the Deepline SDK release
workflow (`getaero-io/deepline-api` → `.github/workflows/sdk-release.yml`),
which compiles the four platform binaries with `bun build --compile`, uploads
them as `sdk-v<version>` release assets alongside a `checksums.txt`, and then
updates these two files in this repo. See the companion PR on `deepline-api`
for the workflow change (`docs/COMPANION-deepline-api-sdk-release.md`).
