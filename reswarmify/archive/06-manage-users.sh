#!/bin/bash

source logging.sh

# 1st argument: rootfs mountpoint
#   a) installation on running system: rootfsmntpnt="/"
#   b) installation via loopback device, e.g. rootfsmntpnt="/media/jack/writable/"
rootfsmntpnt="$1"

if [ -z "${rootfsmntpnt}" ]; then
  logging_error "$0: root filesystem mount point argument is missing"
  exit 1
fi

#-----------------------------------------------------------------------------#

logging_header "manage and add users"

logging_message "rootfs mountpoint"
echo "rootfsmntpnt: ${rootfsmntpnt}"

# allow for (ssh) root login with password
echo "set up password for root and allow for root login"
sshd_conf=$(echo "${rootfsmntpnt}/etc/ssh/sshd_config.d/root.conf" | sed 's/\/\//\//g')
sshd_conf_root=$(cat << EOF
PermitRootLogin yes
PasswordAuthentication yes
EOF
)
echo "${sshd_conf_root}" > ${sshd_conf}
echo -e "${sshd_conf}:\n $(cat ${sshd_conf})"

# make sure to include the previous configuration in sshd_config
sshdInc=$(cat ${rootfsmntpnt}/etc/ssh/sshd_config | grep "^Include")
if [ -z "${sshdInc}" ]; then
  echo "Include statement missing in sshd_config => adding it"
  #echo "Include /etc/ssh/sshd_config.d/*.conf" | sudo tee -a /etc/ssh/sshd_config > /dev/null
  echo -e "\nInclude /etc/ssh/sshd_config.d/*.conf\n" >> /etc/ssh/sshd_config
fi

# generate random salt
salt=$(date +%FT%T.%N | md5sum | base64 | head -c12)
echo "salt: ${salt}"

# choose root password
rootpasswd="reswarm"

# generate shadow root entry
rootshadow=$(echo ${rootpasswd} | openssl passwd -6 -salt ${salt} -stdin)
echo "passwd: ${rootshadow}"

# replace root entry in shadow file
usrshadwfl=$(echo "${rootfsmntpnt}/etc/shadow" | sed 's/\/\//\//g')
usrshadw=$(cat ${usrshadwfl} | grep -v root)
usrshadwroot=$(cat ${usrshadwfl} | grep root)
usrshadwrootent=$(echo ${usrshadwroot} | awk -F ':' -v var="$rootshadow" '{print $1":"var":"$3":"$4":"$5":"$6":"$7":"$8":"$9}')
echo "/etc/shadow:root: ${usrshadwrootent}"
echo -e "${usrshadwrootent}\n${usrshadw}" > ${usrshadwfl}

# restart sshd.service
echo "restarting sshd.service"
systemctl restart sshd.service
systemctl status sshd.service | cat

sleep 2

#-----------------------------------------------------------------------------#
