#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# convert boot-script and kernel into U-boot image format
rm -vf /home/buildroot/bootloader/boot.scr.uimg
mkimage -A arm -O linux -T script -C none -d /home/buildroot/bootloader/boot.txt ${BINARIES_DIR}/boot.scr.uimg
mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux kernel" -d ${BINARIES_DIR}/zImage ${BINARIES_DIR}/uImage

# include all customized boot directory files
ls /home/buildroot/boot/ -lh
cp -v /home/buildroot/boot/* ${BINARIES_DIR}/

# disable/mask ttyS0
rm -vf ${TARGET_DIR}/etc/systemd/system/serial-getty@ttyS0.service
ln -s /dev/null ${TARGET_DIR}/etc/systemd/system/serial-getty@ttyS0.service

# disable/mask (preliminary) reagent upgrade services
rm -vf ${TARGET_DIR}/etc/systemd/system/reagent-upgrade.service
ln -s /dev/null ${TARGET_DIR}/etc/systemd/system/reagent-upgrade.service

# set up soft link (in agent directory) pointing to mount point of vfat partition
vfatlnk="${TARGET_DIR}/opt/reagent/vfat-mount"
bootmnt=$(cat ${TARGET_DIR}/etc/fstab | grep -i vfat | awk '{print $2}' | tr -d ' ')
echo "linking ${vfatlnk} to ${bootmnt}"
rm -vf ${vfatlnk}
ln -s ${bootmnt} ${vfatlnk}

