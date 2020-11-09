#!/bin/bash

# assume output directory
outbuild="output-build"

# find image file
imgpath=$(ls ${outbuild} | grep -Po "^ReswarmOS-.*.img$")

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
parted ${imgdev} print

# detach device
losetup -d ${imgdev}

