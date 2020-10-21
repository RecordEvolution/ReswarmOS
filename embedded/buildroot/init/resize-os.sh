#!/bin/sh

# disable devices for paging and swapping
swapoff -a

# print partition table
fdisk -l

# delete root partition and recreate it
fdisk /dev/mmcblk0
# 1. d  -> 2 
# 2. n -> 2 -> 65537 - (N-1)Sector
# switch to $ part  instead of fdisk to automate partition manipulation

# instead of rebooting let the kernel detect the new partition table
partprobe
# swapon -a

# check partition table and filesystem
lsblk
df -h

# resize filesystem
resize2fs /dev/mmcblk0p2

df -h

# reboot device
#reboot

