#!/bin/bash

# assume output directory
outbuild="output-build"

# find image file
imgpath=$(ls -t ${outbuild} | grep -Po "^ReswarmOS-.*.img$" | head -n1)

if [ -z ${imgpath} ]; then
  echo "no image file found ${outbuild}" >&2
  return 1
else
  echo -e "analysing image file ${imgpath}\n"
fi

# show list of partitions
fdisk -l ${outbuild}/${imgpath}

# check loopback device with image
imgdev=$(losetup -a | grep ${outbuild}/${imgpath})

if [ -z "${imgdev}" ]; then
  echo -e "\nmounting image..."
  losetup -fP ${outbuild}/${imgpath}
else
  echo -e "\nimage already mounted..."
fi
imgdev=$(losetup -a | grep ${outbuild}/${imgpath} | awk -F ':' '{print $1}')
echo -e "...as ${imgdev}\n"

# show partition table
fdisk -l ${imgdev}
parted ${imgdev} print

# mount filesystems
# udisksctl mount --block-device ${imgdev}p1
# udisksctl mount --block-device ${imgdev}p2

# unmount
# umount ${imgdev}p1
# umount ${imgdev}p2

# detach device
losetup -d ${imgdev}


