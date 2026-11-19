#!/usr/bin/env bash
# Conventional Commits: `type(scope)?: lowercase subject`, body lines ≤ 100 chars, no AI attribution.
set -euo pipefail
file="$1"
subject="$(head -n1 "$file")"
pattern='^(feat|fix|docs|chore|refactor|test|perf|build|ci|style|revert)(\([a-z0-9-]+\))?!?: [a-z0-9`]'

if [[ "$subject" =~ ^(Merge|Revert|fixup!|squash!) ]]; then exit 0; fi
if ! [[ "$subject" =~ $pattern ]]; then
  echo "✗ Commit subject must be Conventional Commits, lowercase: '$subject'" >&2
  exit 1
fi
if awk 'NR > 2 && length($0) > 100 && $0 !~ /^#/' "$file" | grep -q .; then
  echo "✗ Commit body lines must be ≤ 100 characters." >&2
  exit 1
fi
if grep -qiE '^co-authored-by:' "$file"; then
  echo "✗ No Co-Authored-By lines (docs/standards.md §6)." >&2
  exit 1
fi
