#!/bin/bash

source logging.sh

# 1st argument: root filesystem mount point
rootfsmntpnt="$1" # = "/" when installing rootfs overlay on a running system

if [ -z "${rootfsmntpnt}" ]; then
  logging_error "rootfs_install.sh: missing argument 'rootfsmntpnt'"
  exit 1
fi

#-----------------------------------------------------------------------------#

logging_header "configure networking"

logging_message "rootfs mount point: ${rootfsmntpnt}"

# make all network interfaces (including eth0) managed by NetworkManager
# Ubuntu > 17.10
# either remove:
#apt remove netplan.io
# or disable it
echo "disable netplan.io"
if [ ! -d ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/ ]; then
  mkdir -pv ${rootfsmntpnt}/etc/cloud/cloud.cfg.d
fi
echo "network: {config: disabled}" > ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/97-disable-network-config.cfg
ls -lh ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/
cat ${rootfsmntpnt}/etc/cloud/cloud.cfg.d/97-disable-network-config.cfg
#systemctl disable systemd-networkd.service
#systemctl mask systemd-networkd.service
#systemctl status systemd-networkd.service | cat
# that basically did the trick!! =>...
mv -v /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused

sleep 2

#-----------------------------------------------------------------------------#
