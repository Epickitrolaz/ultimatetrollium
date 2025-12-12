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

ip_cidr=$(ip a show "${INTERFACE}" | grep -Eo 'inet ([0-9]*\.){3}[0-9]*/[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*/[0-9]*' | head -n 1)

echo -e "Choose an attack:\n1 - fast scan\n2 - full scan\n"
read -p "mode? (1/2): " mode

if [ $mode == "1" ]; then
	sudo nmap -T4 "${ip_cidr}" -v
elif [ $mode == "2" ]; then
	sudo nmap -sS -sU -p- -A -T4 "${ip_cidr}" -v
else
	echo -e "Enter a valid mode"
	exit 1
fi

echo -e "\n"
curl --interface ${INTERFACE} ipinfo.io
echo -e "\n"
curl --interface ${INTERFACE} ifconfig.xyz
