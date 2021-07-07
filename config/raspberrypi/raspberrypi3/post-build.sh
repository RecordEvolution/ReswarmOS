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
# for reference also see: https://rauc.readthedocs.io/en/latest/integration.html#set-up-u-boot-boot-script-for-rauc
mkimage -A arm -O linux -T script -C none -n "U-boot script" -d /home/buildroot/boot/uboot/boot.txt ${BINARIES_DIR}/boot.scr.uimg
mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux kernel" -d ${BINARIES_DIR}/zImage ${BINARIES_DIR}/uImage

# include all customized boot directory files
ls /home/buildroot/boot/ -lhR
cp -v /home/buildroot/boot/cmdline.txt ${BINARIES_DIR}/
cp -v /home/buildroot/boot/config.txt ${BINARIES_DIR}/
cp -v /home/buildroot/boot/device.ini ${BINARIES_DIR}/
cp -v /home/buildroot/boot/uboot/uboot.env ${BINARIES_DIR}/

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

# make sure /var/lock exists
echo "ensure existence of /var/lock directory"
mkdir -pv ${TARGET_DIR}/var/lock/

