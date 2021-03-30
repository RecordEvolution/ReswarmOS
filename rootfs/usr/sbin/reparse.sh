#!/bin/sh

# include JSON parser
# . /usr/sbin/reparse-json.sh

# check for (latest) *.reswarm device configuration file on /boot partition
reswarmcfg=$(ls -t /boot/*.reswarm | head -n1)

# reswarm mode
if [ ! -z ${reswarmcfg} ]; then

  echo "latest *.reswarm configuration ${reswarmcfg}"

  # extract host configuration parameters from *.reswarm configuration file
  # hostname=$(parsejsongetkey ${reswarmcfg} name)
  # username=$(parsejsongetkey ${reswarmcfg} swarm_owner_name)
  # userpasswd=$(parsejsongetkey ${reswarmcfg} secret)
  # wifissid=$(parsejsongetkey ${reswarmcfg} wlanssid)
  # wifipasswd=$(parsejsongetkey ${reswarmcfg} password)
  hostname=$(cat ${reswarmcfg} | /usr/bin/jq ' . | ."name"')
  username=$(cat ${reswarmcfg} | /usr/bin/jq ' . | ."swarm_owner_name"')
  userpasswd=$(cat ${reswarmcfg} | /usr/bin/jq ' . | ."secret"')
  wifissid=$(cat ${reswarmcfg} | /usr/bin/jq ' . | ."wlanssid"')
  wifipasswd=$(cat ${reswarmcfg} | /usr/bin/jq ' . | ."password"')
  echo "hostname:   ${hostname}"
  echo "username:   ${username}"
  echo "userpasswd: ${userpasswd}"
  echo "wifissid:   ${wifissid}"
  echo "wifipasswd: ${wifipasswd}"

  # insert host configuration into /boot/device.ini
  deviceini=$(cat << EOF
[device]
HOSTNAME = ${hostname}

[user]
USERNAME = ${username}
PASSWD   = ${userpasswd}
HOME     = "/home/$(echo ${username} | tr -d "\"")"
GROUP    = ${username}
SHELL    = "/bin/bash"
GROUPS   = "sudo"

[wifi]
SSID     = ${wifissid}
PASSWD   = ${wifipasswd}
EOF
)
  echo -e "${deviceini}" > /boot/device.ini

# standalone/free mode
else

  echo "no *.reswarm configuration found in /boot"

fi
