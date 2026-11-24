#!/usr/bin/env bash
# Runs SwiftLint. With only the Command Line Tools installed, SwiftLint can't find SourceKit on
# its own, so point it at the CLT copy. With full Xcode this is a plain `swiftlint`.
set -euo pipefail
developer_dir="$(xcode-select -p)"
if [[ "$developer_dir" == *CommandLineTools* ]]; then
  export DYLD_FRAMEWORK_PATH="$developer_dir/usr/lib"
fi
exec swiftlint "$@"
