#!/usr/bin/env bash
# Wrapper: run checks in parallel using xargs -P
# Usage: ./afpcheck_xargs.sh [MAX_JOBS] [AFP_LIST]
set -euo pipefail

MAX_JOBS="${1:-10}"                             # tune for your environment
AFP_LIST="${2:-/usr/local/afpchecker/list_afp.txt}"
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${WORKDIR}/afpcheck_worker.sh"

if [[ ! -x "$WORKER" ]]; then
  echo "Worker not found or not executable: $WORKER" >&2
  exit 2
fi

if [[ ! -f "$AFP_LIST" ]]; then
  echo "List not found: $AFP_LIST" >&2
  exit 3
fi

# feed non-empty, non-comment lines to xargs:
grep -E -v '^\s*(#|$)' "$AFP_LIST" | xargs -n1 -P "$MAX_JOBS" -I {} "$WORKER" {}