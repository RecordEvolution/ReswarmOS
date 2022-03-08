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
usernm=$(echo "${usernm}" | sed -e 's/\(.*\)/\L\1/g' | sed -e 's/^[^a-z]//g' | grep -oP "[a-z0-9-]" | tr -d '\n' | sed 's/$/\n/g')
echo "using cleaned username '${usernm}' agreeing with NAME_REGEX"

# check for existing user
userExst=$(cat /etc/shadow | grep ${usernm})
if [ -z "${userExst}" ]; then

  echo "setting up account for user ${usernm} with password ${passwd}"
  #homedir=$(readini ${configfile} user HOME)
  homedir="/home/${usernm}/"
  #group=$(readini ${configfile} user GROUP)
  dfshell=$(readini ${configfile} user SHELL)
  groups=$(readini ${configfile} user GROUPS)
  echo "homedir:${homedir}"
  echo "shell:${dfshell}"
  echo "groups:${groups}"

  # generate random salt for encrypted password in /etc/shadow
  salt=$(head -c 128 /dev/urandom | base64 | tr -d '=/+' | head -c12)
  echo "using salt $salt"
  passwdshadw=$(echo $passwd | openssl passwd -6 -salt $salt -stdin)
  echo "${passwdshadw}"

  # create actual user account with required home directory, group, shell, etc.
  #if [ -z "${group}" ]; then
  #  useradd --home-dir ${homedir} --groups ${groups} --create-home --password \'${passwdshadw}\' --shell ${dfshell} ${usernm}
  #else
  useradd --home-dir ${homedir} --groups ${groups} --create-home --password "${passwdshadw}" --shell ${dfshell} --user-group ${usernm}
  chown ${usernm}:${usernm} ${homedir}
  #fi

  # check for new user
  cat /etc/shadow | grep ${usernm}
  ls -lhd ${homedir}

  # enable ssh login for this user
  sshdcnf="/etc/ssh/sshd_config"
  cat ${sshdcnf} | grep -v AllowUsers > "${sshdcnf}.tmp"
  echo "AllowUsers ${usernm}" >> "${sshdcnf}.tmp"
  mv -v "${sshdcnf}.tmp" ${sshdcnf}

  # if reswarm-mode is enabled => require public-key for authentication
  if [ -f /opt/reagent/reswarm-mode ]; then
    mkdir -pv ${homedir}/.ssh/
    chown ${usernm}:${usernm} ${homedir}/.ssh
    cat /root/id.pub > ${homedir}/.ssh/authorized_keys
    chown ${usernm}:${usernm} ${homedir}/.ssh/authorized_keys
    chmod 600 ${homedir}/.ssh/authorized_keys
    echo -e "$(cat /etc/ssh/sshd_config | grep -v 'PubkeyAuthentication\|PasswordAuthentication')\nPubkeyAuthentication yes\nPasswordAuthentication no\n" > /etc/ssh/sshd_config.tmp
    mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
  fi

else

  echo "user ${usernm} already exists"

fi

