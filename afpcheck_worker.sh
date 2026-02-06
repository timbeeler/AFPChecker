#!/usr/bin/env bash
# Worker: run one AFP check for the given IP (or host) argument.
# Usage: afpcheck_worker.sh <host>
set -uo pipefail

ip="${1:-}"
if [[ -z "$ip" ]]; then
  echo "Usage: $0 <host>" >&2
  exit 2
fi

# Configurable via environment before calling worker:
LOGFILE="${LOGFILE:-/var/log/afpcheck.log}"
AFP_DIR="${AFP_DIR:-afptmp}"
TEST_FILE="${TEST_FILE:-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12 || echo afpchecktest)}"
MOUNT_TIMEOUT="${MOUNT_TIMEOUT:-20}"   # seconds for mount
OP_TIMEOUT="${OP_TIMEOUT:-8}"         # seconds for touch/rm/unmount
REACH_TIMEOUT="${REACH_TIMEOUT:-3}"   # seconds for fast TCP check
MNTROOT="${MNTROOT:-/tmp/afpcheck}"
MNT="$MNTROOT/$ip"

mkdir -p "$MNTROOT"
mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
touch "$LOGFILE" 2>/dev/null || true

log() {
  local ts
  ts="$(date '+%F %T')"
  printf "[%s] %s\n" "$ts" "$*" >>"$LOGFILE"
}

# choose timeout binary (timeout or gtimeout), empty if none
TOBIN=""
if command -v timeout >/dev/null 2>&1; then
  TOBIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TOBIN="gtimeout"
fi

# quick TCP reachability test (port 548 = AFP)
if command -v nc >/dev/null 2>&1; then
  if ! nc -z -w "$REACH_TIMEOUT" "$ip" 548 >/dev/null 2>&1; then
    log "UNREACHABLE $ip (tcp:548)"
    exit 3
  fi
fi

start_ts=$(date +%s)
log "START $ip"

mkdir -p "$MNT"

# mount with timeout (if available)
if [[ -n "$TOBIN" ]]; then
  if ! $TOBIN "${MOUNT_TIMEOUT}s" /sbin/mount_afp "afp://$ip/$AFP_DIR" "$MNT" >/dev/null 2>&1; then
    log "MOUNT_FAILED $ip"
    rmdir "$MNT" 2>/dev/null || true
    exit 4
  fi
else
  # no timeout binary available — try to mount but beware of hanging
  if ! /sbin/mount_afp "afp://$ip/$AFP_DIR" "$MNT" >/dev/null 2>&1; then
    log "MOUNT_FAILED_NO_TIMEOUT $ip"
    rmdir "$MNT" 2>/dev/null || true
    exit 4
  fi
fi

# small IO test: touch & rm
if [[ -n "$TOBIN" ]]; then
  if ! $TOBIN "${OP_TIMEOUT}s" bash -c "touch '$MNT/$TEST_FILE' && rm -f '$MNT/$TEST_FILE'" >/dev/null 2>&1; then
    log "IO_FAILED $ip"
    # attempt to unmount anyway
    $TOBIN "${OP_TIMEOUT}s" /sbin/umount "$MNT" >/dev/null 2>&1 || true
    rmdir "$MNT" 2>/dev/null || true
    exit 5
  fi
else
  if ! bash -c "touch '$MNT/$TEST_FILE' && rm -f '$MNT/$TEST_FILE'" >/dev/null 2>&1; then
    log "IO_FAILED_NO_TIMEOUT $ip"
    /sbin/umount "$MNT" >/dev/null 2>&1 || true
    rmdir "$MNT" 2>/dev/null || true
    exit 5
  fi
fi

# unmount
if [[ -n "$TOBIN" ]]; then
  $TOBIN "${OP_TIMEOUT}s" /sbin/umount "$MNT" >/dev/null 2>&1 || log "UNMOUNT_FAILED $ip"
else
  /sbin/umount "$MNT" >/dev/null 2>&1 || log "UNMOUNT_FAILED_NO_TIMEOUT $ip"
fi

rmdir "$MNT" 2>/dev/null || true
elapsed=$(( $(date +%s) - start_ts ))
log "SUCCESS $ip elapsed=${elapsed}s"
exit 0