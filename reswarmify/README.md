
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
1. remove ReswarmOS repo from home directory
1. clear journal `journalctl --vacuum-time=1s --rotate`
1. power off the device
1. plug it into a different machine
1. mount the boot partition and remove `growpart` disabling from `user-data`
1. unmount
1. relabel the partitions:
   1. `e2label /dev/sdd2 rootfs`
   1. `fatlabel /dev/sdd1 ReswarmOS`
   1. adjust root label in cmdline.txt
     `sed -i 's/root=LABEL=writable/root=LABEL=rootfs/g' /media/mario/ReswarmOS/cmdline.txt`
1. dd the entire SD card, i.e. its two partitions, and write it down as .img
   1. `sudo fdisk -l /dev/sdd`
   1. calculate total size of both partitions:
      1. take `End` sector of second partition
      1. calculate total size in MB
   1. `dd if=/dev/sdd of=/home/mario/ReswarmOS-0.3.7-ubuntu-21.04-arm64+raspi.img bs=1M count=3330 status=progress`


## Examples

### RaspberryPi OS

- baseimage: `2021-05-07-raspios-buster-armhf-lite.img`
- url: https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip 
- hash: `c3687e9df7c62196a24f1cba1bc6f654  2021-05-07-raspios-buster-armhf-lite.img`

1. flash image on SD card: `reflasher -d /dev/sda -i 2021-05-07-raspios-buster-armhf-lite.img`
1. mount boo partition and activate ssh: `udisksctl mount --block-device && touch /../../boot/ssh`
1. insert SD card into Pi and start it up
1. perform ssh login with `pi` and `raspberry`
1. install `git` and `vim` with `apt-get install git vim`
1. clone ReswarmOS repository: `git clone https://github.com/RecordEvolution/ReswarmOS
1. run `sudo raspi-config`, set localization options to enable WiFi and reboot, generate/initialize locale
1. increase strength of default `pi` account password: `passwd pi`
1. run layer script:
  - 04-install-packages.sh
  - 05-rootfs-install.sh
  - 06-manage-users.sh (RaspberrypiOS does not seem to accept `Include` in `sshd_config`, hence, add `root.conf` directly to `sshd_config`)
  - 07-customize-motd.sh
  - (is not required: 08-network-config.sh)
  - 09-reagent-reswarm.sh

