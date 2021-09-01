#!/bin/bash

showLayout()
{
  echo "---------------------------------------------------------"
  lsblk -lo path,name,fstype,label,size,fsused,fssize,fsavail,phy-sec,log-sec,type
  #parted -l /dev/mmcblk0
  fdisk -l /dev/mmcblk0
  echo "---------------------------------------------------------"
}

# assuming following existing/required partition layout:
#
# /dev/mmcblk0p1 mmcblk0p1 vfat   ReswarmOS   32M
# /dev/mmcblk0p2 mmcblk0p2 ext4   rootfsA     10%
# /dev/mmcblk0p3 mmcblk0p3 ext4   rootfsB     10%
# /dev/mmcblk0p4 mmcblk0p4 ext4   appfs       80%    
#

# find sector size
secsiz=$(fdisk -l /dev/mmcblk0 | grep "^Sector size" | awk -F '/' '{print $3}' | awk '{print $1}' | tr -d ' ')
echo "/dev/mmcblk0 sector size = ${secsiz}"

# delete partitions rootfsB and appfs
echo "removing partition 4 and 3"
flock /dev/mmcblk0 parted /dev/mmcblk0 --script rm 4
flock /dev/mmcblk0 parted /dev/mmcblk0 --script rm 3
udevadm settle
flock /dev/mmcblk0 partprobe /dev/mmcblk0

# resize partition rootfsA
echo "resizing partition 2"
parted /dev/mmcblk0 --script resizepart 2 20%
udevadm settle
flock /dev/mmcblk0 partprobe /dev/mmcblk0

# recreate partition rootfsB with size of rootfsA
echo "recreating partition 3"
p2start=$(fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $2}')
#p2start=$((p2start*secsiz))
p2end=$(fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $3}')
#p2end=$((p2end*secsiz))
p3start=$((p2end+1))
p3end=$((2*p2end-p2start+1))
echo "p2start: ${p2start}"
echo "p2end: ${p2end}"
echo "p3start: ${p3start}"
echo "p3end: ${p3end}"
parted /dev/mmcblk0 --script mkpart primary ext4 "${p3start}s" "${p3end}s"
udevadm settle
flock /dev/mmcblk0 partprobe /dev/mmcblk0

# recreate partition appfs occupying all remaining space
echo "recreating partition 4"
p4start=$((p3end+1))
dsize=$(fdisk -l /dev/mmcblk0 | head -n1 | awk -F ',' '{print $3}' | awk '{print $1}' | tr -d ' ')
p4end=$((dsize-1))
echo "p4start: ${p4start}"
echo "p4end: ${p4end}"
parted /dev/mmcblk0 --script mkpart primary ext4 "${p4start}s" "${p4end}s"

sleep 5
udevadm settle
sleep 5
flock /dev/mmcblk0 partprobe /dev/mmcblk0

# resize filesystem of partition p2
mount -o remount,rw /dev/mmcblk0p2
resize2fs /dev/mmcblk0p2

# recreate filesystems on partitions p3 and p4
mkfs.ext4 /dev/mmcblk0p3 -L rootfsB
mkfs.ext4 /dev/mmcblk0p4 -L appfs

showLayout

