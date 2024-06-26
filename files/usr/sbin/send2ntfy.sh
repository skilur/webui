#!/bin/sh

plugin="ntfy"

. /usr/sbin/common-plugins

show_help() {
	echo "Usage: $0 [-s server_url] [-p priority] [-t title] [-b body] [-u user -l login] [-i bool] [-v] [-h]
  By default the saved values will be used unless specified
  OPT  Name     Description					Saved Value
  -s   server   URL or IP of server (including port and topic)	$ntfy_url
  -p   priority (min low default high max)			$ntfy_msg_priority
  -t   title    title for notification				$ntfy_msg_title
  -b   body     notification body				$ntfy_msg_body
  -u   user							$ntfy_username
  -l   login							$ntfy_password
  -i   image    attach image (true/false)			$ntfy_attach_snapshot
  -v            Verbose output.
  -h            Show this help.
"
	exit 0
}

# override config values with command line arguments
while getopts s:p:t:b:u:l:i:vh flag; do
	case "$flag" in
		s)
			ntfy_url=$OPTARG
			;;
		p)
			ntfy_msg_priority=$OPTARG
			;;
		t)
			ntfy_msg_title=$OPTARG
			;;
		u)
			ntfy_user=$OPTARG
			;;
		l)
			ntfy_password=$OPTARG
			;;
		b)
			ntfy_msg_body=$OPTARG
			;;
		i)
			ntfy_attach_snapshot=$OPTARG
			;;
		v)
			verbose="true"
			;;
		h|*)
			show_help
			;;
	esac
done

[ "false" = "$ntfy_enabled" ] && log "Sending to NTFY is disabled." && exit 10

# validate mandatory values
[ -z "$ntfy_url" ] && log "NTFY url not found in config" && exit 11

# assign default values if not set
[ -z "$ntfy_msg_body" ] && ntfy_msg_body="test message"

command="curl --silent --verbose -XPOST"
command="${command} --connect-timeout ${curl_timeout}"
command="${command} --max-time ${curl_timeout}"

if [ ! -z "$ntfy_username" ] && [ ! -z "$ntfy_password" ]; then		# if login is specified add it
	command="${command} -u $ntfy_username:$ntfy_password"
fi

if [ ! -z "$ntfy_msg_title" ]; then			# if title is specified add it
	command="${command} -H \"Title:$ntfy_msg_title\""
fi
command="${command} -H \"X-Priority: $ntfy_msg_priority\""
command="${command} -H \"Message: ${ntfy_msg_body}\""

if [ "true" == "$ntfy_attach_snapshot" ]; then
	snapshot=/tmp/snapshot4cron.jpg
	snapshot4cron.sh
	command="${command} -T ${snapshot} -H \"Filename: snapshot.jpg\""
fi

command="${command} ${ntfy_url}"

log "$command"
logcontent=$(eval "$command" 2>&1 )
echo "$logcontent" >>"$LOG_FILE"

[ "true" = "$verbose" ] && echo "$command"\n"$logcontent"

exit 0

