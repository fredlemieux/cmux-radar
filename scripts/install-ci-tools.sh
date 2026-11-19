#!/usr/bin/env bash
# Installs exact, checksum-verified SwiftLint and SwiftFormat release binaries into DIR and, on
# GitHub Actions, puts DIR on PATH. CI uses this instead of Homebrew so a new upstream release
# can't change lint results or break the build. Bump versions and hashes together.
#
#   scripts/install-ci-tools.sh DIR
set -euo pipefail

dir="${1:?usage: install-ci-tools.sh <dir>}"
mkdir -p "$dir"

install() {
  local name="$1" url="$2" sha256="$3"
  local archive="$dir/$name.zip"
  curl -fsSL --retry 3 -o "$archive" "$url"
  echo "$sha256  $archive" | shasum -a 256 -c - >/dev/null || { echo "✗ checksum mismatch for $name" >&2; exit 1; }
  unzip -oq "$archive" "$name" -d "$dir"
  chmod +x "$dir/$name"
  echo "✓ $name $("$dir/$name" --version 2>/dev/null || "$dir/$name" version)"
}

install swiftlint \
  https://github.com/realm/SwiftLint/releases/download/0.65.1/portable_swiftlint.zip \
  c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0
install swiftformat \
  https://github.com/nicklockwood/SwiftFormat/releases/download/0.64.7/swiftformat.zip \
  e82e224325cbd3403fc7b68caf6c917926dc106de3af875fca4b87e3c4634038

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$dir" >> "$GITHUB_PATH"
fi
