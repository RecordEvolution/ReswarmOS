
# Building a Linux system

To build a custom Linux image and make it production ready we have to consider
_four building blocks_  corresponding to a four step production process.
These essentials components are

1. Boot Process and Bootloader
1. Kernel
1. Root Filesystem (including packages and utilies)
1. OS Image

In case, we build the system for an architecture differing from the host
architecture, we have to first build a _cross-compiler_ to accomplish steps
involving the _kernel_ and all utilies located in the _root filesystem_.

## Boot Process and Bootloader

Here, we exclusively use _GRUB_ (Grand Unifying Bootloader) since it is
distributed under the GPL licence and is the one most compatible with the Linux
system.

### x86_64

### armv7l (Raspberry Pi)

The boot process in any Raspberry Pi model is set up by in two stages:

1. First Stage
    Raspberry Pi's SoC contains a *hard-wired* first stage bootloader in the ROM
    section which mounts and loads the _FAT32_ boot partition of the SD-Card
1. Second Stage
    - second stage bootloader is located in _bootcode.bin_ and contains the GPU
      code and loads the GPU firmware
    - the GPU firmware itself is loaded from _start.elf_ enabling the GPU to
      load user specific code for the CPU like the _kernel_

The Raspberry Pi and its firmware require a _minimum_ of files and configuration
that is provided on the _boot_ partition with _FAT32_ filesystem. For instance,
for the Raspberry Pi 3 the minimal set of files and configuration is

- GPU firmware :
  - kernel8.img (64bit kernel for the Raspberry Pi 3)
  - bcm2710-rpi-3-b.dtb (device tree binary Linux kernel configuration)
  - bootcode.bin (second stage bootloader)
  - fixup.dat ((optional) used to configure SDRAM partition between GPU and CPU)
  - start.elf (GPU firmware)
- configuration :
  - cmdline.txt (kernel commandline parameters)
  - config.txt (configuration file read by the bootloader)

These GPU firmware and bootloader files/BLOBS are provided in the
[Raspberry Pi Github](https://github.com/raspberrypi/firmware/tree/master/boot)
repository.

For comparison, [Hypriot OS](https://blog.hypriot.com/) uses on top of the
firmware BLOBS provided by the Raspberry Pi repository the following additional
configuration files:

- cmdline.txt
- config.txt
- fake-hwclock.data
- meta-data
- network-config
- os-release
- user-data

The configuration details of the _cmdline.txt_ and _config.txt_ are explained
in the Raspberry Pi documentation at
[Kernel Command Line](https://www.raspberrypi.org/documentation/configuration/cmdline-txt.md)
and
[config.txt](https://www.raspberrypi.org/documentation/configuration/config-txt/README.md).

Further configuration documentation for any Raspberry Pi model is provided at
[Configuration](https://www.raspberrypi.org/documentation/configuration/) and
[elinux.org](https://elinux.org/RPiconfig)

### References

- https://www.gnu.org/software/grub/manual/grub/grub.html

## Kernel

A ready-made up-to-date kernel for the _armv7l_ architecture and in particular
for any Raspberry Pi model can be obtained from
[Raspberry Pi Github Firmware](https://github.com/raspberrypi/firmware/tree/master/boot).
However, if we go about compiling our own kernel we most probably have to rely
on the kernel sources provided by the vendor,
e.g. [Raspberry Pi Linux Kernel](https://github.com/raspberrypi/linux) of the
device instead of the official mainline Linux kernel from
[Linux Kernel](https://www.kernel.org/).

### References

- https://www.kernel.org/
- https://www.raspberrypi.org/documentation/linux/kernel/building.md
- https://github.com/umiddelb/armhf/wiki/How-To-compile-a-custom-Linux-kernel-for-your-ARM-device

## Root Filesystem

## OS Image

In order to generate a flashable image file _.img_ of the resulting operating
system we can conveniently use a _loopback device_. We partition and format
the virtual device according to our needs and image requirements. Finally, we
mount the virtual device and write all operating system files we produced on
the appropriate partitions and locations. Let's start step by step

1. decide on the sizes of the _boot/_ and _root/_ partitions of the image
1. generate an empty file _reswarm-os.img_ according to the total size (sum of
  both partitions) of the image
    ```
      dd if=/dev/zero of=reswarm-os.img bs=1M count=100
    ```
1. set up a _parititioned_ loopback device based on this file (and check that
  device was correctly set up by obtaining its identifier number)
    ```
    losetup -fP reswarm-os.img
    losetup -a
    ```
    where `-f` ensures the next free loopback device name is used
1. create disk label
    ```
    parted /dev/loopX --script mklabel msdos
    ```
1. create the partition _boot/_ and _root/_ with their required sizes on the
   device (use at least 1MB/4MB alignment offset for first partition!)
    ```
      parted /dev/loopX --script mkpart primary fat32 1MiB 100MiB
      parted /dev/loopX --script mkpart primary ext4 100MiB 200MiB
    ```
    with _/dev/loopX_ being the automatically assigned next free loop device number.
    Note, that with `fdisk` we could also partition the image file without setting
    up any loop device
1. check resulting partition table
    ```
    parted /dev/loopX print
    ```
1. format partitions and create appropriate filesystems
    ```
    mkfs.fat -F 32 /dev/loopXp1
    mkfs.ext4 /dev/loopXp2
    ```
1. mount both partitions (for currently filesystem supported by the running kernel
    see `cat /proc/filesystems`)
    ```
    mkdir /mnt/{loopfsA,loopfsB}
    mount -t vfat /dev/loopXp1 /mnt/loopfsA
    mount -t ext4 /dev/loopXp2 /mnt/loopfsB
    ```
1. check devices and correct mount points by e.g. `lsblk` or `df -h`
1. copy the _boot/_ files and _root/_ files to their respective partitions
   of the loopback device
    ```
    cp -r ${buildpath}/boot/ /loopfsA
    cp -r ${buildpath}/root/ /loopfsB
    ```
1. unmount the devices and remove mountpoints
    ```
    umount /dev/loopXp1
    umount /dev/loopXp2
    rm -r /mnt/loopfsA /mnt/loopfsB
    ```
1. detach the loopback device
    ```
    losetup -d /dev/loopX
    ```

The image file `reswarm-os.img` now contains both the boot partition and the
root file system and is ready to be deployed to any flash drive.

### References

- https://www.gnu.org/software/parted/manual/html_node/mkpart.html
- https://wiki.osdev.org/Loopback_Device
- https://www.thegeekdiary.com/how-to-create-partitions-inside-loopback-images/
- https://rainbow.chard.org/2013/01/30/how-to-align-partitions-for-best-performance-using-parted/

## Cross Compilation

## Cloud-init

The _cloud-init_ package is the _de-facto_ standard to manage
early-initialization of a cloud instance by customizing the system during the
boot process and automatically sets up e.g. network configuration and connects
the device to the preconfigured network.

### References

- https://cloud-init.io
- https://cloudinit.readthedocs.io/en/18.3/
- https://github.com/canonical/cloud-init

## Testing and Debugging

The produced OS image _.img_ may be conveniently tested by making use of the
[QEMU](https://www.qemu.org/) virtualization tool, which can be used an open
source machine emulator. To install the tool on _Ubuntu_ run:

```
sudo apt-get install qemu-system
```

To start, let's boot up an _x86_64_ machine from an Alpine Linux image

```
qemu-system-x86_64 -drive format=raw,file=/home/mario/Downloads/alpine-standard-3.12.0-x86_64.iso
```

and specify _root_ as localhost login. The lists of currently supported machines
and CPUs (for mcimx6ul) is shown by

```
qemu-system-arm -machine help
qemu-system-arm -machine mcimx6ul-evk -cpu help
```

To start a machine emulation from an image use e.g.

```
qemu-system-arm -machine realview-pb-a8 -cpu cortex-a8 -drive format=raw,file=/home/mario/Downloads/hypriotos-rpi-v1.12.2.img7
```

### References

- https://en.wikibooks.org/wiki/QEMU/Images
- https://wiki.archlinux.org/index.php/QEMU


## Concurrent Projects

- https://github.com/RPi-Distro/pi-gen
- https://github.com/hypriot
- https://www.yoctoproject.org

### BuildRoot

_Buildroot_ is an project providing support for a variety of different
architectures and platform and offers a huge list of
[packages](https://github.com/buildroot/buildroot/tree/master/package).

- https://buildroot.org
- https://github.com/buildroot/buildroot
- https://docs.google.com/viewerng/viewer?url=http://bootlin.com/doc/training/buildroot/buildroot-slides.pdf
- https://www.thirtythreeforty.net/posts/2020/01/mastering-embedded-linux-part-3-buildroot/

#### BuildRoot in Docker

- http://wiki.t-firefly.com/en/ROC-RK3308-CC/buildroot-builder.html

### BuildRoot as Docker host

- https://embeddedbits.org/using-containers-on-embedded-linux/

### Buildroot vs. Yocto

- https://blog.3mdeb.com/2019/2019-06-26-smallest-embedded-system-yocto-vs-buildroot/
- https://www.ginzinger.com/de/techtalk/artikel/yocto-vs-buildroot-141/
