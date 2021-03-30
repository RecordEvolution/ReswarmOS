#!/bin/sh

# specify device name and its partition to check
devnm="mmcblk0"
devprt="2"

# check size of partitions and compare to disk capacity
dskflsz=$(cat /sys/class/block/${devnm}/size)
dskptsz=$(cat /sys/class/block/${devnm}p${devprt}/size)
echo "${devnm}:   ${dskflsz}"
echo "${devnm}p${devprt}: ${dskptsz}"
dskptsz2=$((2*dskptsz))
#echo ${dskptsz2}

if [ ${dskptsz2} -lt ${dskflsz} ]; then
	echo "partition should be resized"
	# resize partition
	parted --script /dev/${devnm} resizepart ${devprt} 100%
	# resize filesystem
	resize2fs /dev/${devnm}p${devprt}
	# inform kernel about new partition table
	partprobe
else
	echo "partition seems to occupy most of the disk"
fi
