#!/bin/bash

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Monitor")

if [ "${mode}" = "Mode:Monitor" ]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode managed
        sudo ifconfig ${INTERFACE} up
fi

connection=$(nmcli -t -f GENERAL.CONNECTION device show $INTERFACE | cut -d: -f2-)

sudo nmcli con down "$connection"

if [ $? -eq 0 ]; then
  echo "Disconnected from $connection."
else
  echo "Failed to disconnect from $connection."
  exit 1
fi

sudo nmcli con delete "$connection"

if [ $? -eq 0 ]; then
  echo "Deleted connection $connection."
else
  echo "Failed to delete connection $connection."
  exit 1
fi

exit 0
