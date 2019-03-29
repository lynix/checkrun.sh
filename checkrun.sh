#!/bin/bash

# checkrun.sh
# ---------------
# Cron-style mailing wrapper for systemd .timer units
# (C) 2018, 2019 Alexander Koch <mail@alexanderkoch.net>
#
# Released under the terms of the MIT License, see 'LICENSE'

# defaults
MAILER="sendmail -t"
MAILTO="$(id -un)"
SFORMAT="%s (returned %d)"
QUIET=0

# usage information
function print_usage() {
	echo "usage: $0 [OPTIONS] COMMAND"
	echo "options:"
	echo "    -s CMD     use CMD as mailer (default: sendmail)"
	echo "    -m MAILTO  set recipient for notification mail (default: \$USER)"
	echo "    -f FORMAT  set format string for mail subject (default: \"$SFORMAT\")"
	echo "    -q         do not send command output on exit code 0"
	echo "    -h         display this usage information"
}

# sendmail interface
function mail() {
	FROM="From: checkrun <$USER@$HOSTNAME>"
	TO="To: $MAILTO"
	SUBJECT="Subject: $(printf "$SFORMAT" "$1" $2 2>/dev/null | head -n 1)"

	echo -e "$FROM\r\n$TO\r\n$SUBJECT\r\n" | cat - "$3" | $MAILER
}


# parse cmdline options
while getopts ":s:m:f:qh" OPT; do
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

# forward any output to controlling instance (e.g. journal)
LOG_LINES=$(wc -l "$LOG" | cut -d ' ' -f 1)
if [ $LOG_LINES -gt 0 ]; then
	cat "$LOG"
fi

# notify if required
if (( $ERR != 0 || ($LOG_LINES != 0 && $QUIET == 0) )); then
	mail "$CMD" $ERR "$LOG"
fi

# clean up
rm -f "$LOG"

exit $ERR
