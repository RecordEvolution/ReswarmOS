
# Reswarmify

1. choose OS image, for instance
  - ubuntu-21.04-preinstalled-server-arm64+raspi.img
  - 2021-03-04-raspios-buster-armhf-lite.img
1. flash it and evtl. disable resizing/growpart of e.g. cloud-init
1. insert the card into the device
1. if possible, connect the device via ethernet
1. power it up
1. connect to the device via ssh by means of default login, for instance (ubuntu:ubuntu)
1. clone the ReswarmOS.git repository
1. run the scripts as root in following order:
   1. ./reswarmify/install-packages.sh 
   1. ./reswarmify/rootfs-install.sh <rootfsmntpnt>
   1. ./reswarmify/manage-users.sh <rootfsmntpnt>
   1. ./reswarmify/reagent-reswarm.sh / /boot/firmware/
   1. ./reswarmify/customize-motd.sh /
1. power off the device
1. plug it into a different machine
1. mount the boot partition and remove `growpart` disabling from `user-data`
1. unmount
1. relabel the partitions:
   1. `e2label /dev/sdd2 rootfs`
   1. `fatlabel /dev/sdd1 ReswarmOS`
1. dd the entire SD card, i.e. its two partitions, and write it down as .img
   1. `sudo fdisk -l /dev/sdd`
   1. calculate total size of both partitions:
      1. take `End` sector of second partition
      1. calculate total size in MB
   1. `dd if=/dev/sdd of=/home/mario/ReswarmOS-0.3.7-ubuntu-21.04-arm64+raspi.img bs=1M count=3330 status=progress`


