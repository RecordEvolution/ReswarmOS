
# System Initialization

# Kernel

- https://s-matyukevich.github.io/raspberry-pi-os/

## sbin/init

The usual script or binary in _sbin/init_ triggers the first process started during
booting of the system. However, in the boot configuration of the Raspberry Pi
we can set any script/binary to be executed during startup by means of the
`init=` configuration in `cmdline.txt`.

## initramfs

The default Raspberry Pi kernel does not use any _initramfs_ [5].
Hence, in general, we are off fine by not adding any _initramfs_ [6].

## References

1. https://en.wikipedia.org/wiki/Init
1. https://raspberrypi.stackexchange.com/questions/41965/error-on-boot-no-working-init-found

1. https://de.wikipedia.org/wiki/Initramfs
1. https://en.wikipedia.org/wiki/Init#SysV-style
1. https://www.thirtythreeforty.net/posts/2020/03/mastering-embedded-linux-part-4-adding-features/
1. https://raspberrypi.stackexchange.com/questions/89909/custom-initramfs
1. http://www.linuxfromscratch.org/blfs/view/svn/postlfs/initramfs.html
