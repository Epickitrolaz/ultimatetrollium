#!/bin/bash

echo "Starting..."

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Managed")

if [ "${mode}" = "Mode:Managed" ]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode monitor
        sudo ifconfig ${INTERFACE} up
fi

sleep 5 # Give the interface time start up

sudo .scripts/wifijammer/.venv/bin/python .scripts/wifijammer/wifijammer.py -i $INTERFACE --verbose --filter "${MAC}"
