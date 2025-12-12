#!/bin/bash

if ! command -v tailscale &> /dev/null; then
        echo "Tailscale not found, install it from the tailscale.com website"
        exit 1
fi

# the simplest script here
sudo tailscale down
