#!/bin/bash

showLayout()
{
  lsblk -lo path,name,fstype,label,size,fsused,fssize,fsavail,phy-sec,log-sec,type
  parted -l /dev/mmcblk0
  fdisk -l /dev/mmcblk0
}

showLayout

# assuming following existing/required partition layout:
#
# /dev/mmcblk0p1 mmcblk0p1 vfat   ReswarmOS   32M
# /dev/mmcblk0p2 mmcblk0p2 ext4   rootfsA     10%
# /dev/mmcblk0p3 mmcblk0p3 ext4   rootfsB     10%
# /dev/mmcblk0p4 mmcblk0p4 ext4   appfs       80%    
#

# delete partitions rootfsB and appfs
parted /dev/mmcblk0 --script rm 4
parted /dev/mmcblk0 --script rm 3
showLayout

# resize partition rootfsA
parted /dev/mmcblk0 --script resizepart 20%
showLayout

# recreate partition rootfsB with size of rootfsA
p2start=$(fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $2}')
p2end=$(fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $3}')
p3start=$((p2end+1))
p3end=$((2*p2end-p2start+1))
parted /dev/mmcblk0 --script mkpart primary ext4 "${p3start}B" "${p3end}B"

# recreate partition appfs occupying all remaining space
p4start=$((p3end+1))
dsize=$(fdisk -l /dev/mmcblk0 | head -n1 | awk -F ',' '{print $2}' | awk '{print $1}' | tr -d ' ')
p4end=$((dsize-1))
parted /dev/mmcblk0 --script mkpart primary ext4 "${p4start}B" "${p4end}B"
showLayout

sleep 5

udevadm settle

sleep 5

flock /dev/mmcblk0 partprobe /dev/mmcblk0

