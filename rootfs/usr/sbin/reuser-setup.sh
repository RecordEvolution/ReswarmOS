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
echo "setting up account for user ${usernm} with password ${passwd}"
homedir=$(readini ${configfile} user HOME)
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
#fi

# check for new user
cat /etc/shadow | grep ${usernm}
ls -lhd ${homedir}

# enable ssh login for this user
echo "AllowUsers ${usernm}" >> /etc/ssh/sshd_config
cat /etc/ssh/sshd_config | grep ${usernm}

# employ .vimrc configuration
cp -v /root/.vimrc ${homedir}/.vimrc

