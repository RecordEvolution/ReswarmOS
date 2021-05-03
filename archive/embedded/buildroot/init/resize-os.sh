#!/bin/sh
# - https://www.gnu.org/software/parted/manual/html_node/parted_31.html

# disable devices for paging and swapping
swapoff -a

# get name of physical disk
disknam=$(lsblk -lo path,type | grep disk | awk '{print $1}' | tr -d ' ')

# check partition table
parted ${disknam} print
fdisk -l | grep "${disknam}"

# kill dockerd process (mounted the rootfs partition to /var/lib/docker)
#pidcontainerd=$(ps aux | grep dockerd | grep -v grep | awk '{print $1}' | tr -d " ")
#kill ${pidcontainerd}

# unmount partition
umount "${disknam}p2"
lsblk

# get number of sectors on disk
numsectors=$(fdisk -l ${disknam} | grep "sectors$" | awk '{print $7}')

# get index of first sector of second partition
sectorstart=$(fdisk -l | grep "${disknam}p2" | awk '{print $2}')

# calculate last sector
sectorend=$((numsectors-1))

# delete second (root) partition
parted --script ${disknam} rm 2

# check partition table
parted ${disknam} print
fdisk -l | grep "${disknam}"

# create new resized partition with exactly!! same start sector
echo "creating new partition from ${sectorstart} to ${sectorend}"
parted --script ${disknam} mkpart primary ext4 ${sectorstart}s ${sectorend}s

# instead of rebooting let the kernel detect the new partition table
partprobe
# swapon -a

# check partition table and filesystem
lsblk
df -h

# adjust/resize filesystem to new partition
resize2fs -p "${disknam}p2"

# remount filesystem
mount -all

# check partition/filesystem
df -h
parted ${disknam} print
fdisk -l | grep "${disknam}"

# reboot device
#reboot

