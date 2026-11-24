#!/usr/bin/env bash
# Conventional Commits: `type(scope)?: lowercase subject`, body lines ≤ 100 chars, no AI attribution.
# Human Co-Authored-By trailers are allowed.
set -euo pipefail
file="$1"
subject="$(head -n1 "$file")"
pattern='^(feat|fix|docs|chore|refactor|test|perf|build|ci|style|revert)(\([a-z0-9-]+\))?!?: [a-z0-9`]'

if [[ "$subject" =~ ^(Merge|Revert|fixup!|squash!) ]]; then exit 0; fi
if ! [[ "$subject" =~ $pattern ]]; then
  echo "✗ Commit subject must be Conventional Commits, lowercase: '$subject'" >&2
  exit 1
fi
# Stop at the scissors line: `git commit -v` appends the diff below it, which isn't part of the body.
comment="$(git config --get core.commentChar 2>/dev/null || echo '#')"
[[ "$comment" == "auto" || -z "$comment" ]] && comment='#'
if awk -v c="$comment" 'index($0, c " ------------------------ >8") == 1 { exit }
  NR > 2 && length($0) > 100 && index($0, c) != 1' "$file" | grep -q .; then
  echo "✗ Commit body lines must be ≤ 100 characters." >&2
  exit 1
fi
if grep -qiE '^co-authored-by:.*noreply@anthropic\.com' "$file"; then
  echo "✗ No AI attribution lines (docs/standards.md §6). Human co-authors are fine." >&2
  exit 1
fi
