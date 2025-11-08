import argparse
import sys
import os
from scapy.all import *
from mac_vendor_lookup import MacLookup, VendorNotFoundError

# A set to keep track of unique probe requests
probed_networks = set()
mac_lookup = MacLookup()

def check_root():
    if os.geteuid() != 0:
        print("[-] This script requires root privileges.")
        sys.exit(1)

def packet_handler(packet, mac_filter=None):
    if packet.haslayer(Dot11ProbeReq):
        # Extract source MAC address
        client_mac = packet.addr2

        # Apply a MAC filter
        if mac_filter and client_mac.lower() != mac_filter.lower():
            return

        # SSID information
        if packet.haslayer(Dot11Elt):
            try:
                essid = packet[Dot11Elt].info.decode()
                if not essid:
                    essid = "Broadcast (Hidden)"
            except UnicodeDecodeError:
                essid = packet[Dot11Elt].info

            # Create a unique key for a set
            probe_key = (client_mac, essid)

            if probe_key not in probed_networks:
                probed_networks.add(probe_key)

                vendor = "Unknown Vendor"
                try:
                    vendor = mac_lookup.lookup(client_mac)
                except (KeyError, VendorNotFoundError):
                    pass

                # Print in a spreadsheet-like format
                print(f"{client_mac:<20} {vendor:<45} {essid}")

def setup_vendor_lookup(force_update=False):
    if force_update:
        print("[*] User requested a database update. This may take a moment...")
        try:
            mac_lookup.update_vendors()
            print("[+] Vendor database updated successfully.")
        except Exception as e:
            print(f"[!] Could not update vendor database: {e}")
            sys.exit(1)
    else:
        try:
            mac_lookup.lookup("00:00:00:00:00:00")
        except VendorNotFoundError:
            print("[!] Vendor database not found. Attempting download...")
            try:
                mac_lookup.update_vendors()
                print("[+] Vendor database downloaded successfully.")
            except Exception as e:
                print(f"[!] Could not download vendor database: {e}")
                sys.exit(1)
        except Exception as e:
            print(f"[!] An error occurred: {e}")
            sys.exit(1)

def main():
    check_root()

    parser = argparse.ArgumentParser(
        description="Wi-Fi Probe Request Scanner.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("-i", "--interface", required=True, help="The wireless interface to use (must be in monitor mode).")
    parser.add_argument("-m", "--mac-filter", help="Filter output to a specific client MAC address.")
    parser.add_argument("--update-vendors", action="store_true", help="Force an update of the MAC vendor database from the internet.")
    
    args = parser.parse_args()
    
    setup_vendor_lookup(force_update=args.update_vendors)

    print(f"[*] Starting probe scanner on interface {args.interface}...")
    if args.mac_filter:
        print(f"[*] Filtering for client MAC: {args.mac_filter}")
    print("[*] Press CTRL+C to stop.\n")

    # Print the table header
    print(f"{'Client MAC':<20} {'Vendor':<45} {'Target ESSID'}")
    print(f"{'='*19:<20} {'='*44:<45} {'='*20}")

    try:
        # Start sniffing
        sniff(iface=args.interface, prn=lambda pkt: packet_handler(pkt, args.mac_filter), store=0)
    except KeyboardInterrupt:
        print("\n[*] Stopping scanner.")
    except Exception as e:
        print(f"\n[!] An error occurred: {e}")
        print("[!] Ensure the interface is in monitor mode.")

if __name__ == "__main__":
    main()
