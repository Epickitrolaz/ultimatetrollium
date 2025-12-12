#!/bin/bash

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Monitor")

if [ "${mode}" = "Mode:Monitor" ]; then
        echo "Connect to a network first"
        exit 1
fi

if iwconfig "${INTERFACE}" | grep -q "ESSID:off/any"; then
        echo "Connect to a network first"
        exit 1
fi

read -p "packets/sec?: " packets

sudo .scripts/dhcp-starvation/dhcp-starvation $INTERFACE $packets
