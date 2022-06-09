#!/bin/bash

set -u
set -e

BOARD_DIR=$(dirname "$0")

# # Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# define container (volume) home directory
BUILD_DIR=/home/buildroot

# build and include Reagent
# ${BUILD_DIR}./build-agent.sh

# include all customized boot directory files
# ls ${BUILD_DIR}/boot/ -lhR
# cp -v ${BUILD_DIR}/boot/config.txt ${BINARIES_DIR}/
# cp -v ${BUILD_DIR}/boot/device.ini ${BINARIES_DIR}/

# # disable/mask ttyS0
# rm -vf ${TARGET_DIR}/etc/systemd/system/serial-getty@ttyS0.service
# ln -s /dev/null ${TARGET_DIR}/etc/systemd/system/serial-getty@ttyS0.service

# # disable/mask (preliminary) reagent upgrade services
# rm -vf ${TARGET_DIR}/etc/systemd/system/reagent-upgrade.service
# ln -s /dev/null ${TARGET_DIR}/etc/systemd/system/reagent-upgrade.service

# set up soft link (in agent directory) pointing to mount point of vfat partition
# vfatlnk="${TARGET_DIR}/opt/reagent/vfat-mount"
# bootmnt=$(cat ${TARGET_DIR}/etc/fstab | grep -i vfat | awk '{print $2}' | tr -d ' ')
# echo "linking ${vfatlnk} to ${bootmnt}"
# rm -vf ${vfatlnk}
# ln -s ${bootmnt} ${vfatlnk}

# make sure /var/lock exists
echo "ensure existence of /var/lock directory"
mkdir -pv ${TARGET_DIR}/var/lock/

if [ -d "$BINARIES_DIR/efi-part/" ]; then
    cp -f "$BOARD_DIR/grub-efi.cfg" "$BINARIES_DIR/efi-part/EFI/BOOT/grub.cfg"
else
    cp -f "$BOARD_DIR/grub.cfg" "$TARGET_DIR/boot/grub/grub.cfg"

    # Copy grub 1st stage to binaries, required for genimage
    cp -f "$TARGET_DIR/lib/grub/i386-pc/boot.img" "$BINARIES_DIR"
fi