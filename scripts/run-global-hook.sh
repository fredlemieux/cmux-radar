#!/usr/bin/env bash
# The repo sets a local core.hooksPath so lefthook can install alongside a global hooks path.
# This keeps any global hook (e.g. one that rewrites commit messages) running for this repo too.
set -euo pipefail
hook="$1"; shift
global_dir="$(git config --global --get core.hooksPath || true)"
global_dir="${global_dir/#\~/$HOME}"
if [[ -n "$global_dir" && -x "$global_dir/$hook" ]]; then
  exec "$global_dir/$hook" "$@"
fi
