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
systemctl restart sshd.service
systemctl status sshd.service | cat

# or simply do $ sudo passwd root ... manually 

# update system
echo "update system"

# disable unattended upgrades
systemctl disable unattended-upgrades.service
systemctl stop unattended-upgrades.service
systemctl status unattended-upgrades.service | cat

apt-get update && apt-get upgrade -y

# install docker and git
apt-get update && apt-get install -y docker.io git

# install net-tools, iproute, etc.
apt-get update && apt-get install -y net-tools iproute2

# install NetworkManager command line tool
apt-get update && apt-get install -y network-manager

# disable cloud-init
systemctl disable cloud-config.service
systemctl disable cloud-final.service
systemctl disable cloud-init-local.service
systemctl disable cloud-init.service

# customize motd
#
# References:
# https://motd.ubuntu.com
# https://raymii.org/s/tutorials/Disable_dynamic_motd_and_motd_news_spam_on_Ubuntu_18.04.html
# https://ownyourbits.com/2017/04/05/customize-your-motd-login-message-in-debian-and-ubuntu/
systemctl disable motd-news.timer
systemctl status motd-news.timer | cat
cp -v rootfs/etc/profile.d/motd.sh /etc/profile.d/
chmod 644 /etc/profile.d/motd.sh
# rm -v /var/run/motd.dynamic
# rm -rvf /etc/update-motd.d/
sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news
sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' /etc/pam.d/sshd

# update os-release
if [ ! -f /etc/os-release-base ]; then
  cp -v /etc/os-release /etc/os-release-base
fi
vrsn=$(cat config.yaml | grep version | awk -F ':' '{print $2}' | tr -d ' ')
gthsh=$(git rev-parse HEAD)
gthshshort=$(git rev-parse --short HEAD)
gtbranch=$(git rev-parse --abbrev-ref HEAD)
tsdate=$(date +%Y%m%dT%H%M%S)
#basename=$(cat /etc/os-release-base | grep "^NAME=" | awk -F '=' '{print $2}' | tr -d '" ')
#basevrsn=$(cat /etc/os-release-base | grep "^VERSION=" | awk -F '=' '{print $2}' | tr -d '" ')
#NAME=ReswarmOS (based on ${basename} ${basevrsn})
osrls=$(cat << EOF
NAME=ReswarmOS
VERSION=v${vrsn}-${gthshshort}-${tsdate}
ID=reswarmos
VERSION_ID=${gthsh}
PRETTY_NAME="ReswarmOS-${vrsn}"
EOF
)
echo -e "${osrls}" > /etc/os-release

# set default device name
hostnamectl set-hostname "reswarm-device"

