
# Update

In order to keep an already deployed device running _ReswarmOS_ up to date
we have to have a way to upgrade the running system _without_ having to
reflash it. Generally speaking there a two approaches to the problem:

1. block based (A/B image)
2. file based

updates.

## RAUC (Robust Auto-Update Controller)

### Bundles

A _Bundle_ is what RAUC calls one complete update artifact and basically
consists of a

- _file system image_ and archive to be installed on the (IoT) device
- _manifest_ describing the images to be installed and some meta information
- and possible pre-, parallel-, post-scripts to run before, during and after the installation

RAUC incorporates all that stuff in a _SquashFS_ image. Every RAUC _Bundle_ must
be _signed_ with a given certificate.

### Slots

In RAUC language everything that can be updated like i.a. an entire device, a partition
or a single file is called a _Slot_.

### References

- https://rauc.io
- https://github.com/rauc/rauc
- https://rauc.readthedocs.io
- https://rauc.readthedocs.io/en/latest/advanced.html
- https://github.com/systemd/casync
- https://www.konsulko.com/getting-started-with-rauc-on-raspberry-pi-2/
- https://elinux.org/RPi_U-Boot
- https://pretalx.com/media/yocto-project-summit-2020/submissions/JJYPH3/resources/leon-anavi-rauc-yocto-2020_RSRhxRE.pdf

## OSTree

### References

- https://github.com/ostreedev/ostree
- https://ostreedev.github.io/ostree/introduction/
- https://github.com/ostreedev/ostree/issues/1801
- https://github.com/ostreedev/ostree/issues/2223

## Bootloader

### U-Boot

Most of the updater frameworks require some work flexibility during the boot process
which is supported out of the box by e.g. a raspberry pi. Both _RAUC_ and _ostree_
support the use of _u-boot_. 

### References

- https://source.denx.de/u-boot/u-boot
- https://github.com/u-boot/u-boot
- https://www.denx.de/wiki/U-Boot/WebHome
- https://andrei.gherzan.ro/linux/uboot-on-rpi/
- https://www.youtube.com/watch?v=5E0sdYkvq-Q

## References

- https://github.com/ostreedev/ostree
- https://ostreedev.github.io/ostree/introduction/
- https://mkrak.org/wp-content/uploads/2018/04/FOSS-NORTH_2018_Software_Updates.pdf
- https://events19.linuxfoundation.org/wp-content/uploads/2018/07/Using-Open-Source-Software-to-Build-an-Industrial-grade-Embedded-Linux-Platform-from-Scratch-OSSJ.pdf
- https://www.embedded-software-engineering.de/automatisches-firmware-update-fuer-embedded-linux-a-833310/
- https://wiki.yoctoproject.org/wiki/System_Update


