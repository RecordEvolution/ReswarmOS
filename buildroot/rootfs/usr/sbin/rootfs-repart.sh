#!/bin/sh

#rootpart="$(findmnt -n -o SOURCE /)"
#rootdev="/dev/$(lsblk -no pkname "$rootpart")"

#flock $rootdev sfdisk -f $rootdev -N 2 <<EOF
#,+
#EOF

# resize partition(s)
flock /dev/mmcblk0 parted --script /dev/mmcblk0 resizepart 2 10%
flock /dev/mmcblk0 parted --script /dev/mmcblk0 resizepart 3 10%
flock /dev/mmcblk0 parted --script /dev/mmcblk0 resizepart 4 80%

sleep 5

udevadm settle

sleep 5

flock $rootdev partprobe $rootdev

#mount -o remount,rw $rootpart
#resize2fs $rootpart

mount -o remount,rw /dev/mmcblk0p2
resize2fs /dev/mmcblk0p2
#mount -o remount,rw /dev/mmcblk0p3
resize2fs /dev/mmcblk0p3
mount -o remount,rw /dev/mmcblk0p4
resize2fs /dev/mmcblk0p4

exit 0

# for reference, see
# https://salsa.debian.org/raspi-team/image-specs/-/blob/master/rootfs/usr/sbin/rpi-resizerootfs

## specify device name and its partition to check
#devnm="mmcblk0"
#devprt="2"
#
## check size of partitions and compare to disk capacity
#dskflsz=$(cat /sys/class/block/${devnm}/size)
#dskptsz=$(cat /sys/class/block/${devnm}p${devprt}/size)
#echo "${devnm}:   ${dskflsz}"
#echo "${devnm}p${devprt}: ${dskptsz}"
#dskptsz2=$((2*dskptsz))
##echo ${dskptsz2}
#
#if [ ${dskptsz2} -lt ${dskflsz} ]; then
#	echo "partition should be resized"
#	# resize partition
#	parted --script /dev/${devnm} resizepart ${devprt} 100%
#	# inform kernel about new partition table
#	partprobe
#	# resize filesystem
#        #e2fsck -f /dev/${devnm}p${devprt}
#	resize2fs /dev/${devnm}p${devprt}
#else
#	echo "partition seems to occupy most of the disk"
#fi
