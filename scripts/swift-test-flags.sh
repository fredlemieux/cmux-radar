#!/usr/bin/env bash
# Prints extra `swift` flags needed when only the Command Line Tools are installed (no Xcode).
# The CLT ship Swift Testing but don't add its framework and interop library to the search
# paths of non-test targets, so libraries that `import Testing` fail to build or load.
# With full Xcode (CI, most dev machines) this prints nothing. See docs/adr/0001.
set -euo pipefail

developer_dir="$(xcode-select -p)"
if [[ "$developer_dir" != *CommandLineTools* ]]; then
  exit 0
fi

base="$developer_dir/Library/Developer"
printf -- '-Xswiftc -F -Xswiftc %s/Frameworks ' "$base"
printf -- '-Xlinker -rpath -Xlinker %s/Frameworks ' "$base"
printf -- '-Xlinker -rpath -Xlinker %s/usr/lib\n' "$base"
