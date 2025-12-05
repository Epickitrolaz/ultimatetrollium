#!/bin/bash

read -p "new mac address?: " mac

reversed_mac=$(echo "$mac" | sed 's/:/ /g' | awk '{ for (i=NF; i>=1; i--) printf "%s%s", $i, (i==1 ? "" : " "); print "" }')

sudo systemctl stop bluetooth
sudo hciconfig $INTERFACE_BT up

sudo hcitool -i $INTERFACE_BT cmd 0x3f 0x001 $reversed_mac

sudo hciconfig $INTERFACE_BT down
sudo hciconfig $INTERFACE_BT up
sudo systemctl start bluetooth

hcitool dev 
