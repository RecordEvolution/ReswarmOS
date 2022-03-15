#!/bin/zsh

set -e

# $1 = rootfs path
# $2 = dest

rootfs_path=$(realpath $1)
dest_dir=$(realpath $2)

unsquashfs -dest $dest_dir $rootfs_path

# make the rootfs contents writable
chmod -R 777 $dest_dir
