#!/bin/bash

rootfs_device_name=$(df | grep "/target$" | cut -d " " -f 1)
grub_rauc_path="/target/etc/grub.d/40_custom"
rauc_conf_path="/target/etc/rauc/system.conf"

rootfsA_device_name="$rootfs_device_name"
rootfsB_device_name="$(echo $rootfs_device_name | cut -d "2" -f 1)3"

sed -i "s@/dev/xxx2@$rootfsA_device_name@g" $grub_rauc_path
sed -i "s@/dev/xxx3@$rootfsB_device_name@g" $grub_rauc_path

sed -i "s@/dev/xxx2@$rootfsA_device_name@g" $rauc_conf_path
sed -i "s@/dev/xxx3@$rootfsB_device_name@g" $rauc_conf_path
