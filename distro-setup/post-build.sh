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

# add (default) dynamic/device configuration file and device-config init.d scripts
DEVCNF="/home/device-setup"
cp ${DEVCNF}/device-config.ini ${TARGET_DIR}/etc/device-config.ini
cp ${DEVCNF}/S18set-hostname ${TARGET_DIR}/etc/init.d/S18set-hostname
cp ${DEVCNF}/S33set-wpasupplicant ${TARGET_DIR}/etc/init.d/S33set-wpasupplicant
cp ${DEVCNF}/S87add-user ${TARGET_DIR}/etc/init.d/S87add-user
cp ${DEVCNF}/S96reswarm-agent ${TARGET_DIR}/etc/init.d/S96reswarm-agent
chmod 755 ${TARGET_DIR}/etc/init.d/S*

# configuration for interactive access to ReswarmOS
ASSCNF="/home/assets"
cp ${ASSCNF}/motd.sh ${TARGET_DIR}/etc/profile.d/motd.sh
chmod 644 ${TARGET_DIR}/etc/profile.d/motd.sh
cp ${ASSCNF}/shell-prompt.sh ${TARGET_DIR}/etc/profile.d/shell-prompt.sh
chmod 644 ${TARGET_DIR}/etc/profile.d/shell-prompt.sh

