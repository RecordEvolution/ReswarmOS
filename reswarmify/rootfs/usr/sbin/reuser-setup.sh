#!/bin/bash

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

# enable ssh login for this user
sshdcnf="/etc/ssh/sshd_config"
cat ${sshdcnf} | grep -v AllowUsers > "${sshdcnf}.tmp"
echo "AllowUsers ${USER}" >> "${sshdcnf}.tmp"
mv -v "${sshdcnf}.tmp" ${sshdcnf}

# if reswarm-mode is enabled => require public-key for authentication
if [ -f /opt/reagent/reswarm-mode ]; then
  mkdir -pv ${homedir}/.ssh/
  chown ${USER}:${USER} ${homedir}/.ssh
  cat /root/id.pub > ${homedir}/.ssh/authorized_keys
  chown ${USER}:${USER} ${homedir}/.ssh/authorized_keys
  chmod 600 ${homedir}/.ssh/authorized_keys
  echo -e "$(cat /etc/ssh/sshd_config | grep -v 'PubkeyAuthentication\|PasswordAuthentication')\nPubkeyAuthentication yes\nPasswordAuthentication no\n" > /etc/ssh/sshd_config.tmp
  mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
fi

