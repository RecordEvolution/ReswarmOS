#!/bin/sh

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

# set up user account according to given configuration file
usernm=$(readini ${configfile} user USERNAME)
passwd=$(readini ${configfile} user PASSWD)
if [ -z "${usernm}" ]; then
  echo "empty USERNAME found" >&2
  exit 1
fi
if [ -z "${passwd}" ]; then
  echo "empty PASSWD found" >&2
  exit 1
fi

# cleaning up username to agree with NAME_REGEX (/etc/adduser.conf)
# usernm=$(echo "${usernm}" | sed -e 's/\(.*\)/\L\1/g' | sed -e 's/^[^a-z]//g' | grep -oP "[a-z0-9-]" | tr -d '\n' | sed 's/$/\n/g')

# check for existing user
userExst=$(cat /etc/shadow | grep ${usernm})
if [ -z "${userExst}" ]; then
  echo "IronFlock user not found, skipping user removal..."
else
  homedir="/home/${usernm}/"

  echo "Removing the IronFlock user: ${username}"

  killall -u ${usernm}
  userdel -f ${usernm}
  rm -rf ${homedir}

  echo "Restoring SSH configuration"

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.tmp

  # Also handle legacy SSHD configs
  sed -i "/^AllowUsers $usernm$/d; /^PubkeyAuthentication yes$/d; /^PasswordAuthentication no$/d" /etc/ssh/sshd_config.tmp
  
  sed -i "/Match User $usernm/,/^$/d" /etc/ssh/sshd_config.tmp

  mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
fi