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
          for tgt in darwin-arm64 darwin-x64 linux-arm64 linux-x64; do
            bun build ./dist/cli/index.mjs \
              --compile --target="bun-${tgt}" \
              --outfile "../dist-bin/deepline-${tgt}"
          done
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
Verified locally against `sdk/dist/cli/index.mjs`: all four targets compile
(62–92 MB each) and the darwin-arm64 binary runs `--version` / `--help` with no
Node anywhere on `PATH`.

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
