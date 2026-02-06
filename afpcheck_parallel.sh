#!/usr/bin/env bash
# Wrapper: run checks in parallel using GNU parallel
# Usage: ./afpcheck_parallel.sh [MAX_JOBS] [AFP_LIST]
set -euo pipefail

if ! command -v parallel >/dev/null 2>&1; then
  echo "GNU parallel not found. Install via your package manager (e.g. brew install parallel or apt install parallel)." >&2
  exit 2
fi

MAX_JOBS="${1:-20}"                                 # tune for your environment
AFP_LIST="${2:-/usr/local/afpchecker/list_afp.txt}"
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${WORKDIR}/afpcheck_worker.sh"

if [[ ! -x "$WORKER" ]]; then
  echo "Worker not found or not executable: $WORKER" >&2
  exit 3
fi

if [[ ! -f "$AFP_LIST" ]]; then
  echo "List not found: $AFP_LIST" >&2
  exit 4
fi

# Use grep to filter comments/blank lines then feed into parallel (reads from stdin).
grep -E -v '^\s*(#|$)' "$AFP_LIST" | parallel --jobs "$MAX_JOBS" "$WORKER" {}