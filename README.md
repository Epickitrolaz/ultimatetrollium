# ultimatetrollium
A collection of simple bash scripts for the raspberry pi made to simplify cybersecurity research using ssh.

Some scripts were not made by me. 

Carwhisperer: https://trifinite.org/stuff/carwhisperer

wifijammer: https://github.com/hash3liZer/wifijammer

OneShot-Extended: https://github.com/chickendrop89/OneShot-Extended

AppleJuice: https://github.com/ECTO-1A/AppleJuice

## How to setup?
```
sudo apt update
sudo apt install git -y

git clone https://github.com/PixelGames987/ultimatetrollium/
cd ultimatetrollium

./setup.sh
```

## How to update?
```
git pull

./setup.sh
```

## Notes for users:
Websites for dns spoofing can easily be created using an AI like ChatGPT or Gemini and running it on port 80.
If a script is not detecting a device even though it's plugged in, try rebooting.

## TODO list:
- Add kismet gpsd support
- Migrate to airmon-ng
- Add a way to connect to bluetooth devices (in development)
