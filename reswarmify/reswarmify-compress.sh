#!/bin/bash

source logging.sh

# 1st argument: block device path of SD card
imagedevpath="$1"
# 2nd argument: path/name of final image
imagename="$2"

if [ -z "${imagedevpath}" ]; then
  logging_error "$0: missing argument 'imagedevpath'"
  exit 1
fi

if [ -z "${imagename}" ]; then
  logging_error "$0: missing argument 'imagename'"
  exit 1
fi

#-----------------------------------------------------------------------------#

logging_header "shrinking root filesystem and preparing OS image"

logging_message "CLI arguments:"
echo -e "imagedevpath: ${imagedevpath}"
echo -e "imagename:    ${imagename}"

# check partitions of device
lsblk | grep "${imagedevpath}"
rootfspart=$(lsblk -lo name,path,fstype,mountpoint | grep "${imagedevpath}" | grep "ext4")
rootfsdev=$(echo "${rootfspart}" | awk '{print $2}')
echo -e "root filesystem partition:\n${rootfspart}"
bootfspart=$(lsblk -lo name,path,fstype,mountpoint | grep "${imagedevpath}" | grep "vfat")
bootfsdev=$(echo "${bootfspart}" | awk '{print $2}')
echo -e "boot filesystem partition:\n${bootfspart}"

# mount rootfs partition
udisksctl mount --block-device ${rootfsdev}
rootfspart=$(lsblk -lo name,path,fstype,mountpoint | grep "${imagedevpath}" | grep "ext4")

# check total size of prepared root filesystem
rootfsmntpnt=$(echo "${rootfspart}" | awk '{print $4}')
rootfssize=$(du -s ${rootfsmntpnt} --block-size=1M | awk '{print $1}' | tr -d ' ')
echo "${rootfsmntpnt} : ${rootfssize}M"

# unmount both partitions
echo "unmount partitions ${rootfsdev}, ${bootfsdev}"
umount ${rootfsdev}
umount ${bootfsdev}

# run filesystem check
echo "run filesystem check on rootfs"
e2fsck ${rootfsdev} -v -n -E fragcheck
e2fsck -f ${rootfsdev}

# resize/shrink filesystem (include 200MiB of empty space)
rootfssizesectors=$((rootfssize+200))
echo "shrink filesystem"
# to ${rootfssizesectors}M"
#echo "resize2fs ${rootfsdev} ${rootfssizesectors}M"
#resize2fs ${rootfsdev} ${rootfssizesectors}M
# shrink filesystem to minimal size possible
resize2fs -M ${rootfsdev}

## resize partition
#echo "resize partition but first check size of new filesystem"
#rootblkcnt=$(dumpe2fs ${rootfsdev} | grep "^Block count" | awk -F ':' '{print $2}' | tr -d ' ')
#rootblksiz=$(dumpe2fs ${rootfsdev} | grep "^Block size" | awk -F ':' '{print $2}' | tr -d ' ')
#rootfssize=$((rootblkcnt*rootblksiz))
#bootblkcnt=$(dumpe2fs ${bootfsdev} | grep "^Block count" | awk -F ':' '{print $2}' | tr -d ' ')
#bootblksiz=$(dumpe2fs ${bootfsdev} | grep "^Block size" | awk -F ':' '{print $2}' | tr -d ' ')
#bootfssize=$((bootblkcnt*bootblksiz))
#echo "rootfs block count: ${rootblkcnt}"
#echo "rootfs block size:  ${rootblksiz}"
#echo "rootfs total size:  ${rootfssize}"
#echo "bootfs block count: ${bootblkcnt}"
#echo "bootfs block size:  ${bootblksiz}"
#echo "bootfs total size:  ${bootfssize}"
## device path and rootfs partition number
#fsdev=$(echo "${rootfsdev}" | grep -oP "/dev/[a-z]*")
#fsnum=$(echo "${rootfsdev}" | grep -oP "[0-9]*")
#echo "working on device ${fsdev}"
#echo "removing partition ${fsnum}"
#parted ${fsdev} --script rm ${fsnum}
#rootfssta=$((bootfssize+1))
#rootfsend=$((bootfssize+1+rootfssize))
#echo "recreating partition ext4 from ${rootfssta} to ${rootfsend}"
#parted ${fsdev} --script mkpart primary ext4 ${rootfssta}B ${rootfsend}B
#
# $ fdisk /dev/sda
# delete ext4 partition
# recreate partition
# ...
# take result of resize2fs, e.g.
# resize2fs 1.45.6 (20-Mar-2020)
# Resizing the filesystem on /dev/sda2 to 812454 (4k) blocks.
# The filesystem on /dev/sda2 is now 812454 (4k) blocks long.
# and translate number of sectors to number sectors with blocksize used by fdisk,
# e.g. 812454*4096/512 = 6499632
# ...
# Select (default p): primary
# Partition number (2-4, default 2): 2
# First sector (526336-124823551, default 526336):
# Last sector, +/-sectors or +/-size{K,M,G,T,P} (526336-124823551, default 124823551): +6499632
# Created a new partition 2 of type 'Linux' and of size 2.6 GiB.
# Partition #2 contains a ext4 signature.
# Do you want to remove the signature? [Y]es/[N]o: N

# create image of device
echo "create image of device"
sectorsiz=$(fdisk -l ${imagedevpath} | grep "^Units" | awk -F '=' '{print $2}' | tr -d 'bytes ')
sectornum=$(fdisk -l ${imagedevpath} | grep "^Device" -A20 | grep -v "^Device" | tail -n1 | awk '{print $4}')
devsize=$(python3 -c "print(${sectorsiz}*${sectornum})")
echo "sector size:     ${sectorsiz}"
echo "sector number:   ${sectornum}"
echo "total size:      ${devsize}"
devcount=$(python3 -c "print(int(${devsize}/1024.**2))")
echo "total size (MB): ${devcount}"
dd if=${imagedevpath} of=${imagename} bs=1M count=${devcount} status=progress

logging_message "final image"
ls -lh ${imagename}

#-----------------------------------------------------------------------------#
