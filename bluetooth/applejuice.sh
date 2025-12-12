#!/bin/bash

sudo rfkill unblock bluetooth

cd .scripts/applejuice

echo "$(cat << EOF
Please select a message number or enter "random".

1: Airpods
2: Airpods Pro
3: Airpods Max
4: Airpods Gen 2
5: Airpods Gen 3
6: Airpods Pro Gen 2
7: PowerBeats
8: PowerBeats Pro
9: Beats Solo Pro
10: Beats Studio Buds
11: Beats Flex
12: BeatsX
13: Beats Solo3
14: Beats Studio3
15: Beats Studio Pro
16: Beats Fit Pro
17: Beats Studio Buds+
18: AppleTV Setup
19: AppleTV Pair
20: AppleTV New User
21: AppleTV AppleID Setup
22: AppleTV Wireless Audio Sync
23: AppleTV Homekit Setup
24: AppleTV Keyboard
25: AppleTV 'Connecting to Network'
26: Homepod Setup
27: Setup New Phone
28: Transfer Number to New Phone
29: TV Color Balance
EOF
)"

read -p "option?: " message

sudo .venv/bin/python app.py -d ${message}
