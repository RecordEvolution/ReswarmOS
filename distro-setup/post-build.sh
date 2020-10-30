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

# configure wlan0 and dhcp
cp /home/distro-setup/interfaces ${TARGET_DIR}/etc/network/interfaces
cp /home/distro-setup/dhcpcd.conf ${TARGET_DIR}/etc/dhcpcd.conf

# resizing of root filesystem during first boot
cp /home/distro-setup/S22expand-rootpart ${TARGET_DIR}/etc/init.d/S22expand-rootpart
chmod 755 ${TARGET_DIR}/etc/init.d/S22expand-rootpart
cp /home/distro-setup/S23expand-rootfs ${TARGET_DIR}/etc/init.d/S23expand-rootfs
chmod 755 ${TARGET_DIR}/etc/init.d/S23expand-rootfs

