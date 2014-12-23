#!/bin/bash

function apiawk() {
curl -s https://identity.api.rackspacecloud.com/v2.0/tokens \
-X 'POST' -d '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"%USERNAME%", "apiKey":"%APIKEY%"}}}' \
-H "Content-Type: application/json" | grep -Po '"token":.*?[^\\]",' | awk 'BEGIN { FS = "\"" } ; { print $6 }'
} 

authtoken=$(apiawk)



function check_state() {
	curl -s -X GET -H "X-Auth-Token: $1"  \
	https://monitoring.api.rackspacecloud.com/v1.0/%ACCOUNT NUMBER%/entities/%ENTITY ID%/alarms/%ALARM ID%/notification_history/%CHECK ID%?limit=1 \
	| grep -Po '"state":.*?[^\\]",' | awk ' BEGIN { FS = "\"" } ; { print $4 } '
}

checkresult=$(check_state $authtoken) 


servercount=$(cat /tmp/autoscaling_servers)

if [ $checkresult == OK ]; then
	echo "All OK"
	if [ $servercount > 2 ]; then
		echo "Lowering Server Count"
		curl -X POST %AUTOSCALE WEB HOOK (Decrease)%
		if [ $servercount < 1 ]; then
			echo "No Servers remain"
		else
			expr $servercount - 1 > /tmp/autoscaling_servers
		fi
		echo "Servers Remaining: $servercount"
	else
		echo "No servers created by script"
	fi
elif [ $checkresult == WARNING ]; then
	echo "Montioring in Warning state, leaving servers."
	echo "There are $servercount servers"
elif [ $checkresult == CRITICAL ]; then
	echo "Monitoring in Critical state, creating servers."
	if [ $servercount = 0 ]; then
		echo "Autoscale should be creating a server"
		expr $servercount + 1 > /tmp/autoscaling_servers
	elif [ $servercount > 1 ]; then
		echo "Inceasing Server Count"
		curl -X POST %AUTOSCALE WEB HOOK (Increase)%
		expr $servercount + 1 > /tmp/autoscaling_servers
		echo "Servers Created (Total): $servercount"
	else
		echo "No servers created by script"
	fi
else
	echo "Something that was not expected was returned, doing nothing..."
fi

