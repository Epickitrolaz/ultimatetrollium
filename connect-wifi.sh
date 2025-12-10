#!/bin/bash

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Monitor")

if [ "${mode}" = "Mode:Monitor" ]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode managed
        sudo ifconfig ${INTERFACE} up
        echo "Re-run the script after network scan is complete"
	exit 0
fi

read -p "ssid?: " ssid

read -s -p "password? (leave blank for open networks): " password
echo

if [ -z "${password}" ]; then
    sudo nmcli dev wifi connect "${ssid}" ifname "${INTERFACE}"
else
    sudo nmcli dev wifi connect "${ssid}" password "${password}" ifname "${INTERFACE}"
fi

if [ $? -eq 0 ]; then
  echo "Successfully connected to $ssid."
else
  echo "Connection to $ssid failed."
  exit 1
fi

exit 0
