#!/bin/bash
# The setup script for Raspberry Pi OS (Trixie)
set -e

SCRIPT_DIR="$(pwd)"

echo $SCRIPT_DIR

echo -e "\n[*] Updating package list...\n"
sudo apt update
echo -e "\n[*] Full system update...\n"
sudo apt full-upgrade -y

echo -e "\n[*] Installing WiFi/Bluetooth attack tools and dependencies...\n"
sudo apt install build-essential bluez libbluetooth-dev sox nmap aircrack-ng network-manager reaver bluez mdk4 iw pixiewps nano neovim hostapd dnsmasq python3-dev libnl-route-3-dev libnl-genl-3-dev libpcap-dev libev-dev libnl-3-dev gpsd gpsd-clients tmux -y

echo -e "\n[*] Building the carwhisperer exploit...\n"
cd "$SCRIPT_DIR/.scripts/carwhisperer"
make
mkdir -p "output"
cd "$SCRIPT_DIR"

read -p "Do you want to install tailscale? (Y/n): " tailscale
if [ "${tailscale^^}" != "N" ]; then
    if ! command -v tailscale &> /dev/null; then
        echo -e "\n[*] Installing tailscale...\n"
        curl -fsSL https://tailscale.com/install.sh | sh
        echo -e "\n[*] Tailscale installed\n"
    else
        echo -e "\n[*] Tailscale already installed, skipping installation.\n"
    fi
    sudo systemctl enable tailscaled --now
    
    TAILSCALE_CONF="/etc/sysctl.d/99-tailscale.conf"
    if ! sudo grep -q 'net.ipv4.ip_forward = 1' "$TAILSCALE_CONF"; then
        echo 'net.ipv4.ip_forward = 1' | sudo tee -a "$TAILSCALE_CONF"
    else
        echo "net.ipv4.ip_forward already configured."
    fi
    if ! sudo grep -q 'net.ipv6.conf.all.forwarding = 1' "$TAILSCALE_CONF"; then
        echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a "$TAILSCALE_CONF"
    else
        echo "net.ipv6.conf.all.forwarding already configured."
    fi
    sudo sysctl -p "$TAILSCALE_CONF"
fi

echo -e "\n[*] All dependencies installed and carwhisperer built.\n"

# This makes the connection between the raspberry pi and a phone more stable
echo -e "\n[*] Disabling wlan0 power management...\n"
WIFI_POWERSAVE_CONF="/etc/NetworkManager/conf.d/disable-wifi-powersave.conf"
if [ ! -f "$WIFI_POWERSAVE_CONF" ] || ! sudo grep -q "wifi.powersave = 2" "$WIFI_POWERSAVE_CONF"; then
    cat <<EOF | sudo tee "$WIFI_POWERSAVE_CONF" > /dev/null
[connection]
wifi.powersave = 2
EOF
    echo "WiFi power management configuration applied."
else
    echo "WiFi power management already configured."
fi

echo -e "\n[*] Installing kismet...\n"

KEYRING_PATH="/etc/apt/keyrings/kismet-archive-keyring.gpg"
SOURCES_LIST_PATH="/etc/apt/sources.list.d/kismet.list"

if [ -f "$SOURCES_LIST_PATH" ] && sudo grep -q "kismetwireless.net" "$SOURCES_LIST_PATH"; then
    echo "Kismet repository already configured."
    sudo apt update
else
    echo "Adding Kismet repository..."
    sudo mkdir -p /etc/apt/keyrings

    wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key | sudo gpg --dearmor -o "$KEYRING_PATH"
    
    echo "deb [signed-by=$KEYRING_PATH] https://www.kismetwireless.net/repos/apt/release/$(lsb_release -cs) $(lsb_release -cs) main" | sudo tee "$SOURCES_LIST_PATH" > /dev/null

    sudo apt update
    echo "Kismet repository added successfully."
fi

echo -e "\n[*] Installing Kismet package...\n"
sudo apt install kismet -y

echo -e "\n[*] Adding Kismet GPS config entry...\n"
sudo sh -c 'grep -qxF "gps=gpsd:host=localhost,port=2947" /etc/kismet/kismet.conf || echo "gps=gpsd:host=localhost,port=2947" >> /etc/kismet/kismet.conf'

echo -e "\n[*] Disabling Kismet service from starting on boot...\n"
sudo systemctl disable kismet

echo -e "\n[*] Kismet installation complete."


echo -e "\n[*] Setting up wifijammer.py\n"
WIFIJAMMER_VENV_PATH="$SCRIPT_DIR/.scripts/wifijammer/.venv"
if [ ! -d "$WIFIJAMMER_VENV_PATH" ]; then
    python -m venv "$WIFIJAMMER_VENV_PATH"
    echo "wifijammer.py virtual environment created."
else
    echo "wifijammer.py virtual environment already exists."
fi
"$WIFIJAMMER_VENV_PATH/bin/python" -m pip install scapy

cd /usr/lib/aarch64-linux-gnu
sudo ln -s -f libc.a liblibc.a
cd $SCRIPT_DIR

echo -e "\n[*] wifijammer.py ready to use\n"

echo -e "\n[*] Setting up dhcp-starvation.c\n"
gcc -o ".scripts/dhcp-starvation/dhcp-starvation" ".scripts/dhcp-starvation/dhcp-starvation.c"
echo -e "\n[*] dhcp-starvation.c ready to use\n"

echo -e "\n[*] Setting up pixie-all\n"
PIXIEALL_VENV_PATH="$SCRIPT_DIR/.scripts/pixie-all/venv"
if [ ! -d "$PIXIEALL_VENV_PATH" ]; then
    python -m venv "$PIXIEALL_VENV_PATH"
    echo "pixie-all virtual environment created."
else
    echo "pixie-all virtual environment already exists."
fi
"$PIXIEALL_VENV_PATH/bin/python" -m pip install -r "$SCRIPT_DIR/.scripts/pixie-all/requirements.txt" 


APPLEJUICE_PATH="$SCRIPT_DIR/.scripts/applejuice"

echo -e "\n[*] Setting up AppleJuice...\n"
python -m venv "$APPLEJUICE_PATH"/.venv
"$APPLEJUICE_PATH"/.venv/bin/python -m pip install git+https://github.com/pybluez/pybluez.git#egg=pybluez
"$APPLEJUICE_PATH"/.venv/bin/python -m pip install -r "$APPLEJUICE_PATH"/requirements.txt

echo -e "\n[*] AppleJuice set up.\n"


PROBE_SCANNER_PATH="$SCRIPT_DIR/.scripts/probe-scanner"

echo -e "\n[*] Setting up probe-scanner...\n"
python -m venv "$PROBE_SCANNER_PATH"/.venv
"$PROBE_SCANNER_PATH"/.venv/bin/python -m pip install -r "$PROBE_SCANNER_PATH"/requirements.txt

echo -e "\n[*] Probe-scanner set up.\n"


mkdir -p wifi/captured

read -p "Which wlan device will you be using? (eg. wlan1): " interface
read -p "Which hci device will you be using? (eg. hci0): " bt_interface
sudo iwconfig
read -p "Copy and paste your hotspot's mac address/bssid (to not be targeted by the wifi deauther): " mac

add_or_update_bashrc_export() {
    local var_name="$1"
    local var_value="$2"
    local line_to_add="export ${var_name}=${var_value}"
    local bashrc_file="${HOME}/.bashrc"

    if grep -q "export ${var_name}=" "$bashrc_file"; then
        # If the variable exists, update its value
        sed -i "/^export ${var_name}=/c\\${line_to_add}" "$bashrc_file"
        echo "Updated ${var_name} in ~/.bashrc"
    else
        # If the variable doesn't exist, add it
        echo "$line_to_add" >> "$bashrc_file"
        echo "Added ${var_name} to ~/.bashrc"
    fi
}

add_or_update_bashrc_export INTERFACE "${interface}"
add_or_update_bashrc_export INTERFACE_BT "${bt_interface}"
add_or_update_bashrc_export MAC "\"${mac}\""

source ~/.bashrc

# TODO: add gpsd configuration
KISMET_CONF="/etc/kismet/kismet.conf"
KISMET_SOURCE_LINE="source=${interface}"
if sudo grep -q "^source=" "$KISMET_CONF"; then
    # If any source line exists, update it to the new interface
    sudo sed -i "/^source=/c\\${KISMET_SOURCE_LINE}" "$KISMET_CONF"
    echo "Updated Kismet source interface to ${interface}."
else
    # If no source line exists, add it
    sudo sh -c "echo \"${KISMET_SOURCE_LINE}\" >> \"$KISMET_CONF\""
    echo "Added Kismet source interface ${interface}."
fi

echo -e "\n[*] Restarting NetworkManager... This will temporarily disconnect the raspberry pi from your hotspot\n"
sudo systemctl restart NetworkManager
echo "[*] Setup completed, scripts ready for use."
