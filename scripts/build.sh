#!/usr/bin/env bash
# Build a read-only wacli for linux/amd64 from an upstream release tag.
# Usage: scripts/build.sh v0.25.0
# Output: dist/wacli (static binary) and dist/wacli-linux-amd64.tar.gz
set -euo pipefail

tag="${1:?usage: build.sh <upstream tag, e.g. v0.25.0>}"
root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/build/wacli"
dist="$root/dist"

rm -rf "$src" "$dist"
mkdir -p "$dist"
git clone --quiet --depth 1 --branch "$tag" https://github.com/openclaw/wacli.git "$src"

# Fails loudly when upstream changed the patched lines: the release must not ship.
git -C "$src" apply --whitespace=nowarn "$root/patch/readonly.patch"

# Same Go toolchain image upstream pins for this tag.
go_image="$(awk '/^FROM golang:/ {print $2; exit}' "$src/Dockerfile")"
if [[ -z "$go_image" ]]; then
  echo "could not find the golang image in upstream Dockerfile" >&2
  exit 1
fi

version="${tag#v}-ro"
docker run --rm -v "$src:/src" -w /src "$go_image" sh -euc "
  apk add --no-cache build-base git >/dev/null
  CGO_ENABLED=1 CGO_CFLAGS='-Wno-error=missing-braces' GOOS=linux GOARCH=amd64 \
    go build -tags sqlite_fts5 -trimpath \
    -ldflags '-s -w -X main.version=$version -linkmode external -extldflags -static' \
    -o /src/wacli-bin ./cmd/wacli
"

cp "$src/wacli-bin" "$dist/wacli"
cp "$root/LICENSE.upstream" "$dist/LICENSE"
tar -C "$dist" -czf "$dist/wacli-linux-amd64.tar.gz" wacli LICENSE
(cd "$dist" && sha256sum wacli-linux-amd64.tar.gz > SHA256SUMS)
echo "built $version"
