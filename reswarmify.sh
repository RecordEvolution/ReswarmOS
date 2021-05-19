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
  echo "$(tput setaf 1)directory for final image does not exist: ${fimagedir}, please place the final image in an existing directory" >&2
  exit 1
fi

# mount image as loopback device
echo "mouting image..."
losetup -fP ${bimage}
lpdev=$(losetup -a | grep ${bimage})
echo ${lpdev}
lsblk

