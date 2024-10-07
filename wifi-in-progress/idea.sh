#!/bin/bash

# Get available Wi-Fi networks
available_networks=$(nmcli dev wifi list | awk '{print $2}' | tail -n +2)

# Get known Wi-Fi networks (saved)
known_networks=$(nmcli connection show | grep wifi | awk '{print $1}')

# Compare both lists and show common networks
echo "Known and available Wi-Fi networks:"
for network in $known_networks; do
    if echo "$available_networks" | grep -q "$network"; then
        echo "$network"
    fi
done
