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
DSTCNF="/home/buildroot/distro-setup"

# specify device model/board
MDL="raspberrypiall"

# add rasberrypi3 dtb's since configuration is based on rasberrypi4
DTBCFG="/home/buildroot/configs/rasberrypi3/boot"
echo "adding DTBs for rasberrypi3"
cp -v ${DTBCFG}/bcm2710-rpi-3-b.dtb ${BINARIES_DIR}/
cp -v ${DTBCFG}/bcm2710-rpi-3-b-plus.dtb ${BINARIES_DIR}/
cp -v ${DTBCFG}/bcm2710-rpi-cm3.dtb ${BINARIES_DIR}/
cp -v ${DTBCFG}/bootcode.bin ${BINARIES_DIR}/

# deploy customized boot configuration
BOTCFG="/home/buildroot/configs/${MDL}/boot"
echo "use customized boot configuration in ${BOTCFG}"
cp -v ${BOTCFG}/config.txt ${BINARIES_DIR}/config.txt
cp -v ${BOTCFG}/cmdline.txt ${BINARIES_DIR}/cmdline.txt

# configure wlan0 and dhcp
echo "configure wlan0 and dhcp"
cp ${DSTCNF}/${MDL}/interfaces ${TARGET_DIR}/etc/network/interfaces
cp ${DSTCNF}/${MDL}/dhcpcd.conf ${TARGET_DIR}/etc/dhcpcd.conf

# resizing of root filesystem during first boot
echo "resize rootfs during first boot"
cp ${DSTCNF}/S22expand-rootpart ${TARGET_DIR}/etc/init.d/S22expand-rootpart
chmod 755 ${TARGET_DIR}/etc/init.d/S22expand-rootpart
cp ${DSTCNF}/S23expand-rootfs ${TARGET_DIR}/etc/init.d/S23expand-rootfs
chmod 755 ${TARGET_DIR}/etc/init.d/S23expand-rootfs

# mount boot partition
echo "mount boot partition"
mkdir -p ${TARGET_DIR}/boot
echo "/dev/mmcblk0p1  /boot           vfat    defaults        0       2" >> ${TARGET_DIR}/etc/fstab

# add (default) dynamic/device configuration file and device-config init.d scripts
echo "default device configuration"
DEVCNF="/home/buildroot/device-setup"
cp -v ${DEVCNF}/read-ini.sh ${TARGET_DIR}/usr/bin/read-ini.sh
chmod 755 ${TARGET_DIR}/usr/bin/read-ini.sh
cp -v ${DEVCNF}/S18set-hostname ${TARGET_DIR}/etc/init.d/S18set-hostname
cp -v ${DEVCNF}/S33set-wpasupplicant ${TARGET_DIR}/etc/init.d/S33set-wpasupplicant
cp -v ${DEVCNF}/S87add-user ${TARGET_DIR}/etc/init.d/S87add-user
chmod 755 ${TARGET_DIR}/etc/init.d/S*

# copy default device configuration to boot partition
echo "add default device configuration in boot partition"
cp -v ${DEVCNF}/device-config.ini ${BINARIES_DIR}/device-config.ini

# configuration of interactive (ssh) access to ReswarmOS
echo "ssh configuration"
ASSCNF="/home/buildroot/assets"
cp -v ${ASSCNF}/motd.sh ${TARGET_DIR}/etc/profile.d/motd.sh
chmod 644 ${TARGET_DIR}/etc/profile.d/motd.sh
cp -v ${ASSCNF}/shell-prompt.sh ${TARGET_DIR}/etc/profile.d/shell-prompt.sh
chmod 644 ${TARGET_DIR}/etc/profile.d/shell-prompt.sh
cp -v ${ASSCNF}/reswarmos.txt ${TARGET_DIR}/etc/reswarmos.txt
chmod 644 ${TARGET_DIR}/etc/reswarmos.txt

# use custom sshd_config to be employed
cp -v ${DEVCNF}/sshd_config ${TARGET_DIR}/etc/ssh/sshd_config

# WiFi network setup
mkdir -pv ${TARGET_DIR}/etc/wpa_supplicant

# Reswarm management agent setup
echo "set up Reswarm management agent"
AGTCNF="/home/buildroot/agent-setup"
cp -v ${AGTCNF}/init/S17check-reswarm ${TARGET_DIR}/etc/init.d/S17check-reswarm
#cp -v ${AGTCNF}/S57docker-config ${TARGET_DIR}/etc/init.d/S57docker-config
cp -v ${AGTCNF}/init/S97reagent ${TARGET_DIR}/etc/init.d/S97reagent
cp -v ${AGTCNF}/init/S98agentmgmt ${TARGET_DIR}/etc/init.d/S98agentmgmt
chmod 755 ${TARGET_DIR}/etc/init.d/S*
cp -v ${AGTCNF}/parse-config.py ${TARGET_DIR}/usr/bin/parse-config.py
chmod 755 ${TARGET_DIR}/usr/bin/parse-config.py
cp -v ${AGTCNF}/manage-reagent.sh ${TARGET_DIR}/usr/bin/manage-reagent.sh
chmod 755 ${TARGET_DIR}/usr/bin/manage-reagent.sh
cp -v ${AGTCNF}/reagent-mgmt-logger.sh ${TARGET_DIR}/usr/bin/reagent-mgmt-logger.sh
chmod 755 ${TARGET_DIR}/usr/bin/reagent-mgmt-logger.sh

# add Reagent binary
echo "preparing and adding Reagent"
reagenturl="https://storage.googleapis.com/re-agent/reagent-latest"
mkdir -pv ${TARGET_DIR}/opt/reagent
rm -v ${TARGET_DIR}/opt/reagent/reagent-*
wget ${reagenturl} -P ${TARGET_DIR}/opt/reagent/
chmod 755 ${TARGET_DIR}/opt/reagent/reagent-*


