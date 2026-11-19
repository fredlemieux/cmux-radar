#!/usr/bin/env bash
# Mutation testing with Muter (docs/standards.md §3.2, §3.7).
#
#   scripts/mutate.sh                 full run (nightly)
#   scripts/mutate.sh --changed BASE  only Swift sources changed since BASE (pull requests)
#
# Fails when the score is below MUTATION_THRESHOLD (default 90).
set -euo pipefail
cd "$(dirname "$0")/.."

threshold="${MUTATION_THRESHOLD:-90}"
mutated_copy="$(cd .. && pwd)/$(basename "$PWD")_mutated"

files=()
if [[ "${1:-}" == "--changed" ]]; then
  base="${2:?usage: mutate.sh --changed <base-ref>}"
  while IFS= read -r file; do files+=("$file"); done < <(
    git diff --name-only --diff-filter=AM "$base"...HEAD -- 'Sources/RadarCore/*.swift' 'Sources/RadarSnapshot/*.swift' |
      grep -vE 'Sources/RadarSnapshot/(Render|AssertSnapshot)\.swift' || true
  )
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No mutable sources changed since $base — skipping."
    exit 0
  fi
fi

# Muter needs a config in the repo root; generate it so toolchain-specific flags stay correct.
{
  echo "executable: $(command -v swift)"
  echo "arguments:"
  printf -- '- %s\n' test --scratch-path .build-mutate --disable-get-task-allow-entitlement -Xswiftc -no-warnings-as-errors
  for flag in $(scripts/swift-test-flags.sh); do printf -- '- %s\n' "$flag"; done
  cat <<'YAML'
exclude:
- Package.swift
- Tests
- .build
- .build-mutate
- Sources/RadarUI
- Sources/RadarCatalog
- Sources/RadarSnapshot/Render.swift
- Sources/RadarSnapshot/AssertSnapshot.swift
excludeCalls: []
YAML
} > muter.conf.yml

# Muter copies the repo; resolve dependencies first so the copy never has to fetch.
swift package --scratch-path .build-mutate resolve >/dev/null
rm -rf -- "$mutated_copy"

args=(run --skip-coverage --format plain)
for file in "${files[@]}"; do args+=(--files-to-mutate "$file"); done

report="$(mktemp)"
muter "${args[@]}" | tee "$report" | grep -E 'mutant (killed|survived)|Mutation Score of' || true
rm -rf -- "$mutated_copy"

score="$(sed -nE 's/.*Mutation Score of Test Suite: ([0-9]+)%.*/\1/p' "$report" | tail -1)"
if [[ -z "$score" ]]; then
  echo "✗ Muter produced no score — see the output above." >&2
  exit 1
fi
if (( score < threshold )); then
  echo "✗ Mutation score $score% is below the $threshold% threshold." >&2
  exit 1
fi
echo "✓ Mutation score $score% (threshold $threshold%)"
