
# Building a Linux system

To build a custom Linux image and make it production ready we have to consider
_four building blocks_  corresponding to a four step production process.
These essentials compontents are

1. Boot Process and Bootloader
1. Kernel
1. Root Filesystem
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

1. First Stage: Raspberry Pi`s SoC contains a *hard-wired* first stage
                bootloader in the ROM section which mounts and loads the
                _FAT32_ boot partition of the SD-Card
1. Second Stage: - second stage bootloader is located in _bootcode.bin_ and
                   contains the GPU code and loads the GPU firmware
                 - the GPU firmware itself is loaded from _start.elf_ enabling the
                   GPU to load user specific code for the CPU like the _kernel_

The Raspberry Pi and its firmware need a _minimum_ of file and configuration
that is provided on the _boot_ partition with _FAT32_ filesystem. The minimal
set of files and configuration is:

### References

- https://www.gnu.org/software/grub/manual/grub/grub.html

## Kernel

## Root Filesystem

## OS Image

In order to generate a flashable image file _.img_ of the resulting operating
system we can conveniently use a _loopback device_. We partition and format
the virtual device according to our needs and image requirements. Finally, we
mount the virtual device and write all operating system files we produced on
the appropriate partitions and locations. Let's start step by step

1. decide on the sizes of the _boot/_ and _root/_ partitions of the image
1. generate an empty file _mf-os.img_ according to the total size (sum of
  both partitions) of the image
    ```Shell
    dd if=/dev/zero of=mf-os.img bs=1M count=100
    ```
1. set up a _parititioned_ loopback device based on this file (and check that
  device was correctly set up by obtaining its identifier number)
    ```Shell
    losetup -fP mf-os.img
    losetup -a
    ```
    where `-f` ensures the next free loopback device name is used
1. create the partition _boot/_ and _root/_ with their required sizes on the
  device
  ```Shell
    parted /dev/loopX --script mkpart primary FAT32 1049kB 100MB
    parted /dev/loopX --script mkpart primary ext4 1MB 100MB
  ```
  with _/dev/loopX_ being the automatically assigned next free loop device number.
  Note, that with `fdisk` we could also partition the image file without setting
  up any loop device
1. check resulting partition table
    ```Shell
    parted /dev/loopX print
    ```
1. format partitions and create appropriate filesystems
    ```Shell
    mkfs.fat32 -I /dev/loopXp1
    mkfs.ext4 -I /dev/loopXp2
    ```
1. mount both partitions
    ```Shell
    mkdir /loopfsA /loopfsB
    mount -o loop /dev/loopXp1 /loopfsA
    mount -o loop /dev/loopXp2 /loopfsB
    ```
1. check devices and correct mount points by e.g. `lsblk` or `df -h`
1. copy the _boot/_ files and _root/_ files to their respective partitions
   of the loopback device
    ```Shell
    cp -r ${buildpath}/boot/ /loopfsA
    cp -r ${buildpath}/boot/ /loopfsB
    ```
1. unmount the devices
    ```Shell
    umount /loopfsA
    umount /loopfsB
    ```
1. detach the loopback device
   ```Shell
   losetup -d /dev/loopX
   ```

The image file `mf-os.img` now contains both the boot partition and the
root file system and is ready to be deployed to any flash drive.

### References

- https://wiki.osdev.org/Loopback_Device
- https://www.thegeekdiary.com/how-to-create-partitions-inside-loopback-images/

## Cross Compilation
