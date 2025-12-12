#!/bin/bash

echo -e "\nYou need to run this file BEFORE starting a hotspot\n"

read -p "(1 - edit; 2 - revert): " mode

if [[ $mode == "1" ]]; then
	read -p "(1 - nano; 2 - neovim): " editor
	sudo cp /etc/hosts /etc/hosts.bak
	if [[ $editor == "1" ]]; then
		sudo nano /etc/hosts
	elif [[ $editor == "2" ]]; then
		sudo nvim /etc/hosts
	else
		echo "Invalid option"
		exit 1
	fi
elif [[ $mode == "2" ]]; then
	sudo rm -f /etc/hosts
	sudo mv /etc/hosts.bak /etc/hosts
else
	echo "Invalid option"
	exit 1
fi

sudo systemctl restart dnsmasq
