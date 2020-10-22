#!/bin/sh

# disable devices for paging and swapping
swapoff -a

# get name of physical disk
disknam=$(lsblk -lo path,type | grep disk | awk '{print $1}' | tr -d ' ')

# check partition table
parted ${disknam} print
fdisk -l | grep "${disknam}"

# get number of sectors on disk
numsectors=$(fdisk -l ${disknam} | grep "sectors$" | awk '{print $7}')

# get index of first sector of second partition
sectorstart=$(fdisk -l | grep "${disknam}p2" | awk '{print $2}')

# calculate last sector
sectorend=$((numsectors-1))

# delete second (root) partition
parted --script ${disknam} rm 2

# create new resized partition with exactly!! same start sector
parted --script ${disknam} mkpart primary ext4 ${sectorstart} ${sectorend}

# instead of rebooting let the kernel detect the new partition table
partprobe
# swapon -a

# check partition table and filesystem
lsblk
df -h

# adjust/resize filesystem to new partition
resize2fs -p "${disknam}p2"

# check partition/filesystem
df -h
parted ${disknam} print
fdisk -l | grep "${disknam}"

# reboot device
#reboot

