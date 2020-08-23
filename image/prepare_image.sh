#!/bin/bash
# generated by 'image/prepare_image.py'

source log/logging.sh

logging_message "creating image file"

# create image file of appropriate total size
dd if=/dev/zero of=/home/mario/reswarm-os/ReswarmOS_0.1.img bs=1M count=665

# check image path and size
ls -lh /home/mario/reswarm-os/ReswarmOS_0.1.img

logging_message "prepare loopback device"

# find next unused loopback device
devName=$(losetup -f) 

# set up loopback device with image file
losetup -fP /home/mario/reswarm-os/ReswarmOS_0.1.img

# check new loopback device
losetup -a 
losetup -l ${devName}

logging_message "set disk label"

# create disk label
parted ${devName} --script mklabel msdos 

logging_message "create partitions and filesystems"

# create partitions and employ required filesystems
logging_message "create partition 1 : boot"

parted ${devName} --script mkpart primary fat16 1048576B 68157439B

logging_message "format partition"

mkfs.fat -F 16 ${devName}p1

logging_message "mount partition"

# mount partition
mkdir -v /mnt/boot
mount -t vfat ${devName}p1 /mnt/boot
sleep 2

logging_message "populate partition"

# copy files
cp -rv /home/mario/reswarm-os/boot/* /mnt/boot

logging_message "unmount partition"

# unmount partition
umount ${devName}p1
sleep 2

logging_message "remove mount-point"

# remove mount-point
rm -r /mnt/boot

logging_message "create partition 2 : ReswarmOS"

parted ${devName} --script mkpart primary ext4 68157440B 487587839B

logging_message "format partition"

mkfs.ext4 ${devName}p2

logging_message "mount partition"

# mount partition
mkdir -v /mnt/ReswarmOS
mount -t ext4 ${devName}p2 /mnt/ReswarmOS
sleep 2

logging_message "populate partition"

# copy files
cp -rv /home/mario/reswarm-os/ReswarmOS/* /mnt/ReswarmOS

logging_message "unmount partition"

# unmount partition
umount ${devName}p2
sleep 2

logging_message "remove mount-point"

# remove mount-point
rm -r /mnt/ReswarmOS

logging_message "create partition 3 : share"

parted ${devName} --script mkpart primary ext4 487587840B 697303039B

logging_message "format partition"

mkfs.ext4 ${devName}p3


logging_message "check partitions"

# check partitions
parted ${devName} print

logging_message "detach loopback device"

# detach loopback device
losetup -d ${devName}

