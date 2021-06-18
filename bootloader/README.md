# Bootloader

## U-Boot

Most of the updater frameworks require some work flexibility during the boot process
which is not supported out of the box by e.g. a raspberry pi. Both _RAUC_ and _ostree_
support the use of _U-boot_.

_U-boot_ represents an additional abstraction layer in the boot process of the board that 
is placed in between the SOC and the kernel loading. 
The general boot process will involve several layers/stages:

1. First stage bootloader (SOC)
2. User bootloader
3. Linux Kernel
4. Userspace

U-boot is injected into the second step of the process and usually involves two states itself:
1. U-boot SPL (secondary programm loader)
2. U-boot

### RaspberryPi

Using _U-boot_ on a RaspberryPi it is introduced by the configuration file `config.txt` in the 
vfat boot partition of the SD card by the line

```
kernel=u-boot.bin
```

which loads the _U-boot_ binary instead of the Linux kernel. Alternatively, rename _u-boot.bin_
into _kernel<x>.img_ since this will be loaded by the SOC first stage bootloader by default.

## References

- https://source.denx.de/u-boot/u-boot
- https://github.com/u-boot/u-boot
- https://www.denx.de/wiki/U-Boot/WebHome
- https://andrei.gherzan.ro/linux/uboot-on-rpi/
- https://www.youtube.com/watch?v=5E0sdYkvq-Q
- https://www.youtube.com/watch?v=INWghYZH3hI
- https://www.golem.de/news/raspberry-pi-der-mit-dem-64-bit-kernel-tanzt-1611-124475-4.html
- https://kernelnomicon.org/?p=682
- https://blog.christophersmart.com/2016/10/27/building-and-booting-upstream-linux-and-u-boot-for-raspberry-pi-23-arm-boards/

