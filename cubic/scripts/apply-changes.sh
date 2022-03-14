#!/bin/zsh
set -e

# $1 = absolute path to ISO

cur_dir=$(dirname $0)
dir_id=$(uuidgen)
iso_path=$(realpath $1)
iso_name=$(echo $iso_path | rev | cut -d\/ -f-1 | rev | sed 's|.iso||g')

root_dir="/tmp/$iso_name-$dir_id"
disk_extract_dir="/tmp/$iso_name-$dir_id/disk-contents"
rootfs_extract_dir="/tmp/$iso_name-$dir_id/rootfs-contents"

mkdir -p $root_dir $disk_extract_dir $rootfs_extract_dir

echo "Extracting ISO contents...\n"

$cur_dir/extract-iso.sh $iso_path $disk_extract_dir

echo "The ISO contents have been extract to $disk_extract_dir"

echo "\n"

echo "Extracting rootfs..."

$cur_dir/extract-rootfs $disk_extract_dir/casper/filesystem.squashfs $rootfs_extract_dir

echo "The rootfs have been extract to $rootfs_extract_dir"

echo "\n\n"

echo "The installer and the rootfs have been extracted, please apply your changes to these directories"

echo "\n\n"

read "answer?Repackage ISO (y/n)? "
if [ "$answer" = "y" ]; then
    echo "Repackaging rootfs..."
    $cur_dir/rebuild-rootfs $rootfs_extract_dir $disk_extract_dir/casper/filesystem.squashfs

    sleep 1

    echo "Repackaging ISO..."
    $cur_dir/rebuild-iso $disk_extract_dir $iso_path
fi

rm -rf $disk_extract_dir

echo "Successfully saved modified ISO to $iso_path!"