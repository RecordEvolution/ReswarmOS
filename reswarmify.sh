#!/bin/bash

welcome=$(cat << EOF

Welcome to Reswarmify!

-------------------------------------------------------------------------------

Reswarmify turns (almost) any operation system image into a Reswarm 
compatible OS by adding the Reswarm layer

Base image requirements:
1. linux based distribution
2. two partition scheme: 
    - vfat boot partition
    - ext4 root filesystem partition
3. features systemd as init system

Please note, that this script only works on a Linux host with root privileges!

EOF
)

echo -e "${welcome}\n"

#-----------------------------------------------------------------------------#

# check host and privileges
hostkind=$(uname)
if [ "${hostkind}" != "Linux" ]; then
  echo "$(tput setaf 1)Sorry, you're not working on a Linux host" >&2
  echo "$(tput sgr0)"
  exit 1
fi
if [ "$(whoami)" != "root" ]; then
  echo "$(tput setaf 1)Sorry, root privileges are required" >&2
  echo "$(tput sgr0)"
  exit 1
fi

# choose base image
baseimage="$1"
if [ -z "${baseimage}" ]; then
  echo "since you did not provide any image path, please enter base image path"
  read -p "base image path: " bimage
else
  bimage="${baseimage}"
fi
echo "using base image:$(tput setaf 2) ${bimage}$(tput sgr0)"
if [ ! -f "${bimage}" ]; then
  echo "$(tput setaf 1)baseimage file does not seem to exist, please check the path$(tput sgr0)" >&2
  exit 1
fi

# choose final image
finalimage="$2"
if [ -z "${finalimage}" ]; then
  echo "you didn't provide the final image name, please provide one (include the path where to store it)"
  read -p "final image path: " fimage
else
  fimage="${finalimage}"
fi
echo "using final image:$(tput setaf 2) ${fimage}$(tput sgr0)"
fimagedir=$(dirname ${fimage})
if [ ! -d ${fimagedir} ]; then
  echo "$(tput setaf 1)directory for final image does not exist: ${fimagedir}, please place the final image in an existing directory$(tput sgr0)" >&2
  exit 1
fi

#-----------------------------------------------------------------------------#

# copy baseimage as finalimage
echo ""
cp -v ${bimage} ${fimage}

# mount image as loopback device
lpdev=$(losetup -a | grep ${fimage})
if [ -z "${lpdev}" ]; then
  echo -e "\nmounting image as loopback device...\n"
  losetup -fP ${fimage}
  lpdev=$(losetup -a | grep ${fimage})
else
  echo -e "\nimage is already mounted\n"
fi
echo ${lpdev}
lpdevpath=$(echo ${lpdev} | awk -F ':' '{print $1}')
lpdevname=$(echo ${lpdevpath} | awk -F '/' '{print $NF}')
echo "mounted as ${lpdevpath}"
lsblk | grep ${lpdevname}

# trying to determine the image's architecture
echo -e "\ntrying to determine the image's architecture..."
sleep 2
echo "mounting partition ${lpdevpath}p2"
udisksctl mount --block-device "${lpdevpath}p2"
rootfsmntpnt=$(lsblk  -lo path,mountpoint | grep "${lpdevpath}p2" | awk '{print $2}')
echo "mount point of root filesystem: ${rootfsmntpnt}"
archtype=$(file ${rootfsmntpnt}/bin/bash | awk -F ',' '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
echo "image's architecture appears to be: $(tput setaf 2)${archtype}$(tput sgr0)"

#-----------------------------------------------------------------------------#

# define docker service
dockerservice=$(cat << EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket
Wants=containerd.service

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF
)

dockersocket=$(cat << EOF
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF
)

# Reference:
# https://docs.docker.com/engine/install/binaries/

# docker static binaries:
# https://download.docker.com/linux/static/stable/

# for instance
# https://download.docker.com/linux/static/stable/aarch64/docker-20.10.6.tgz
# tar -xvzf docker-20.10.6.tgz -C docker-20.10.6/

# Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /lib/systemd/system/docker.service.

# generate download URL for docker binaries (latest version 2021-05-18)
if [ ! -z "$(echo ${archtype} | grep 'x86-64')" ]; then
  dockerurl="https://download.docker.com/linux/static/stable/aarch64/docker-20.10.6.tgz"
elif [ ! -z "$(echo ${archtype} | grep 'aarch64')" ]; then
  dockerurl="https://download.docker.com/linux/static/stable/aarch64/docker-20.10.6.tgz"
elif [ ! -z "$(echo ${archtype} | grep 'ARM')" ]; then
  dockerurl="https://download.docker.com/linux/static/stable/armhf/docker-20.10.6.tgz"
else
  echo "$(tput setaf 1)unexpected architecture: ${archtype}$(tput sgr0)" >&2
  exit 1 
fi

# TODO install and setup docker on root filesystem

#-----------------------------------------------------------------------------#

# TODO install customization overlay for root filesystem given in ./rootfs/

#-----------------------------------------------------------------------------#

# unmount/detach loopback device
echo -e "\ndetaching/unmouting image...\n"
umount ${lpdevpath}*
losetup -d ${lpdevpath}

echo -e "\n$(tput setaf 2)successfully generated reswarmified version\nof ${bimage}\nas ${fimage}$(tput sgr0)\n" >&2

#-----------------------------------------------------------------------------#
