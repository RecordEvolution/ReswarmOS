#!/bin/bash

input_dir="squashfs-root"
mkdir -p $input_dir
mv rootfs.ext4 $input_dir
mv manifest.raucm $input_dir
output_name=$(cat name.txt)

rauc bundle --cert=cert.pem --key=key.pem $input_dir $output_name
RESULT=$?

if [ $RESULT -ne 0 ]; then
  exit 1
fi