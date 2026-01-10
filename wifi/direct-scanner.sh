#!/bin/bash

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Monitor")
if [ "${mode}" = "Mode:Monitor" ]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode managed
        sudo ifconfig ${INTERFACE} up
fi

../.scripts/direct-scanner/.venv/bin/python ../.scripts/direct-scanner/main.py
