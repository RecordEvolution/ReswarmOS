#!/bin/sh

# JSON parser
JQ=/usr/bin/jq

# include JSON parser
#. /usr/sbin/reparse-json.sh

# symlink pointing to mount point of vfat partition keeping device configuration
bootDir="/boot"

# check for (latest) *.reswarm device configuration file on vfat partition
reswarmfile=$(ls -t ${bootDir} | grep ".reswarm" | head -n1)
reswarmcfg="$(readlink ${bootDir})/${reswarmfile}"

# define reswarm mode file and soft link to .reswarm configuration
remode=/opt/reagent/reswarm-mode
relink=/opt/reagent/device-config.reswarm

# check reagent binary as well (get latest only)
reagentdir=/opt/reagent/
reagentbin=$(ls -t ${reagentdir} | grep "reagent-" | head -n1)

# set up symlink to general device.ini configuration
ln -svf $(readlink ${bootDir})/device.ini /opt/reagent/device-config.ini

# reswarm mode
if [ ! -z ${reswarmfile} ]; then

  echo "latest *.reswarm configuration ${reswarmcfg}"

  if [ ! -z ${reagentbin} ]; then

    echo "latest reagent binary ${reagentdir}${reagentbin}"

    # activate reswarm mode
    echo "activating reswarm mode"
    touch "${remode}"

  else

    echo "no reagent binary available"

  fi

  # set up symbolic link targeting latest reswarm configuration
  ln -svf ${reswarmcfg} ${relink}

  # extract host configuration parameters from *.reswarm configuration file
  #hostname=$(parsejsongetkey ${reswarmcfg} name)
  #username=$(parsejsongetkey ${reswarmcfg} swarm_owner_name)
  #userpasswd=$(parsejsongetkey ${reswarmcfg} secret)
  #wifissid=$(parsejsongetkey ${reswarmcfg} wlanssid)
  #wifipasswd=$(parsejsongetkey ${reswarmcfg} password)
  hostname=$(cat ${reswarmcfg} | $JQ ' . | ."name"')
  username=$(cat ${reswarmcfg} | $JQ ' . | ."swarm_owner_name"')
  userpasswd=$(cat ${reswarmcfg} | $JQ ' . | ."secret"')
  wifissid=$(cat ${reswarmcfg} | $JQ ' . | ."wlanssid"')
  wifipasswd=$(cat ${reswarmcfg} | $JQ ' . | ."password"')
  echo "hostname:   ${hostname}"
  echo "username:   ${username}"
  echo "userpasswd: ${userpasswd}"
  echo "wifissid:   ${wifissid}"
  echo "wifipasswd: ${wifipasswd}"

  # check validity of configuration
  if [ -z "${hostname}" ]; then
    echo "empty hostname found" >&2
    exit 1
  fi
  if [ -z "${username}/${userpasswd}" ]; then
    echo "empty username/userpasswd found" >&2
    exit 1
  fi
  if [ -z "${wifissid}${wifipasswd}" ]; then
    echo "empty wifissid/wifipasswd found" >&2
    exit 1
  fi

  # insert host configuration into ${bootDir}/device.ini
  # TODO inherit any non-default/additional values from device.ini
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
  echo -e "${deviceini}" > ${bootDir}/device.ini

  # extract private key from reswarm file
  echo -e $(cat ${reswarmcfg} | $JQ ' .authentication.key' | tr -d '"') > /root/key.pem

  # generate corresponding public key
  chmod 600 /root/key.pem
  ssh-keygen -y -f /root/key.pem > /root/id.pub

# standalone/free mode
else

  echo "no *.reswarm configuration found in ${bootDir}"

  # make sure reswarm mode is deactivated and config link removed
  rm -vf ${remode}
  rm -vf ${relink}

fi

