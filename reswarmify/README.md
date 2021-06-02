
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
1. mount boot partition and activate ssh: `udisksctl mount --block-device && touch /../../boot/ssh`
1. insert SD card into Pi and start it up
1. perform ssh login with `pi` and `raspberry`
1. install `git` and `vim` with `apt-get install git vim`
1. clone ReswarmOS repository: `git clone https://github.com/RecordEvolution/ReswarmOS
1. run `sudo raspi-config`, set localization options to enable WiFi and reboot, generate/initialize locale
   or simply uncomment required locales in `/etc/locale.gen` and do `locale-gen`
1. unblock wireless device:
  ```
  rfkill list
  rfkill unblock 0
  rfkill list
  ```
  check visibility of device: `ifconfig`
1. `/etc/NetworkManager/NetworkManager.conf`: 
   ```
  [ifupdown]
  managed=yes
  ```
1. disable `dhcpcd` by `systemctl disable dhcpcd.service`, reboot and make sure only one single `wpa_supplicant`
   process is active in order to not interfere with NetworkManager managing `wlan0`
  (see issue https://wiki.archlinux.org/title/NetworkManager#DHCP_client)
1. run layer script:
  - 04-install-packages.sh
  - 05-rootfs-install.sh
  - 06-manage-users.sh (RaspberrypiOS does not seem to accept `Include` in `sshd_config`, hence add `root.conf` directly to `sshd_config`)
  - 07-customize-motd.sh
  - (is not required: 08-network-config.sh)
  - 09-reagent-reswarm.sh
1. make sure binary `dhclient` is installed and add `/etc/NetworkManager/conf.d/17-dhcp-client.conf` with
  ```
  [main]
  dhcp=dhclient
  ```
1. remove `max-download-attempts` option from `/etc/docker/daemon.json` due to old docker version that does not know about this key yet
1. increase strength of default `pi` account password: `passwd pi`
1. shutdown device
1. insert SD card in another machine
1. adjust `cmdline.txt`
  - set new `partuuid` of rootfs according to `lsblk -lo name,path,fstype,label,partuuid`
  - reset init script to regrow root partition, i.e. `quiet init=/usr/lib/raspi-config/init_resize.sh`
  - resizing the filesystem is done by (re)adding `resize2fs_once` to `/etc/init.d/`:
  ```
  chmod +x /etc/init.d/resize2fs_once
  systemctl enable resize2fs_once
  ```
  for reference: see
  - https://raspberrypi.stackexchange.com/questions/87534/expand-raspbian-file-system-on-first-boot
  - https://www.raspberrypi.org/forums/viewtopic.php?t=253531

