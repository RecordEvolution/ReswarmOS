#!/bin/bash

# source the configuration parser
. /opt/reagent/reswarmify/scripts/reparse-ini.sh

# check configuration file argument
configfile="$1"
if [ -z ${configfile} ]; then
  echo "no configuration file given (e.g. device.ini)" >&2
  exit 1
fi

if [ ! -f ${configfile} ]; then
  echo "configuration file ${configfile} does not exist" >&2
  exit 1
fi

# set up WiFi connection according to given configuration file
ssid=$(readini ${configfile} wifi SSID)

# check existing connections
nmconns=$(nmcli connection)
nmconnsexst=$(echo "${nmconns}" | grep "${ssid}")

# No SSID found
if [ -z "${ssid}" ]; then
  echo "No networking configuration was found, skipping..."
  exit 0
fi

if [ -z "${nmconnsexst}" ]; then
  echo "Network connection does not exist, skipping..."
else
  nmconnid=$(nmcli -t -f NAME,UUID con | grep "${ssid}" | cut -d ":" -f2)

  nmcli connection delete "${nmconnid}"

  echo "Deleted network connection with SSID: ${ssid}"
fi
