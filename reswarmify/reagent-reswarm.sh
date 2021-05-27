#!/bin/bash

source logging.sh

# 1st argument: rootfs mountpoint
#   a) installation on running system: rootfsmntpnt="/"
#   b) installation via loopback device, e.g. rootfsmntpnt="/media/jack/writable/"
rootfsmntpnt="$1"
# 2nd argument: vfat/boot mountpoint
#   a) running system: =/boot or =/boot/firmware
#   b) loopback device: e.g. =/media/jack/boot-os/
bootmntpnt="$2"

if [ -z "${rootfsmntpnt}" ]; then
  logging_error "$0: root filesystem mount point argument is missing"
  exit 1
fi

if [ -z "${bootmntpnt}" ]; then
  logging_error "$0: vfat/boot filesystem mount point argument is missing"
  exit 1
fi

#-----------------------------------------------------------------------------#

logging_header "set up reagent and reswarm configuration"

logging_message "rootfs and boot mountpoints"
echo "rootfsmntpnt: ${rootfsmntpnt}"
echo "bootmntpnt:   ${bootmntpnt}"

# create reagent directory
reagentdir=$(echo ${rootfsmntpnt}/opt/reagent/ | sed 's/\/\//\//g')
mkdir -pv ${reagentdir}

# determine architecture
archtype=$(file ${rootfsmntpnt}/bin/bash | awk -F ',' '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
echo "image's architecture appears to be: $(tput setaf 2)${archtype}$(tput sgr0)"

# get reagent configuration from config.yaml
reswarmcfg="./config.yaml"
reagentcfg=$(cat ${reswarmcfg} | grep -i "^ *reagent" -A150)

# extract suitable URL for architecture and pull binary
if [ ! -z "$(echo ${archtype} | grep 'x86-64')" ]; then
  reagenturl=$(echo "${reagentcfg}" | grep "^ *url:" -A 5 | grep amd64 | awk '{print $2}' | tr -d ' ')
elif [ ! -z "$(echo ${archtype} | grep 'aarch64')" ]; then
  reagenturl=$(echo "${reagentcfg}" | grep "^ *url:" -A 5 | grep arm64 | awk '{print $2}' | tr -d ' ')
elif [ ! -z "$(echo ${archtype} | grep 'ARM')" ]; then
  reagenturl=$(echo "${reagentcfg}" | grep "^ *url:" -A 5 | grep armv7 | awk '{print $2}' | tr -d ' ')
else
  logging_error "$0: unexpected architecture: ${archtype}"
  exit 1
fi
echo "gettting (latest) reagent binary"
echo "URL: ${reagenturl}"
wget ${reagenturl} -O ${reagentdir}reagent-latest
chmod u+x ${reagentdir}reagent-latest

# create link to point to .reswarm configuration or device.ini file
fstabpath=$(echo ${rootfsmntpnt}/etc/fstab | sed 's/\/\//\//g')
echo "creating symlink pointing to mountpoint of vfat partition (given by ${fstabpath})"
vfatmntpnt=$(cat ${fstabpath} | grep vfat | awk '{print $2}' | tr -d ' ')
echo "boot partition mount point: ${vfatmntpnt}"
rm -vf ${reagentdir}vfat-mount
ln -s ${vfatmntpnt} ${reagentdir}vfat-mount
ls -lh ${reagentdir}vfat-mount

# copy default device.ini configuration
echo "copy default device configuration"
cp -v ./boot/device.ini ${bootmntpnt}/
ls -lh ${bootmntpnt}/

sleep 2

#-----------------------------------------------------------------------------#
