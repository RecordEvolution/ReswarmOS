#!/bin/bash

source logging.sh

# 1st argument: root filesystem mount point
rootfsmntpnt="$1" # = "/" when installing rootfs overlay on a running system

if [ -z "${rootfsmntpnt}" ]; then
  logging_error "rootfs_install.sh: missing argument 'rootfsmntpnt'"
  exit 1
fi

#-----------------------------------------------------------------------------#

logging_header "configure partitions"

logging_message "rootfs mount point: ${rootfsmntpnt}"

# adjust partition labels in /etc/fstab (ensure consistency with cmdline.txt and actual labels!!)
fstabpath=$(echo "${rootfsmntpnt}/etc/fstab" | sed 's/\/\//\//g')
sed -i 's/LABEL=writable/LABEL=rootfs/g' ${fstabpath}
sed -i 's/LABEL=system-boot/LABEL=ReswarmOS/g' ${fstabpath}

# change label in cmdline.txt TODO configure on non-running system
vfatmntpnt=$(cat ${fstabpath} | awk '{print $2}' | tr -d '\n ')
sed -i 's/root=LABEL=writable/root=LABEL=rootfs/g' ${vfatmntpnt}/cmdline.txt
cat ${vfatmntpnt}/cmdline.txt

sleep 2

#-----------------------------------------------------------------------------#
