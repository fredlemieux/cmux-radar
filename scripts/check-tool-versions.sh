#!/usr/bin/env bash
# Fails when a tool's major.minor differs from the version the repo was tuned for.
# Bump these together with any config changes the new version needs.
set -euo pipefail

expect() {
  local name="$1" want="$2" have="$3"
  if [[ "$have" != "$want"* ]]; then
    echo "✗ $name $have — expected $want.x (see scripts/check-tool-versions.sh)" >&2
    return 1
  fi
  echo "✓ $name $have"
}

status=0
expect swiftlint 0.65 "$(swiftlint version)" || status=1
expect swiftformat 0.64 "$(swiftformat --version)" || status=1
expect lefthook 2. "$(lefthook version)" || status=1
expect swift 6. "$(swift --version 2>&1 | sed -nE 's/.*Swift version ([0-9.]+).*/\1/p')" || status=1
exit "$status"
