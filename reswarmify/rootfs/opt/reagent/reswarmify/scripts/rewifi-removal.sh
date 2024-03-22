#!/bin/bash

# source the configuration parser
. /opt/reagent/reswarmify/scripts/reparse-ini.sh
# check existing connections
nmconns=$(nmcli connection)
nmconnsexst=$(echo "${nmconns}" | grep "${ssid}")

# No SSID found
if [ -z "${ssid}" ]; then
  echo "No SSID was found, skipping..."
  exit 0
fi

if [ -z "${nmconnsexst}" ]; then

  echo "wifi connection does not exist, skipping..."
else
  nmconnid=$(nmcli -t -f NAME,UUID con | grep "${nmconnsexst}" | cut -d ":" -f2)

  nmcli connection delete "${nmconnid}"

  echo "deleted connection with ID: ${nmconnid}"
fi
