#!/bin/bash

cleanup() {
    echo -e "\n\nStopping all mdk4 processes"
    sudo killall mdk4 >/dev/null 2>&1
    rm -f "/tmp/aps_list.txt"
    exit 0
}

trap cleanup INT

mode=$(iwconfig "${INTERFACE}" | grep -o "Mode:Managed")
if [ "${mode}" = "Mode:Managed" ]; then
        sudo ifconfig ${INTERFACE} down
        sudo iwconfig ${INTERFACE} mode monitor
        sudo ifconfig ${INTERFACE} up
fi

echo -e "\nWarning: use this script with caution! The raspberry pi can overheat while managing this many processes without proper cooling.\n"

read -p "ssid?: " ssid_prefix
read -p "count?: " count
read -p "enable mac hopping? (Y/n): " hop_macs

if [[ "$hop_macs" =~ ^[Yy]$ ]]; then
    for i in $(seq 1 "$count"); do
      ssid="${ssid_prefix}${i}"
      random_mac=$(printf '02:%02x:%02x:%02x:%02x:%02x' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])
      echo "Advertising SSID: '$ssid' with MAC: $random_mac"
      # Launch mdk4 in the background
      sudo mdk4 "$INTERFACE" b -n "$ssid" -m "$random_mac" &
      sleep 0.1 # Small delay so the driver can handle it, 0.1s is the bare minimum it csn handle
    done
    echo "All workers running. Press Ctrl+C to stop."
    # Wait for any background process to finish, or for a signal like Ctrl+C
    wait
else
    AP_FILE="/tmp/aps_list.txt"
    echo "Creating SSID list"
    rm -f "$AP_FILE"
    for i in $(seq 1 "$count"); do
      echo "${ssid_prefix}${i}" >> "$AP_FILE"
    done
    echo "Press ctrl+c to stop"
    sudo mdk4 "$INTERFACE" b -f "$AP_FILE"
fi

# Run cleanup at the end in case mdk4 finishes on its own
cleanup
