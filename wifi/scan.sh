#!/bin/bash

echo -e "Choose a scan mode:\n1 - nmcli (used to scan wifi networks to connect to)\n2 - airodump-ng (used to scan wifi networks to run attacks, grab hanshakes, etc.\n"
read -p "scan mode? (1/2): " scan

if [[ "${scan}" != "1" && "${scan}" != "2" ]]; then
	echo "Choose a correct mode"
	exit 1
fi

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Monitor")

if [[ "${scan}" == "1" && "${mode}" = "Mode:Monitor" ]]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode managed
        sudo ifconfig ${INTERFACE} up
	echo "Waiting for the scan to complete..."
	sleep 10

elif [[ "${scan}" == "2" && "${mode}" = "Mode:Managed" ]]; then 
	sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode managed
        sudo ifconfig ${INTERFACE} up
fi

if [ "${scan}" == "1" ]; then
	nmcli dev wifi list ifname ${INTERFACE} --rescan yes

elif [ "${scan}" == "2" ]; then
	read -p "scan 5ghz? (y/N): " band
		if [[ "${band}" == "y" ]]; then
			sudo airodump-ng $INTERFACE --band a
		else
			sudo airodump-ng $INTERFACE --band g
		fi
fi

exit 0
