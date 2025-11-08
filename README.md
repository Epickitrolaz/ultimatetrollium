# ultimatetrollium
A collection of simple bash scripts for the raspberry pi made to simplify running wifi/bluetooth attacks using ssh.

Note: Some scripts were not made by me. 

Carwhisperer: https://trifinite.org/stuff/carwhisperer

wifijammer: https://github.com/hash3liZer/wifijammer

OneShot-Extended: https://github.com/chickendrop89/OneShot-Extended

AppleJuice: https://github.com/ECTO-1A/AppleJuice

How to setup?
```
sudo apt update
sudo apt install git -y

git clone https://github.com/PixelGames987/ultimatetrollium/
cd ultimatetrollium

./setup.sh
```

Websites for dns spoofing can easily be created using an AI like ChatGPT or Gemini and running it on port 80.


The setup script installs:
```
build-essential bluez libbluetooth-dev sox nmap aircrack-ng network-manager reaver bluez mdk3 wpa-supplicant iw pixiewps, neovim, hostapd, dnsmasq
carwhisperer
tailscale (optional)
kismet
wifijammer
OneShot-Extended
```


TODO list:
- Fix kismet
- add target client deauth
- add evil portal functionality
- migrate to airmon-ng
- add a way to connect to bluetooth devices
