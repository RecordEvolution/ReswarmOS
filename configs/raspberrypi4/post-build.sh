#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# add static/distro configuration
DSTCNF="/home/distro-setup"

# configure wlan0 and dhcp
cp ${DSTCNF}/interfaces ${TARGET_DIR}/etc/network/interfaces
cp ${DSTCNF}/dhcpcd.conf ${TARGET_DIR}/etc/dhcpcd.conf

# resizing of root filesystem during first boot
cp ${DSTCNF}/S22expand-rootpart ${TARGET_DIR}/etc/init.d/S22expand-rootpart
chmod 755 ${TARGET_DIR}/etc/init.d/S22expand-rootpart
cp ${DSTCNF}/S23expand-rootfs ${TARGET_DIR}/etc/init.d/S23expand-rootfs
chmod 755 ${TARGET_DIR}/etc/init.d/S23expand-rootfs

# mount boot partition
mkdir -p ${TARGET_DIR}/boot
echo "/dev/mmcblk0p1  /boot           vfat    defaults        0       2" >> ${TARGET_DIR}/etc/fstab

# add (default) dynamic/device configuration file and device-config init.d scripts
DEVCNF="/home/device-setup"
cp -v ${DEVCNF}/read-ini.sh ${TARGET_DIR}/usr/bin/read-ini.sh
chmod 755 ${TARGET_DIR}/usr/bin/read-ini.sh
cp -v ${DEVCNF}/S18set-hostname ${TARGET_DIR}/etc/init.d/S18set-hostname
cp -v ${DEVCNF}/S33set-wpasupplicant ${TARGET_DIR}/etc/init.d/S33set-wpasupplicant
cp -v ${DEVCNF}/S87add-user ${TARGET_DIR}/etc/init.d/S87add-user
cp -v ${DEVCNF}/S96reswarm-agent ${TARGET_DIR}/etc/init.d/S96reswarm-agent
chmod 755 ${TARGET_DIR}/etc/init.d/S*

# configuration of interactive (ssh) access to ReswarmOS
ASSCNF="/home/assets"
cp -v ${ASSCNF}/motd.sh ${TARGET_DIR}/etc/profile.d/motd.sh
chmod 644 ${TARGET_DIR}/etc/profile.d/motd.sh
cp -v ${ASSCNF}/shell-prompt.sh ${TARGET_DIR}/etc/profile.d/shell-prompt.sh
chmod 644 ${TARGET_DIR}/etc/profile.d/shell-prompt.sh
# evtl. allow root login
sshdopt="PermitRootLogin yes"
sshdpath="${TARGET_DIR}/etc/ssh/sshd_config"
sshdoptch=$(cat ${sshdpath} | grep -v "^#" | grep "${sshdopt}")
if [ -z "${sshdoptch}" ]; then
  echo "${sshdopt}" >> ${sshdpath}
fi

# copy default device to boot partition
cp -v ${DEVCNF}/device-config.ini ${BINARIES_DIR}/device-config.ini

