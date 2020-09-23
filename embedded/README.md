
# Build systems for Embedded Linux Distributions

[Buildroot](https://buildroot.org) and [Yocto](https://www.yoctoproject.org/)

## Buildroot

### First Steps

Get the code and unpack

```Shell
wget https://buildroot.org/downloads/buildroot-2020.08.tar.gz -P $HOME/Downloads
cd $HOME/Downloads && tar -xvzf builroot-2020.08.tar.gz
```

or clone the master branch from github

```
git clone --single-branch --depth=1 https://github.com/buildroot/buildroot
```

Enter the buildroot directory and check out the available commands

```
make help
```

_builroot_ already has a lot of preconfigured build configurations available,
which can be listed by

```
make list-defconfigs
```

Among these we also find default configurations for multiple Rasberry Pi models:

```
raspberrypi0_defconfig              - Build for raspberrypi0
raspberrypi0w_defconfig             - Build for raspberrypi0w
raspberrypi2_defconfig              - Build for raspberrypi2
raspberrypi3_64_defconfig           - Build for raspberrypi3_64
raspberrypi3_defconfig              - Build for raspberrypi3
raspberrypi3_qt5we_defconfig        - Build for raspberrypi3_qt5we
raspberrypi4_64_defconfig           - Build for raspberrypi4_64
raspberrypi4_defconfig              - Build for raspberrypi4
raspberrypi_defconfig               - Build for raspberrypi
```

### Quick Start

To employ one of the default configurations simply do, e.g.

```Shell
make raspberrypi4_defconfig
```

To further customize this configuration you may want to use `make menuconfig`.
The current configuration is by default saved in _.config/_. To start building
the image simply type

```Shell
make all
```

Depending on the setup and host this may take about 30-60 minutes.
The actual OS-image should then be located in _output/images/_ including the
image `output/images/sdcard.img`.

### Setting up WIFI

Use `make menuconfig` to add and select required system components, i.a.

```
Networking applications -> wpa_supplicant
Networking applications -> wpa_supplicant - Enable 80211 support
Networking applications -> dropbear
Networking applications -> openssh
```

Add file `board/raspberrypi/interfaces` with

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    pre-up /etc/network/nfs_check
    wait-delay 15

auto wlan0
iface wlan0 inet dhcp
    pre-up wpa_supplicant -D nl80211 -i wlan0 -c /etc/wpa_supplicant.conf -B
    post-down killall -q wpa_supplicant
    wait-delay 15

iface default inet dhcp
```

and `board/raspberrypi/wpa_supplicant.conf` with

```
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1

network={
   ssid="EDIT_THIS"
   psk="EDIT_THIS"
}
```

In order to make _buildroot_ copy the files above in the root filesystem append

```
cp package/busybox/S10mdev ${TARGET_DIR}/etc/init.d/S10mdev
chmod 755 ${TARGET_DIR}/etc/init.d/S10mdev
cp package/busybox/mdev.conf ${TARGET_DIR}/etc/mdev.conf

cp board/raspberrypi/interfaces ${TARGET_DIR}/etc/network/interfaces
cp board/raspberrypi/wpa_supplicant.conf ${TARGET_DIR}/etc/wpa_supplicant.conf
cp board/raspberrypi/sshd_config ${TARGET_DIR}/etc/ssh/sshd_config
```

to `board/raspberrypi/post-build.sh`.

- https://armphibian.wordpress.com/2019/10/01/how-to-build-raspberry-pi-zero-w-buildroot-image/
- https://blog.crysys.hu/2018/06/enabling-wifi-and-converting-the-raspberry-pi-into-a-wifi-ap/
- https://unix.stackexchange.com/questions/396151/buildroot-zero-w-wireless

Very Helpful:

- https://rohitsw.wordpress.com/2016/12/17/building-a-linux-filesystem-on-raspberry-pi-3/
- https://www.raspberrypi.org/forums/viewtopic.php?t=159034
- http://lists.busybox.net/pipermail/buildroot/2016-April/159688.html
- https://github.com/OpenELEC/wlan-firmware
- http://lists.busybox.net/pipermail/buildroot/2017-May/191324.html

Kernel error while loading wifi module:

`Direct firmware load for brcm/brcmfmac43455-sdio.bin failed with error -2`

- http://lists.buildroot.org/pipermail/buildroot/2016-July/166287.html

### References

- https://buildroot.org/downloads/manual/manual.html#_buildroot_quick_start
- https://ltekieli.com/buildroot-with-raspberry-pi-what-where-and-how/
- https://medium.com/@hungryspider/building-custom-linux-for-raspberry-pi-using-buildroot-f81efc7aa817
- http://oa.upm.es/53063/1/RPIembeddedLinuxSystems_raspberry.pdf

## Yocto

### References

- https://www.embeddeduse.com/2020/05/26/qt-embedded-systems-1-build-linux-image-with-yocto/

## References

- https://elinux.org/images/9/9a/Buildroot-vs-Yocto-Differences-for-Your-Daily-Job-Luca-Ceresoli-AIM-Sportline.pdf
- https://blog.3mdeb.com/2019/2019-06-26-smallest-embedded-system-yocto-vs-buildroot/
- https://www.ginzinger.com/de/techtalk/artikel/yocto-vs-buildroot-141/
