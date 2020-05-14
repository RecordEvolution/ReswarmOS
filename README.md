
# Reswarm Image

In order to have an individual system image for our Reswarm-Project we have to
assemble an image that satisfies the following requirements:

- small << 1GB
- able to host Docker
- cloud-init
- features two partitions: /boot/ (fat32) and /root/ (ext4) to be writable for
  configuration files

## Cloud init

- https://blog.hypriot.com/post/cloud-init-cloud-on-hypriot-x64/
- https://cloud-init.io
- https://cloudinit.readthedocs.io/en/latest/index.html

## Include Docker

- https://docs.docker.com/engine/install/binaries/

## How to write system directly on SD-Card (without image)

- https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4

## References

- http://www.linuxfromscratch.org
- https://github.com/reinterpretcat/lfs

## Alternatives

- https://github.com/vmware/photon
- https://www.inovex.de/blog/docker-a-comparison-of-minimalistic-operating-systems/
- https://sweetcode.io/linux-distributions-optimized-hosting-docker/
- http://distro.ibiblio.org/tinycorelinux/9.x/armv6/releases/RPi/

### Tiny Core Linux

- http://distro.ibiblio.org/tinycorelinux/9.x/armv6/releases/RPi/piCore-9.0.3.zip
