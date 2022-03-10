#!/bin/zsh
set -e

# $1 = absolute path to ISO
# $2 = absolute path to autoinstall config

cur_dir=$(dirname $0)
dir_id=$(uuidgen)
extract_dir="/tmp/iso-extract-$dir_id"

mkdir -p $extract_dir

$cur_dir/extract-iso.sh $1 $extract_dir

cat $2 >$extract_dir/preseed/nocloud/user-data

echo "Wrote following config to user-data:"

cat $extract_dir/preseed/nocloud/user-data

echo "\n\n"

read "answer?Repackage ISO (y/n)? "
if [ "$answer" = "y" ]; then
    $cur_dir/rebuild-iso.sh $extract_dir $1
fi
