# AFPChecker

## Overview

AFPChecker is a client-side monitoring script designed to verify AFP
(Apple Filing Protocol) connectivity and functionality.

It integrates with **Nagios** via NRPE by performing periodic mount,
write, delete, and unmount operations against configured AFP shares and
logging the results for monitoring and alerting.

------------------------------------------------------------------------

## File Locations & Descriptions

### Main script

    /usr/local/afpchecker/afpcheck

Shell script that:

-   Mounts an AFP share\
-   Creates a zero-byte test file\
-   Deletes the file\
-   Unmounts the share\
-   Logs all actions and errors

------------------------------------------------------------------------

### LaunchDaemon (automation)

    /Library/LaunchDaemons/com.rt.afpchecker.plist

Launchd configuration that:

-   Runs `afpcheck` every 5 minutes (300 seconds)\
-   Runs at system boot

------------------------------------------------------------------------

### AFP share list

    /usr/local/afpchecker/list_afp.txt

Text file containing AFP share URLs or mount targets that are checked
during each run.

------------------------------------------------------------------------

### Log file

    /log_afpcheck.log

Log of all AFP connectivity checks and errors.

This file is monitored by Nagios via NRPE.

------------------------------------------------------------------------

### Documentation

    /usr/local/afpchecker/readme.txt

Legacy documentation file (this README supersedes it).

------------------------------------------------------------------------

## How It Works

1.  For each AFP share listed in `list_afp.txt`, the script:

    -   Creates a temporary mount point\
    -   Mounts the AFP share\
    -   Writes a zero-byte test file\
    -   Deletes the file\
    -   Unmounts the share

2.  All actions and errors are logged to:

        /log_afpcheck.log

3.  The script is executed automatically by launchd every 300 seconds
    and at system startup.

------------------------------------------------------------------------

## Nagios Integration

Nagios monitors AFP connectivity by inspecting the client log file using
NRPE.

On the client, `nrpe.cfg` includes the following command:

    command[check_log]=/usr/local/nagios/libexec/check_log   -F /log_afpcheck.log   -O /var/tmp/log_afpcheck   -q error

### What this does:

-   Scans `/log_afpcheck.log`\
-   Tracks the last read position in `/var/tmp/log_afpcheck`\
-   Searches for the keyword: `error`

If any errors are found, Nagios triggers an alert.

------------------------------------------------------------------------

## Purpose

AFPChecker was created to:

-   Validate AFP share availability from client machines\
-   Detect mount, write, or permission failures\
-   Provide early warning of storage or network issues

By testing real file operations (not just connectivity), it ensures AFP
shares are fully functional --- not just reachable.

------------------------------------------------------------------------

## Known Issues / Testing Notes

-   AFP mount failures may occur if credentials expire or permissions
    change\
-   Network latency can cause intermittent mount timeouts\
-   Log file growth should be monitored or rotated over time

(Consider adding log rotation via `newsyslog` or `logrotate`.)
