#!/bin/bash
#
# Build precompiled platform gems for doltlite from the per-platform libdoltlite
# libraries built by the dolthub/doltlite release. Run from a doltlite-ruby
# checkout. Expects the release's library zips (doltlite-lib-<target>-<ver>.zip)
# in the directory given as the second argument.
#
# Usage: script/build-gems.sh <version> <libs_dir>
#   version   gem version (e.g. 0.11.18)
#   libs_dir  directory containing doltlite-lib-<target>-<version>.zip files
#
# Produces pkg/doltlite-<version>-<platform>.gem for each available platform.

set -euo pipefail

VERSION="${1:?usage: build-gems.sh <version> <libs_dir>}"
LIBS_DIR="${2:?usage: build-gems.sh <version> <libs_dir>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# release target -> ruby platform : bundled library filename
MAPPINGS=(
  "linux-x64:x86_64-linux:libdoltlite.so"
  "linux-arm64:aarch64-linux:libdoltlite.so"
  "osx-arm64:arm64-darwin:libdoltlite.dylib"
  "osx-x64:x86_64-darwin:libdoltlite.dylib"
)

mkdir -p pkg
built=0
for entry in "${MAPPINGS[@]}"; do
  IFS=: read -r target platform libfile <<< "$entry"
  zip="$LIBS_DIR/doltlite-lib-${target}-${VERSION}.zip"
  if [ ! -f "$zip" ]; then
    echo "skip ${platform}: ${zip} not found"
    continue
  fi

  rm -rf vendor/libdoltlite
  mkdir -p vendor/libdoltlite
  tmp="$(mktemp -d)"
  unzip -qo "$zip" -d "$tmp"
  found="$(find "$tmp" -name "$libfile" | head -1)"
  rm -rf -- "$tmp"
  if [ -z "$found" ]; then
    echo "ERROR: ${libfile} not found in ${zip}" >&2
    exit 1
  fi
  cp "$found" "vendor/libdoltlite/${libfile}"

  GEM_PLATFORM="$platform" gem build doltlite.gemspec -o "pkg/doltlite-${VERSION}-${platform}.gem"
  built=$((built + 1))
done

rm -rf vendor/libdoltlite && mkdir -p vendor/libdoltlite
echo "built ${built} platform gem(s):"
ls -la pkg
