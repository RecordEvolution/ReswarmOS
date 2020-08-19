
# Building a custom Linux system

In order to have an individual system image for our Reswarm-Project we have to
assemble an image that satisfies the following requirements:

- small << 1GB
- able to host Docker
- cloud-init
- features two partitions: /boot/ (fat32) and /root/ (ext4) to be writable for
  configuration files

## Linux Standard Base (LSB)

packages built in LFS to satisfy requirements of
[LBS](https://refspecs.linuxfoundation.org/lsb.shtml)

- Bash, Bc, Binutils, Coreutils, Diffutils, File, Findutils
- Gawk, Grep, Gzip, M4, Man-DB, Ncurses, Procps, Psmisc
- Sed, Shadow, Tar, Util-linux, Zlib

## Linux Kernel

- https://www.kernel.org
- https://en.wikipedia.org/wiki/Linux_kernel

## Boot Loader

- Raspberry Pi Firmware
  - https://github.com/raspberrypi/firmware/tree/master/boot

## Cloud init

- https://blog.hypriot.com/post/cloud-init-cloud-on-hypriot-x64/
- https://cloud-init.io
- https://cloudinit.readthedocs.io/en/latest/index.html

## Include Docker

- https://docs.docker.com/engine/install/binaries/

### Docker compatible Alternatives

- https://coreos.com/rkt/
- https://containerd.io

## How to write system directly on SD-Card (without image)

- https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4

## References

- original Linux from Scratch project
  - http://www.linuxfromscratch.org
  - http://www.linuxfromscratch.org/lfs/view/stable/
  - https://github.com/reinterpretcat/lfs

- General Guide for building linux
  - https://www.linuxjournal.com/content/diy-build-custom-minimal-linux-distribution-source

- specific for Raspberry Pi 64bit and Docker
  - https://blog.hypriot.com/post/building-a-64bit-docker-os-for-rpi3/
  - https://github.com/dieterreuter/workshop-raspberrypi-64bit-os

## Real-Time OS

- cross-reference: VAGO, Beckhoff etc.
- https://en.wikipedia.org/wiki/Comparison_of_real-time_operating_systems
- https://www.ethercat.org/default.htm
- http://crispaudio.de/?page_id=835

## Alternatives

- https://blog.hypriot.com/about/
- https://www.balena.io/os/

- https://github.com/vmware/photon
- https://www.inovex.de/blog/docker-a-comparison-of-minimalistic-operating-systems/
- https://sweetcode.io/linux-distributions-optimized-hosting-docker/
- http://distro.ibiblio.org/tinycorelinux/9.x/armv6/releases/RPi/

### Tiny Core Linux

- http://distro.ibiblio.org/tinycorelinux/9.x/armv6/releases/RPi/piCore-9.0.3.zip
