#!/bin/sh

# source the configuration parser
. /usr/sbin/reparse-ini.sh

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
passwd=$(readini ${configfile} wifi PASSWD)
echo "using SSID ${ssid} with password ${passwd}"

# set up connection and try to connect instantly
#nmcli device wifi connect "${ssid}" password "${passwd}"

# add new WiFi access point (without connecting)
nmcli connection add type wifi con-name "${ssid}" ifname wlan0 ssid "${ssid}"
nmcli connection modify "${ssid}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${passwd}"
# nmcli connection modify "${ssid}" connection.autoconnect yes
# nmcli connection up "${ssid}"
