#!/bin/zsh

set -e

# $1 = source directory
# $2 = squashfs target

source_dir=$(realpath $1)
target=$(realpath $2)
compression=$3

squashfs_dir_file_size=$(du $source_dir | cut -f1)

mksquashfs $source_dir $target \
 -noappend                 \
 -comp ${compression}      \
 -wildcards                \
 -e "proc/*"               \
 -e "proc/.*"              \
 -e "run/*"                \
 -e "run/.*"               \
 -e "tmp/*"                \
 -e "tmp/.*"               \
 -e "var/crash/*"          \
 -e "var/crash/.*"         \
 -e "swapfile"             \
 -e "root/.bash_history"   \
 -e "root/.cache"          \
 -e "root/.wget-hsts"      \
 -e "home/*/.bash_history" \
 -e "home/*/.cache"        \
 -e "home/*/.wget-hsts"

if [ $? -eq 0 ]; then
    echo $squashfs_dir_file_size > $source_dir/casper/filesystem.size

    if [ $? -eq 0 ]; then
        echo "Successfully compressed rootfs and updated its size"
    fi
fi
