#!/bin/bash

# This script works only on some devices

read -p "New bluetooth MAC address?: " mac

# MAC validation
if ! [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
    echo "Invalid MAC address"
    exit 1
fi

reversed_mac=$(echo "$mac" | sed 's/:/ /g' | awk '{ for (i=NF; i>=1; i--) printf "%s%s", $i, (i==1 ? "" : " "); print "" }')
sudo systemctl stop bluetooth
sudo hciconfig $INTERFACE_BT up
sudo hcitool -i $INTERFACE_BT cmd 0x3f 0x001 $reversed_mac
sudo hciconfig $INTERFACE_BT down
sudo hciconfig $INTERFACE_BT up
sudo systemctl start bluetooth
hcitool dev
