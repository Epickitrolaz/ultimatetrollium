#!/bin/bash

echo -e "\n1 - start kismet\n2 - stop kismet"
read -p "choice? (1/2): " choice

case "$choice" in
    	1)
		sudo systemctl start kismet
		echo "Kismet running on 0.0.0.0:2501"
                ;;
	2)
		sudo systemctl stop kismet
		echo "Kismet stopped"
                ;;
    	*)
	        echo "Enter 1 or 2"
        	;;
esac
