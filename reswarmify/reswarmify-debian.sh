#!/bin/bash

# allow for root login with password
echo "set up password for root and allow for root login"
sshd_conf=/etc/ssh/sshd_config.d/root.conf
sshd_conf_root=$(cat << EOF
PermitRootLogin yes
PasswordAuthentication yes
EOF
)
echo "${sshd_conf_root}" > ${sshd_conf}
salt=$(date +%FT%T.%N | base64 | head -c12)
echo "salt: ${salt}"
rootpasswd="reswarm"
rootshadow=$(echo ${rootpasswd} | openssl passwd -6 -salt ${salt} -stdin)
echo "passwd: ${rootshadow}"
usrshadwfl=/etc/shadow
usrshadw=$(cat ${usrshadwfl} | grep -v root)
usrshadwroot=$(cat ${usrshadwfl} | grep root)
usrshadwrootent=$(echo ${usrshadwroot} | awk -F ':' -v var="$rootshadow" '{print $1":"var":"$3":"$4":"$5":"$6":"$7":"$8":"$9}')
echo "root etc/shadow: ${usrshadwrootent}"
echo -e "${usrshadwrootent}\n${usrshadw}" > ${usrshadwfl}

# or simply to $ sudo passwd root ... manually 

# update system
echo "update system"

# disable unattended upgrades
systemctl disable unattended-upgrades.service
systemctl status unattended-upgrades.service | cat

apt-get update && apt-get upgrade -y

# install docker and git
apt-get update && apt-get install -y docker.io git

# install net-tools, iproute, etc.
apt-get update && apt-get install -y net-tools iproute2

# install NetworkManager command line tool
apt-get update && apt-get install -y network-manager

# customize motd
# https://ownyourbits.com/2017/04/05/customize-your-motd-login-message-in-debian-and-ubuntu/

