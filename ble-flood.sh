#!/bin/bash

rm -f /tmp/scan.txt > /dev/null

sudo systemctl restart bluetooth # Restarts the bluetooth service to avoid hcitool errors
sleep 2
sudo rfkill unblock bluetooth # Unlock bluetooth if rfkill disables it (useful for external bluetooth adapters)
sudo btmgmt --index $INTERFACE_BT power on # Power on the interface

echo "\nScanning...\n"
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
}' /tmp/scan.txt
echo -e "\n\n"
