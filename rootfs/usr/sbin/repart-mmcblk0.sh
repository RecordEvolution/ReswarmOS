#!/bin/bash

# set device name
devc="/dev/mmcblk0"

# suggested relative size of single rootfs partition (percentage)
rootfsRelSiz=18

showLayout()
{
  echo "---------------------------------------------------------"
  lsblk -lo path,name,fstype,label,size,fsused,fssize,fsavail,phy-sec,log-sec,type
  #parted -l /dev/mmcblk0
  fdisk -l "${devc}"
  echo "---------------------------------------------------------"
}

getSectorSize()
{
  # find sector size
  secsiz=$(fdisk -l ${devc} | grep "^Sector size" | awk -F '/' '{print $3}' | awk '{print $1}' | tr -d ' ')
  echo "${secsiz}"
}

getTotalSizeSectors()
{
  devcp="${devc}$1"
  totsiz=$(fdisk -l ${devcp} | grep -oP ", [0-9]* sectors" | awk '{print $2}')
  echo "${totsiz}"
}

getTotalSizeBytes()
{
  totsiz=$(fdisk -l ${devc} | grep -oP ", [0-9]* bytes" | awk '{print $2}')
  echo "${totsiz}"
}

getAbsEndSectorsBoot()
{
  endsec=$(fdisk -l ${devc} | grep ${devc}p1 | awk '{print $4}')
  echo "${endsec}"
}

# suggested partition layout:
#
# /dev/mmcblk0p1 mmcblk0p1 vfat   ReswarmOS   32M
# /dev/mmcblk0p2 mmcblk0p2 ext4   rootfsA     10%
# /dev/mmcblk0p3 mmcblk0p3 ext4   rootfsB     10%
# /dev/mmcblk0p4 mmcblk0p4 ext4   appfs       80%    
#

showLayout

# check device parameter
secsiz="$(getSectorSize)"
echo "${devc} sector size (bytes)  = ${secsiz}"
totsizbyt="$(getTotalSizeBytes)"
echo "${devc} total size (bytes)   = ${totsizbyt}"
totsizsec="$(getTotalSizeSectors)"
echo "${devc} total size (sectors) = ${totsizsec}"

# fixed size/position of ReswarmOS /boot partition
p1sizsec=$(getTotalSizeSectors p1)
echo "${devc}p1 total size (sectors)   = ${p1sizsec}"
p1endabssec=$(getAbsEndSectorsBoot)
echo "${devc}p1 end position (sectors) = ${p1endabssec}"

# calculate required partition sizes
echo "planned relative size (percentage) of p2/p3 = ${rootfsRelSiz}"
p4sizrel=$((100-2*rootfsRelSiz))
echo "planned relative size (percentage) of p4    = ${p4sizrel}"
#
p23sizsec=$(((totsizsec-p1sizsec)/2048*rootfsRelSiz*2*10))
p23sizsec=$(( (p23sizsec/2048+1)*2048 ))
echo "planned ${dev}p2/p3 size (sectors) = ${p23sizsec}"
p23sizbyt=$((p23sizsec*secsiz))
echo "planned ${dev}p2/p3 size (bytes)   = ${p23sizbyt}"
#
p4sizsec=$(((totsizsec-p1sizsec)/2048*p4sizrel*2*10))
p4sizsec=$(( (p4sizsec/2048+1)*2048 ))
echo "planned ${dev}p4 size (sectors)    = ${p4sizsec}"
p4sizbyt=$((p4sizsec*secsiz))
echo "planned ${dev}p4 size (bytes)      = ${p4sizbyt}"
#
chksmsec=$((p1sizsec+2*p23sizsec+p4sizsec))
echo "check sum (sectors)                = ${chksmsec}"
chksmbyt=$((p1sizbyt+2*p23sizbyt+p4sizbyt))
echo "check sum (bytes)                  = ${chksmbyt}"

# check actual partition sizes
p2sizsecIs=$(getTotalSizeSectors p2)
echo "${devc}p2 total size (sectors) = ${p2sizsecIs}"
p3sizsecIs=$(getTotalSizeSectors p3)
echo "${devc}p3 total size (sectors) = ${p3sizsecIs}"
p4sizsecIs=$(getTotalSizeSectors p4)
echo "${devc}p4 total size (sectors) = ${p4sizsecIs}"

# calculate absolute start/end sector indices (aligned ? <start/end> % 2048 == 0 ?)
p2startabssec=$(( ((p1endabssec+1)/2048+1)*2048  ))
p2endabssec=$((p2startabssec+p23sizsec))
p3startabssec=$(( ((p2endabssec+1)/2048+1)*2048 ))
p3endabssec=$((p3startabssec+p23sizsec))
p4startabssec=$(( ((p3endabssec+1)/2048+1)*2048 ))
p4endabssec=$((p4startabssec+p4sizsec))

echo "planned ${devc}p1 start - end (sectors) = 1s - ${p1endabssec}s"
echo "planned ${devc}p2 start - end (sectors) = ${p2startabssec}s - ${p2endabssec}s"
echo "planned ${devc}p3 start - end (sectors) = ${p3startabssec}s - ${p3endabssec}s"
echo "planned ${devc}p4 start - end (sectors) = ${p4startabssec}s - ${p4endabssec}s"

# repartition p2
repartdevp2()
{
  echo "remove partitions ${devc}p3=rootfsB and ${devc}p4=appfs"
  flock ${devc} parted ${devc} --script rm 4
  flock ${devc} parted ${devc} --script rm 3
  udevadm settle
  flock ${devc} partprobe ${devc}

  echo "resize partition ${devc}p2=rootfsA"
  parted /dev/mmcblk0 --script resizepart 2 "${p2endabssec}s"
  udevadm settle
  flock ${devc} partprobe ${devc}

  echo "recreate partitions ${devc}p3=rootfsB and ${devc}p4=appfs"
  parted ${devc} --script mkpart primary ext4 "${p3startabssec}s" "${p3endabssec}s"
  udevadm settle
  flock ${devc} partprobe ${devc}
  parted ${devc} --script mkpart primary ext4 "${p4startabssec}s" "${p4endabssec}s"
  udevadm settle
  flock ${devc} partprobe ${devc}

  sleep 5
  udevadm settle
  sleep 5
  flock ${devc} partprobe ${devc}

  echo "resize filesystem of ${devc}p2"
  mount -o remount,rw ${devc}p2
  resize2fs ${devc}p2

  echo "recreate filesystems on ${devc}p3 and ${devc}p4"
  mkfs.ext4 ${devc}p3 -L rootfs
  mkfs.ext4 ${devc}p4 -L appfs
}

# repartition p3
repartdevp3()
{
  echo "remove partition ${devc}p4=appfs"
  flock ${devc} parted ${devc} --script rm 4
  udevadm settle
  flock ${devc} partprobe ${devc}

  echo "resize partition ${devc}p3=rootfsB"
  parted /dev/mmcblk0 --script resizepart 3 "${p3endabssec}s"
  udevadm settle
  flock ${devc} partprobe ${devc}

  echo "recreate partition ${devc}p4=appfs"
  parted ${devc} --script mkpart primary ext4 "${p4startabssec}s" "${p4endabssec}s"
  udevadm settle
  flock ${devc} partprobe ${devc}

  sleep 5
  udevadm settle
  sleep 5
  flock ${devc} partprobe ${devc}

  echo "resize filesystem of ${devc}p3"
  mount -o remount,rw ${devc}p3
  resize2fs ${devc}p3

  echo "recreate filesystems on ${devc}p4"
  mkfs.ext4 ${devc}p4 -L appfs
}

# repartition p4
repartdevp4()
{
  echo "resize partition ${devc}p4=appfs"
  parted /dev/mmcblk0 --script resizepart 4 "${p4endabssec}s"
  udevadm settle
  flock ${devc} partprobe ${devc}

  sleep 5
  udevadm settle
  sleep 5
  flock ${devc} partprobe ${devc}

  echo "resize filesystem of ${devc}p4"
  mount -o remount,rw ${devc}p4
  resize2fs ${devc}p4
}

# partition p2
if [ $p2sizsecIs -lt $p23sizsec ]; then
  echo "need to resize partition ${devc}p2"
  #repartdevp2
else
  echo "no need to resize partition ${devc}p2"
fi

# partition p3
if [ $p3sizsecIs -lt $p23sizsec ]; then
  echo "need to resize partition ${devc}p3"
  #repartdevp3
else
  echo "no need to resize partition ${devc}p3"
fi

# partition p4
if [ $p4sizsecIs -lt $p4sizsec ]; then
  echo "need to resize partition ${devc}p4"
  #repartdevp4

  # Since any resizing is usually only required during the initial/first setup
  # we take the size of partition p4=appfs as overall indicator. In contrast,
  # after a ReswarmOS upgrade via RAUC we don't expect to have to repartition
  # anything, while the updated partition is resized by RAUC itself automatically!!
  repartdevp2

else
  echo "no need to resize partition ${devc}p4"
fi

showLayout

