#!/bin/bash

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Managed")
if [ "${mode}" = "Mode:Managed" ]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode monitor
        sudo ifconfig ${INTERFACE} up
fi

read -p "Client MAC filter? (leave empty to sniff all requests): " mac_filter

if [ -z $mac_filter ]; then
	sudo ../.scripts/probe-scanner/.venv/bin/python ../.scripts/probe-scanner/main.py -i $INTERFACE
else
	sudo ../.scripts/probe-scanner/.venv/bin/python ../.scripts/probe-scanner/main.py -i $INTERFACE -m $mac_filter
fi
	
