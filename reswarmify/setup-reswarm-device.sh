#!/bin/bash

# install packages

apt-get update && apt-get upgrade -y
apt-get update && apt-get install -y docker.io vim git
apt-get update && apt-get install -y net-tools iproute2
apt-get update && apt-get install -y wget
apt-get update && apt-get install -y dnsutils
apt-get update && apt-get install -y network-manager
apt-get update && apt-get install -y jq

# rootfs install

rootfsmntpnt="/"

etcdockerdaemonjson=$(cat << EOF
{
  "insecure-registries": [],
  "max-concurrent-downloads": 2,
  "max-concurrent-uploads": 2,
  "max-download-attempts": 3
}
EOF
)

#    if [ ! -d ${rootfsfldir} ]; then
#      echo "required directory ${rootfsfldir} does not exist, creating it"
#      mkdir -pv ${rootfsfldir}
#    fi
#    # add file to root filesystem
#    cp -v ${fl} ${rootfsflpath}

#systemctl enable ${unitfl}
#:systemctl status ${unitfl} | cat


# 06-manage-users.sh

rootfsmntpnt="$1"
if [ -z "${rootfsmntpnt}" ]; then
  exit 1
fi
echo "rootfsmntpnt: ${rootfsmntpnt}"
echo "set up password for root and allow for root login"
sshd_conf=$(echo "${rootfsmntpnt}/etc/ssh/sshd_config.d/root.conf" | sed 's/\/\//\//g')
sshd_conf_root=$(cat << EOF
PermitRootLogin yes
PasswordAuthentication yes
EOF
)
echo "${sshd_conf_root}" > ${sshd_conf}
echo -e "${sshd_conf}:\n $(cat ${sshd_conf})"
sshdInc=$(cat ${rootfsmntpnt}/etc/ssh/sshd_config | grep "^Include")
if [ -z "${sshdInc}" ]; then
  echo "Include statement missing in sshd_config => adding it"
  #echo "Include /etc/ssh/sshd_config.d/*.conf" | sudo tee -a /etc/ssh/sshd_config > /dev/null
  echo -e "\nInclude /etc/ssh/sshd_config.d/*.conf\n" >> /etc/ssh/sshd_config
fi
salt=$(date +%FT%T.%N | md5sum | base64 | head -c12)
echo "salt: ${salt}"
rootpasswd="reswarm"
rootshadow=$(echo ${rootpasswd} | openssl passwd -6 -salt ${salt} -stdin)
echo "passwd: ${rootshadow}"
usrshadwfl=$(echo "${rootfsmntpnt}/etc/shadow" | sed 's/\/\//\//g')
usrshadw=$(cat ${usrshadwfl} | grep -v root)
usrshadwroot=$(cat ${usrshadwfl} | grep root)
usrshadwrootent=$(echo ${usrshadwroot} | awk -F ':' -v var="$rootshadow" '{print $1":"var":"$3":"$4":"$5":"$6":"$7":"$8":"$9}')
echo "/etc/shadow:root: ${usrshadwrootent}"
echo -e "${usrshadwrootent}\n${usrshadw}" > ${usrshadwfl}
echo "restarting sshd.service"
systemctl restart sshd.service
systemctl status sshd.service | cat
sleep 2



# 07-customize-motd.sh

rootfsmntpnt="$1"
if [ -z "${rootfsmntpnt}" ]; then
  exit 1
fi
if [ ! -f "./config.yaml" ]; then
fi
echo "rootfsmntpnt: ${rootfsmntpnt}"
systemctl disable motd-news.timer
systemctl status motd-news.timer | cat
rootfsetcprof=$(echo ${rootfsmntpnt}/etc/profile.d/ | sed 's/\/\//\//g')
cp -v rootfs/etc/profile.d/motd.sh ${rootfsetcprof}
chmod 644 ${rootfsetcprof}/motd.sh
ls -lh ${rootfsetcprof}motd.sh
echo "disable motd-news"
rootfsetcdefmotd=$(echo ${rootfsmntpnt}/etc/default/motd-news | sed 's/\/\//\//g')
sed -i 's/ENABLED=1/ENABLED=0/g' ${rootfsetcdefmotd}
echo "disable pam_motd"
rootfsetcpamdsshd=$(echo ${rootfsmntpnt}/etc/pam.d/sshd | sed 's/\/\//\//g')
sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' ${rootfsetcpamdsshd}
echo "update and customize os-release"
rootfsetcrls=$(echo ${rootfsmntpnt}/etc/os-release | sed 's/\/\//\//g')
rootfsetcrlsbase=$(echo ${rootfsmntpnt}/etc/os-release-base | sed 's/\/\//\//g')
if [ ! -f ${rootfsetcrlsbase} ]; then
  cp -v ${rootfsetcrls} ${rootfsetcrlsbase}
fi
newosrls=$(./reswarmify/os-release.sh)
echo "${newosrls}"
echo "${newosrls}" > ${rootfsetcrls}
echo "set hostname"
hostnamectl set-hostname "reswarm-device"
hostnamectl status
sleep 2



# 08-network-config.sh

rootfsmntpnt="$1" # = "/" when installing rootfs overlay on a running system
if [ -z "${rootfsmntpnt}" ]; then
  exit 1
fi
echo "disable netplan.io"
if [ ! -d ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/ ]; then
  mkdir -pv ${rootfsmntpnt}/etc/cloud/cloud.cfg.d
fi
echo "network: {config: disabled}" > ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/97-disable-network-config.cfg
ls -lh ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/
cat ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/97-disable-network-config.cfg
mv -v /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused
sleep 2



# 09-reagent-reswarm.sh

rootfsmntpnt="$1"
bootmntpnt="$2"
if [ -z "${rootfsmntpnt}" ]; then
  exit 1
fi
if [ -z "${bootmntpnt}" ]; then
  exit 1
fi
echo "rootfsmntpnt: ${rootfsmntpnt}"
echo "bootmntpnt:   ${bootmntpnt}"
reagentdir=$(echo ${rootfsmntpnt}/opt/reagent/ | sed 's/\/\//\//g')
mkdir -pv ${reagentdir}
archtype=$(file ${rootfsmntpnt}/bin/bash | awk -F ',' '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
echo "image's architecture appears to be: $(tput setaf 2)${archtype}$(tput sgr0)"
reswarmcfg="./config.yaml"
reagentcfg=$(cat ${reswarmcfg} | grep -i "^ *reagent" -A150)
if [ ! -z "$(echo ${archtype} | grep 'x86-64')" ]; then
  reagenturl=$(echo "${reagentcfg}" | grep "^ *url:" -A 5 | grep amd64 | awk '{print $2}' | tr -d ' ')
elif [ ! -z "$(echo ${archtype} | grep 'aarch64')" ]; then
  reagenturl=$(echo "${reagentcfg}" | grep "^ *url:" -A 5 | grep arm64 | awk '{print $2}' | tr -d ' ')
elif [ ! -z "$(echo ${archtype} | grep 'ARM')" ]; then
  reagenturl=$(echo "${reagentcfg}" | grep "^ *url:" -A 5 | grep armv7 | awk '{print $2}' | tr -d ' ')
else
  exit 1
fi
echo "gettting (latest) reagent binary"
echo "URL: ${reagenturl}"
wget ${reagenturl} -O ${reagentdir}reagent-latest
chmod u+x ${reagentdir}reagent-latest
fstabpath=$(echo ${rootfsmntpnt}/etc/fstab | sed 's/\/\//\//g')
echo "creating symlink pointing to mountpoint of vfat partition (given by ${fstabpath})"
vfatmntpnt=$(cat ${fstabpath} | grep vfat | awk '{print $2}' | tr -d ' ')
echo "boot partition mount point: ${vfatmntpnt}"
rm -vf ${reagentdir}vfat-mount
ln -s ${vfatmntpnt} ${reagentdir}vfat-mount
ls -lh ${reagentdir}vfat-mount
echo "copy default device configuration"
cp -v ./boot/device.ini ${bootmntpnt}/
ls -lh ${bootmntpnt}/
sleep 2


