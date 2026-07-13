# Companion change: publish standalone CLI binaries from `deepline-api`

The launcher in `deepline/bin/` downloads a per-platform standalone binary from
the `getaero-io/deepline-api` **`sdk-v<version>`** GitHub release. That release
does not yet attach those binaries, so this PR needs a companion change in
`deepline-api` to build and upload them. This mirrors how
`clay-run/agent-plugins` ships binaries via its `clay-cli-v<version>` releases.

Both changes are small and additive: the npm publish path is untouched, so the
existing `npm install -g deepline` flow keeps working during rollout.

## 1. Add a compile + checksum step to `.github/workflows/sdk-release.yml`

The workflow already installs `bun` (1.3.11) and builds the SDK to
`sdk/dist/cli/index.mjs`. Add this step **after "Rebuild SDK with stamped
version"** and **before "Create GitHub release"**:

```yaml
      - name: Compile standalone CLI binaries
        if: steps.decide.outputs.should_publish == 'true'
        working-directory: sdk
        run: |
          set -euo pipefail
          mkdir -p ../dist-bin
          # target -> bun compile target. x64 uses the *baseline* target on
          # purpose: bun's default bun-linux-x64 / bun-darwin-x64 binaries
          # require AVX CPU instructions and abort with
          # "CPU lacks AVX support ... use *-baseline build" on hosts without
          # them (older/budget cloud VMs, some shared tiers, emulated x64).
          # Verified in a clean container: the default x64 binary aborts on a
          # no-AVX CPU; the -baseline binary runs. arm64 has no such split.
          # The asset name stays deepline-<os>-x64 so the launcher is unchanged.
          compile() { # <asset-suffix> <bun-target>
            bun build ./dist/cli/index.mjs \
              --compile --target="$2" \
              --outfile "../dist-bin/deepline-$1"
          }
          compile darwin-arm64 bun-darwin-arm64
          compile darwin-x64   bun-darwin-x64-baseline
          compile linux-arm64  bun-linux-arm64
          compile linux-x64    bun-linux-x64-baseline
          cd ../dist-bin
          # Clay-format checksums: "<sha256>  <asset>"
          sha256sum deepline-* > checksums.txt
          cat checksums.txt
```

Then attach the assets in the **"Create GitHub release"** step by adding them to
the `gh release create` call:

```yaml
          gh release create "sdk-v${{ steps.decide.outputs.version }}" \
            --title "SDK v${{ steps.decide.outputs.version }}" \
            --notes-file /tmp/sdk-release-notes.md \
            dist-bin/deepline-darwin-arm64 \
            dist-bin/deepline-darwin-x64 \
            dist-bin/deepline-linux-arm64 \
            dist-bin/deepline-linux-x64 \
            dist-bin/checksums.txt
```

`bun build --compile --target=bun-<os>-<arch>` cross-compiles from a single
ubuntu runner (bun downloads the target runtime), so no build matrix is needed.

### Add a smoke-run gate (recommended)

Compiling is not the same as running — the AVX issue above only surfaces at
*execution* time. Add a step after compile that actually runs the two Linux
binaries in clean, Node-free containers before the release is created, so a
broken binary fails the release instead of shipping:

```yaml
      - name: Smoke-run Linux binaries (no Node, glibc)
        if: steps.decide.outputs.should_publish == 'true'
        run: |
          set -euo pipefail
          run_one() { # <platform> <asset>
            docker run --rm --platform "$1" \
              -v "$PWD/dist-bin/$2:/deepline:ro" debian:12-slim \
              sh -c 'command -v node >/dev/null && { echo "node leaked in"; exit 1; }; /deepline --version'
          }
          run_one linux/amd64 deepline-linux-x64
          run_one linux/arm64 deepline-linux-arm64
```

(GitHub's ubuntu runners are x64, so `linux/amd64` is native and `linux/arm64`
runs under QEMU — enough to confirm the binaries execute and print a version.)

### Cross-platform validation (done locally via Docker, no Node in-container)

| Check | Result |
| --- | --- |
| `deepline-linux-arm64` runs on debian/glibc, no Node | pass |
| `deepline-linux-x64` **default** target on a no-AVX CPU | **aborts** (`CPU lacks AVX`) → use `-baseline` |
| `deepline-linux-x64` **baseline** target on a no-AVX CPU | pass |
| glibc binary on Alpine/musl (raw) | cryptic `not found` (why the launcher guards) |
| launcher musl guard on Alpine | clean JSON error, refuses to exec |
| launcher full flow on debian (download → checksum → cache → exec) | pass, no Node |
| `deepline-darwin-arm64` on macOS, no Node on PATH | pass |

## 2. Sync `cli-version` + `checksums.txt` back into `deepline-plugins`

After the release is created, update the two pinned files in this repo so the
launcher points at the new binaries. Add a final step to the same workflow (uses
a token with push access to `deepline-plugins`):

```yaml
      - name: Update deepline-plugins launcher pin
        if: steps.decide.outputs.should_publish == 'true'
        env:
          GH_TOKEN: ${{ secrets.DEEPLINE_PLUGINS_PUSH_TOKEN }}
          VERSION: ${{ steps.decide.outputs.version }}
        run: |
          set -euo pipefail
          git clone --depth 1 "https://x-access-token:${GH_TOKEN}@github.com/getaero-io/deepline-plugins.git" /tmp/dp
          printf '%s' "$VERSION" > /tmp/dp/deepline/bin/cli-version
          cp dist-bin/checksums.txt /tmp/dp/deepline/bin/checksums.txt
          cd /tmp/dp
          if ! git diff --quiet; then
            git config user.name "deepline-release-bot"
            git config user.email "release-bot@deepline.com"
            git commit -am "chore: pin CLI launcher to sdk-v${VERSION}"
            git push
          fi
```

(Alternatively, open this as an automated PR against `deepline-plugins` instead
of a direct push, if branch protection requires review.)

## Notes

- **glibc**: `bun build --compile` linux binaries are glibc-linked; the launcher
  already guards against musl/Alpine with a categorical error. Matches Clay.
- **Size**: binaries are 62–92 MB (the bun runtime is embedded). They are release
  assets, not committed to git — only `cli-version` (a few bytes) and
  `checksums.txt` (4 lines) live in this repo.
- **Rollback**: if a release's binaries are bad, revert `cli-version` here to the
  previous version; the launcher will download the older, still-present release.
