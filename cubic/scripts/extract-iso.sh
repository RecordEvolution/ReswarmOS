#!/bin/zsh

set -e

# $1 = absolute path of ISO
# $2 = extract location

platform=$(uname -s)
dir_id=$(uuidgen)
mount_dir="/tmp/iso-mount-$dir_id"

absolute_ISO_path=$(realpath $1)
extract_dir=$(realpath $2)

mkdir -p $extract_dir
mkdir -p $mount_dir

if [[ "$platform" == "Darwin" ]]; then
    hdiutil_output=$(hdiutil attach -nomount $absolute_ISO_path)
    attached_disk=$(echo $hdiutil_output | cut -d ' ' -f 1 | head -n 1 | xargs)
    mount -t cd9660 $attached_disk $mount_dir &> /dev/null
else
    sudo mount $absolute_ISO_path $mount_dir
fi

rsync -az --info=progress2 $mount_dir/ $extract_dir/ 2> /dev/null

if [ $? -eq 0 ]; then
    echo "Sucessfully extracted ISO contents to $extract_dir"
fi

if [[ "$platform" == "Darwin" ]]; then
    umount $mount_dir &> /dev/null
    hdiutil detach $attached_disk &> /dev/null
else
    sudo umount $mount_dir &> /dev/null
fi

# make the ISO contents writable
chmod -R 777 $extract_dir