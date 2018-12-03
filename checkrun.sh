#!/bin/bash

# checkrun.sh
# ---------------
# Cron-style mailing wrapper for systemd .timer units
# (C) 2018 Alexander Koch <mail@alexanderkoch.net>
#
# Released under the terms of the MIT License, see 'LICENSE'

# defaults
MAILER="sendmail"
MAILTO="$(id -un)"
VERBOSE=0
IGNRET=0

# usage information
function print_usage() {
	echo "usage: $0 [OPTIONS] COMMAND"
	echo "options:"
	echo "    -s CMD     use CMD as mailer (default: sendmail)"
	echo "    -m MAILTO  set recipient for notification mail (default: \$USER)"
	echo "    -v         send command output even on exit code 0"
	echo "    -i         ignore exit code, notify on output only"
	echo "    -h         display this usage information"
}

# parse cmdline options
while getopts ":s:m:vih" OPT; do
	case $OPT in
		s)
			MAILER="$OPTARG"
			;;
		m)
			MAILTO="$OPTARG"
			;;
		v)
			VERBOSE=1
			;;
		i)
			IGNRET=1
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

# fail if no command given
if [ -z "$1" ]; then
	echo "error: missing argument."
	print_usage
	exit 1
fi

# execute COMMAND, capture output
LOG="$(mktemp)"
$@ &> "$LOG"
ERR=$?

# evaluate return value
if [ $ERR -ne 0 ] && [ $IGNRET -ne 1 ]; then
	echo -e "Subject: '$@' FAILED ($ERR)\r\n" | cat - "$LOG" | $MAILER "$MAILTO"
	cat "$LOG"
	exit $ERR
fi

# notify if output was given and verbose mode selected or exit code ignored
if [ $(wc -l "$LOG" | cut -d ' ' -f 1) -gt 0 ]; then
	if [ $VERBOSE -eq 1 ] || [ $IGNRET -eq 1 ]; then
		echo -e "Subject: '$@'\r\n" | cat - "$LOG" | $MAILER "$MAILTO"
	fi
fi

# clean up
rm -f "$LOG"

exit 0
