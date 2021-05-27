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

if [ ! -f "./config.yaml" ]; then
  logging_error "$0: config.yaml not found (check working directory)"
fi

#-----------------------------------------------------------------------------#

logging_header "customize motd and os-release"

logging_message "rootfs mountpoint"
echo "rootfsmntpnt: ${rootfsmntpnt}"

# customize motd
#
# References:
# https://motd.ubuntu.com
# https://raymii.org/s/tutorials/Disable_dynamic_motd_and_motd_news_spam_on_Ubuntu_18.04.html
# https://ownyourbits.com/2017/04/05/customize-your-motd-login-message-in-debian-and-ubuntu/

# disable various systemd units
systemctl disable motd-news.timer
systemctl status motd-news.timer | cat

# put custom motd.sh in place
rootfsetcprof=$(echo ${rootfsmntpnt}/etc/profile.d/ | sed 's/\/\//\//g')
cp -v rootfs/etc/profile.d/motd.sh ${rootfsetcprof}
chmod 644 ${rootfsetcprof}/motd.sh
ls -lh ${rootfsetcprof}motd.sh

# rm -v /var/run/motd.dynamic
# rm -rvf /etc/update-motd.d/

echo "disable motd-news"
rootfsetcdefmotd=$(echo ${rootfsmntpnt}/etc/default/motd-news | sed 's/\/\//\//g')
sed -i 's/ENABLED=1/ENABLED=0/g' ${rootfsetcdefmotd}
echo "disable pam_motd"
rootfsetcpamdsshd=$(echo ${rootfsmntpnt}/etc/pam.d/sshd | sed 's/\/\//\//g')
sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' ${rootfsetcpamdsshd}

# update os-release
echo "update and customize os-release"
rootfsetcrls=$(echo ${rootfsmntpnt}/etc/os-release | sed 's/\/\//\//g')
rootfsetcrlsbase=$(echo ${rootfsmntpnt}/etc/os-release-base | sed 's/\/\//\//g')
if [ ! -f ${rootfsetcrlsbase} ]; then
  cp -v ${rootfsetcrls} ${rootfsetcrlsbase}
fi
newosrls=$(./reswarmify/os-release.sh)
echo "${newosrls}"
echo "${newosrls}" > ${rootfsetcrls}

# set default device name
echo "set hostname"
hostnamectl set-hostname "reswarm-device"
hostnamectl status

sleep 2

#-----------------------------------------------------------------------------#
