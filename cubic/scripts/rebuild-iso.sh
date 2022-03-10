#!/bin/zsh

# $1 = contents folder
# $2 = original image path (for boot sectors)

set -e

declare -A blockSizes
blockSizes=(["k"]=1024 ["m"]=1048576 ["g"]=1073741824 ["t"]=1099511627776 ["s"]=2048 ["d"]=512)

intervalRegex="--interval:(.*):(.*):(.*):'(.*)'"
blockNumberRegex="\d"
progressRegex="(\d*\.\d*)%"

indev=$(xorriso -indev $2 -report_el_torito as_mkisofs 2>&1)

[[ $indev =~ $intervalRegex ]]

fs=$match[1]
interval=$match[2]
zero=$match[3]

startBlockS=$(echo $interval | awk -F '-' '{print $1}')
endBlockS=$(echo $interval | awk -F '-' '{print $2}')

startBlock=$(echo $startBlockS | grep -Eo "\d*")
endBlock=$(echo $endBlockS | grep -Eo "\d*")
blockSizeUnit=$(echo $startBlockS | grep -Eo "\D")
blockCount=$(($endBlock - $startBlock + 1))
blockSize=$blockSizes[$blockSizeUnit]

bootPartitionImagePath='/tmp/partition.img'
skipBlock=$startBlock

newISOPath=$(echo $2 | cut -d. -f-1,2,3)-new.iso

echo "Extracting the boot sector from the original ISO"
echo "Block size: $blockSize, Skip: $skipBlock, Count=$blockCount\n"

ddOutput=$(dd if=$2 bs=$blockSize skip=$skipBlock count=$blockCount of=$bootPartitionImagePath 2>&1)
if [ $? -ne 0 ]; then
    echo "Failed to collect Boot Sector format from ISO"
    echo $ddOutput
else
    echo "Successfully extracted the Boot Sector format\n"
fi

command="xorriso -as mkisofs \
    -r \
    -J \
    -joliet-long \
    -l \
    -iso-level 3 \
    -V 'ReswarmOS' \
    -isohybrid-mbr \
    --interval:${fs}:${interval}:${zero}:'${bootPartitionImagePath}' \
    -partition_cyl_align off \
    -partition_offset 0 \
    --mbr-force-bootable \
    -apm-block-size 2048 \
    -iso_mbr_part_type 0x00 \
    -c '/isolinux/boot.cat' \
    -b '/isolinux/isolinux.bin' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e '/boot/grub/efi.img' \
    -no-emul-boot \
    -boot-load-size 8000 \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -o ${newISOPath} \
    ."

cd $1 && eval $command 2> >(grep -Eo --line-buffered "(\d*\.\d*)%" | awk '{print "Xorriso Progress: " $1}')
if [ $? -ne 0 ]; then
    echo "Failed to recreate ISO image"
    echo $ddOutput
else
    echo "Sucessfully rebuild the image! Location: $newISOPath"
fi