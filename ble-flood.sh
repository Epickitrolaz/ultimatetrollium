#!/bin/bash

rm -f /tmp/scan.txt > /dev/null

sudo systemctl restart bluetooth # Restarts the bluetooth service to avoid hcitool errors
sleep 2
sudo rfkill unblock bluetooth # Unlock bluetooth if rfkill disables it (useful for external bluetooth adapters)
sudo btmgmt --index $INTERFACE_BT power on # Power on the interface


sudo btmgmt --index $INTERFACE_BT find | tee /tmp/scan.txt # Start the scan


# Format everything
echo -e "\n"
awk '
/dev_found/ {
    if (mac) {
        printf "%-20s %-10s %-5s %-30s\n", mac, type, rssi, (name ? name : "(not available)")
    }
    mac=$2; type=$4; rssi=$6; name="";
}
/name/ {
    sub(/^name /, "");
    name=$0;
}
END {
    if (mac) {
        printf "%-20s %-10s %-5s %-30s\n", mac, type, rssi, (name ? name : "(not available)")
    }
}' /tmp/scan.txt
echo -e "\n\n"
