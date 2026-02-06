# AFPChecker

## Overview

AFPChecker is a client-side monitoring script designed to verify AFP (Apple Filing Protocol) connectivity and functionality.

It integrates with **Nagios** via NRPE by performing periodic mount, write, delete, and unmount operations against configured AFP shares and logging the results for monitoring and alerting.

In addition to the original serial checker, AFPChecker includes **parallel runners** (GNU `parallel` and `xargs -P`) to reduce total runtime when checking many shares.

---

## File Locations & Descriptions

### Main script (serial)

```
/usr/local/afpchecker/afpcheck
```

Shell script that:

- Mounts an AFP share
- Creates a zero-byte test file
- Deletes the file
- Unmounts the share
- Logs all actions and errors

---

### LaunchDaemon (automation)

```
/Library/LaunchDaemons/com.rt.afpchecker.plist
```

Launchd configuration that:

- Runs the checker every 5 minutes (300 seconds)
- Runs at system boot

---

### AFP share list

```
/usr/local/afpchecker/list_afp.txt
```

Text file containing AFP share URLs or mount targets that are checked during each run.

> Blank lines and lines beginning with `#` are treated as comments by the parallel wrappers.

---

### Log file

```
/log_afpcheck.log
```

Log of all AFP connectivity checks and errors.

This file is monitored by Nagios via NRPE.

---

### Parallel scripts (repo)

These scripts live in the repository and are intended to run the same check logic across many shares concurrently:

- `afpcheck_worker.sh` — invoked once per AFP target (one share per process)
- `afpcheck_parallel.sh` — wrapper using **GNU parallel**
- `afpcheck_xargs.sh` — wrapper using **xargs -P** (no GNU parallel dependency)

---

## How It Works

For each AFP share listed in `list_afp.txt`, AFPChecker performs a real “functional” test:

- Create a mount point
- Mount the AFP share
- Create a zero-byte test file
- Delete the test file
- Unmount the share

All actions and errors are logged to:

```
/log_afpcheck.log
```

The script is typically executed automatically by launchd every 300 seconds and at system startup.

---

## Parallel Checking

Parallel mode exists to speed up checks when you have a large share list.

### Worker model (`afpcheck_worker.sh`)

Runs a single AFP check for one host.

**Usage**

```bash
./afpcheck_worker.sh <host>
```

**Environment overrides**

| Variable | Default | Description |
|---------|--------|-------------|
| LOGFILE | /var/log/afpcheck.log | Log file location |
| AFP_DIR | afptmp | AFP share name/path |
| TEST_FILE | random | Temporary file name |
| MOUNT_TIMEOUT | 20 | Seconds allowed for mount |
| OP_TIMEOUT | 8 | Seconds allowed for IO + unmount |
| REACH_TIMEOUT | 3 | TCP reach test timeout |
| MNTROOT | /tmp/afpcheck | Root mount directory |

**Exit codes**

| Code | Meaning |
|-----:|--------|
| 0 | Success |
| 2 | Missing host argument |
| 3 | Host unreachable (TCP 548) |
| 4 | Mount failed |
| 5 | IO test failed |

---

### GNU parallel runner (`afpcheck_parallel.sh`)

Runs workers using GNU `parallel`.

**Usage**

```bash
./afpcheck_parallel.sh [MAX_JOBS] [AFP_LIST]
```

**Defaults**

- `MAX_JOBS=20`
- `AFP_LIST=/usr/local/afpchecker/list_afp.txt`

**Examples**

```bash
./afpcheck_parallel.sh
./afpcheck_parallel.sh 30
./afpcheck_parallel.sh 20 ./list_afp.txt
```

**Requirements**

Install GNU parallel:

- macOS: `brew install parallel`
- Linux: `apt install parallel`

**Exit codes**

| Code | Meaning |
|-----:|--------|
| 2 | GNU parallel not installed |
| 3 | Worker missing/not executable |
| 4 | AFP list file missing |

---

### xargs runner (`afpcheck_xargs.sh`)

Parallel execution without GNU parallel.

**Usage**

```bash
./afpcheck_xargs.sh [MAX_JOBS] [AFP_LIST]
```

**Defaults**

- `MAX_JOBS=10`
- `AFP_LIST=/usr/local/afpchecker/list_afp.txt`

**Examples**

```bash
./afpcheck_xargs.sh
./afpcheck_xargs.sh 20
./afpcheck_xargs.sh 10 ./list_afp.txt
```

**Exit codes**

| Code | Meaning |
|-----:|--------|
| 2 | Worker missing/not executable |
| 3 | AFP list file missing |

---

## Nagios Integration

Nagios monitors AFP connectivity by inspecting the log file via NRPE.

```bash
command[check_log]=/usr/local/nagios/libexec/check_log   -F /log_afpcheck.log   -O /var/tmp/log_afpcheck   -q error
```

---

## Purpose

AFPChecker validates AFP shares using real filesystem operations to ensure:

- Connectivity
- Permissions
- Write/delete capability

This catches failures that simple ping or port checks miss.

---

## Known Issues

- Credential expiry can cause mount failures
- High parallel job counts may overload systems
- Logs should be rotated to prevent growth

---

## Future Ideas

- Metrics export (Prometheus/CSV)
- Structured logs (JSON)
- Smarter retry logic
- Sample LaunchDaemon for parallel mode
