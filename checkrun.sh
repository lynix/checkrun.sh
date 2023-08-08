#!/bin/bash

# checkrun.sh
# ---------------
# Cron-style mailing wrapper for systemd .timer units
# (C) Alexander Koch <mail@alexanderkoch.net>
#
# Released under the terms of the MIT License, see 'LICENSE'


USER="${USER:-$(id -un)}"
HOST_FQDN="$HOSTNAME"
if which hostname &>/dev/null; then
	HOST_FQDN="$(hostname -f)"
fi

# defaults
MAILER="sendmail -t"
MAILTO="$USER"
SFORMAT="%s [%d]"
QUIET=0
NOLOG=0
NOEMPTY=0

# usage information
function print_usage() {
	echo "usage: $0 [OPTIONS] COMMAND"
	echo "options:"
	echo "    -s CMD     use CMD as mailer (default: sendmail)"
	echo "    -m MAILTO  set recipient for notification mail (default: \$USER)"
	echo "    -f FORMAT  set format string for mail subject (default: \"$SFORMAT\")"
	echo "    -q         do not send command output on exit code 0"
	echo "    -n         do not send notification if output is empty"
	echo "    -l         do not forward command output to stdout"
	echo "    -h         display this usage information"
}

# sendmail interface
function mail() {
	FROM="From: checkrun on ${HOSTNAME} <${USER}@${HOST_FQDN}>"
	TO="To: $MAILTO"
	SUBJECT="Subject: $(printf "$SFORMAT" "$1" $2 2>/dev/null | head -n 1)"

	echo -e "$FROM\r\n$TO\r\n$SUBJECT\r\n" | cat - "$3" | $MAILER
}


# parse cmdline options
while getopts ":s:m:f:qlnh" OPT; do
	case "$OPT" in
		s)
			MAILER="$OPTARG"
			;;
		m)
			MAILTO="$OPTARG"
			;;
		f)
			SFORMAT="$OPTARG"
			;;
		q)
			QUIET=1
			;;
		n)
			NOEMPTY=1
			;;
		l)
			NOLOG=1
			;;
		h)
			print_usage
			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG." >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done
shift $(( $OPTIND - 1 ))
CMD="$@"

# fail if no command given
if [ -z "$1" ]; then
	echo "error: missing argument."
	print_usage
	exit 1
fi

# create output buffer
LOG="$(mktemp)"
[ -z "$LOG" ] && exit 1

# execute COMMAND, capture output and exit code
$CMD &> "$LOG"
ERR=$?

# forward output to controlling instance (e.g. journal) if not disabled
LOG_LINES=$(wc -l "$LOG" | cut -d ' ' -f 1)
if [ $NOLOG -eq 0 ] && [ $LOG_LINES -gt 0 ]; then
	cat "$LOG"
fi

# notify if required
if (( ($ERR == 0  && $LOG_LINES != 0 && $QUIET == 0) || \
	($ERR != 0 && $LOG_LINES != 0) || \
	($ERR != 0 && $LOG_LINES == 0 && $NOEMPTY == 0) )); then
	mail "$CMD" $ERR "$LOG"
fi

# clean up
rm -f "$LOG"

exit $ERR
