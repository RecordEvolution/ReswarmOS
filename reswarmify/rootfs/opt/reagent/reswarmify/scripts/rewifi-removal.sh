#!/bin/bash

# source the configuration parser
. /opt/reagent/reswarmify/scripts/reparse-ini.sh
# check existing connections
nmconns=$(nmcli connection)
nmconnsexst=$(echo "${nmconns}" | grep "${ssid}")

if [ -z "${nmconnsexst}" ]; then

  echo "wifi connection does not exist, skipping..."
else
  nmconnid=$(nmcli -t -f NAME,UUID con | grep "${nmconnsexst}" | cut -d ":" -f2)

  nmcli connection delete "${nmconnid}"
fi
