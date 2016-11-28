afpchecker

File descriptions and locations:

/usr/local/afpchecker/afpcheck - shell script that mounts an afp share, writes and deletes a file.
/Library/LaunchDamons/com.rt.afpchecker.plist - launchd plist that runs afpcheck every 5 mins
/usr/local/afpchecker/list_afp.txt - a list of AFP shares that are checked when afpcheck runs
/log_afpcheck.log - a log of the checks, and the file that is defined in nrpe.conf for check_logs
/usr/local/afpchecker/readme.txt - this file

Description of application

This script was intended to check for AFP connectivity from a the client, NAGIOS would monitor the log file on the client and if errors are detected then alert the appropriate people.

This script creates a volume mount, mounts the afp, creates and then deletes a 0b file and unmount. It logs all the interactions in the /log_checkafp.log file.

The script is automated via a global damon and runs every 300 seconds and at boot.

A Nagios Host runs nrpe command with the argument check_log. The nrpe.cfg file on the client has the following harcoded command uncommented:

command[check_log]=/usr/local/nagios/libexec/check_log -F /log_afpcheck.log -O /var/tmp/log_afpcheck -q error. This combination inspects the logs looking for “error”, which is returned when the afpcheck cannot perform one of it’s tasks.

Pull request
