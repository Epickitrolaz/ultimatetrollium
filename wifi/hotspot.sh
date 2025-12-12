#!/bin/bash

# Some parts of this script were vibe coded

echo -e "\nYou need to run this file AFTER running dns-spoof.sh\n"

CONF_DIR="/tmp/hotspot"
HOSTAPD_CONF="$CONF_DIR/hostapd.conf"
DNSMASQ_CONF="$CONF_DIR/dnsmasq.conf"
WIFI_IFACE_FILE="$CONF_DIR/wifi_iface.dat" # File to store running interface name

check_if_running() {
    if [ -d "$CONF_DIR" ]; then
        return 0 # running
    else
        return 1 # not running
    fi
}

# Stop hostapd, dnsmasq, and clean up configurations.
stop_hotspot() {
    echo "[*] Stopping hotspot..."

    sudo pkill hostapd
    sudo pkill dnsmasq

    echo "[*] Flushing iptables rules..."
    sudo iptables -F
    sudo iptables -t nat -F

    # Read the interface name that was used before
    if [ -f "$WIFI_IFACE_FILE" ]; then
        WIFI_IFACE=$(cat "$WIFI_IFACE_FILE")
        echo "[*] Resetting Wi-Fi interface: $WIFI_IFACE"
        sudo ip addr flush dev "$WIFI_IFACE"
        sudo ip link set "$WIFI_IFACE" down
        sleep 1
        sudo ip link set "$WIFI_IFACE" up
    else
        echo "[!] Warning: Could not find the interface file. You may need to reset it manually."
    fi
    
    sudo rm -rf "$CONF_DIR"
    echo "[*] Hotspot stopped!"
}

# Function to start the hotspot
start_hotspot() {
    echo "[*] Setting up hotspot: SSID=$SSID, IFACE=$WIFI_IFACE, INTERNET=$INTERNET_IFACE"
    
    sudo mkdir -p "$CONF_DIR"
    sudo pkill hostapd 2>/dev/null
    sudo pkill dnsmasq 2>/dev/null
    
    # Store the Wi-Fi interface name for later
    echo "$WIFI_IFACE" | sudo tee "$WIFI_IFACE_FILE" > /dev/null

    # Configure hostapd (made by chatgpt)
    echo "[*] Configuring hostapd..."
    cat <<EOF | sudo tee "$HOSTAPD_CONF" >/dev/null
interface=$WIFI_IFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF
    # Add password configuration if a password was provided
    if [ -n "$PASSWORD" ]; then
        cat <<EOF | sudo tee -a "$HOSTAPD_CONF" >/dev/null
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF
    fi

    # Configure dnsmasq
    echo "[*] Configuring dnsmasq..."
    cat <<EOF | sudo tee "$DNSMASQ_CONF" >/dev/null
interface=$WIFI_IFACE
dhcp-range=192.168.50.2,192.168.50.100,255.255.255.0,12h
server=8.8.8.8
server=1.1.1.1
EOF

    # Configure interface
    echo "[*] Configuring network interface: $WIFI_IFACE"
    sudo ip addr flush dev "$WIFI_IFACE"
    sudo ip link set "$WIFI_IFACE" down
    sudo ip link set "$WIFI_IFACE" up
    sudo ip addr add 192.168.50.1/24 dev "$WIFI_IFACE"

    # Configure NAT if an internet interface was provided
    if [ -n "$INTERNET_IFACE" ]; then
        echo "[*] Setting up NAT via $INTERNET_IFACE..."
        sudo iptables -t nat -A POSTROUTING -o "$INTERNET_IFACE" -j MASQUERADE
        sudo iptables -A FORWARD -i "$INTERNET_IFACE" -o "$WIFI_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
        sudo iptables -A FORWARD -i "$WIFI_IFACE" -o "$INTERNET_IFACE" -j ACCEPT
        # Enable IP forwarding
        sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
    else
        echo "[*] No internet interface specified."
    fi

    # Start services
    echo "[*] Starting dnsmasq..."
    sudo dnsmasq --conf-file="$DNSMASQ_CONF" --no-daemon --log-async &
    
    echo "[*] Starting hostapd..."
    sudo hostapd "$HOSTAPD_CONF" -B

    echo "[*] Hotspot started."
    echo "    SSID: $SSID"
    echo "    IP Address: 192.168.50.1"
}

if check_if_running; then
    echo "Hotspot running."
    read -rp "Do you want to stop it? [y/N]: " choice
    case "$choice" in 
      y|Y )
        stop_hotspot
        ;;
      * )
        echo "Exiting..."
        exit 0
        ;;
    esac
else
    echo "No hotspot running."
    
    WIFI_IFACE=${INTERFACE}

    read -rp "Internet interface? (leave empty for no internet): " INTERNET_IFACE

    while [ -z "$SSID" ]; do
        read -rp "SSID?: " SSID
        if [ -z "$SSID" ]; then
            echo "SSID cannot be empty."
        fi
    done

    read -rp "Password? (leave empty for no passowrd): " PASSWORD
    
    if [ -n "$PASSWORD" ] && [ ${#PASSWORD} -lt 8 ]; then
        echo "Password is less than 8 characters. Many devices won't connect"
    fi
    
    start_hotspot
fi
