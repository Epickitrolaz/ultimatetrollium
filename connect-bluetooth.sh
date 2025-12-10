#!/bin/bash

read -p "scan timeout?: " timeout

echo -e "\nScanning...\n"

# Setup
setup_pipe=$(mktemp -u)
mkfifo "$setup_pipe"

{
        echo "select $INTERFACE_BT"
        echo "power on"
        echo "scan off"
        echo "scan on"
        sleep "$timeout"

        echo "quit"
} > "$setup_pipe" &

devices=$(bluetoothctl < "$setup_pipe" | sed 's/\x1b\[[0-9;]*m//g')

rm "$setup_pipe"

echo "Scan results:"
echo "$devices" | grep "\[NEW\] Device"

read -p "Enter MAC to connect to: " mac
echo -e "\nConnecting to $mac...\n"

connection_log=$(bluetoothctl <<EOF | sed 's/\x1b\[[0-9;]*m//g'
select $INTERFACE_BT
connect $mac
EOF
)

echo $connection_log
