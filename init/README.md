
# System Initialization

## Testing

## QEMU

Install the _QEMU_ emulator on Ubuntu with

```
sudo apt-get install qemu
```

while you can also choose among a variety of machines and architectures. These
may be listed by

```
qemu-system-aarch64 -machine help
qemu-system-aarch64 -machine raspi3 -cpu help
qemu-system-aarch64 -machine raspi3 -cpu cortex-a72
```
### References

- https://www.qemu.org
- https://www.qemu.org/docs/master/system/index.html
- https://wiki.qemu.org/Main_Page
- https://wiki.archlinux.org/index.php/QEMU

## Virtual Machine

_Buildroot_ supports the use of a virtual machine (_qemu_) to test the generated
root file system:

```
output/host/bin/qemu-system-x86_64
  -M pc
  -kernel output/images/bzImage
  -drive file=output/images/rootfs.ext2,if=virtio,format=raw
  -append "rootwait root=/dev/vda"
  -net nic,model=virtio
  -net user
```

### References

- https://wiki.archlinux.org/index.php/QEMU
- https://www.thirtythreeforty.net/posts/2020/01/mastering-embedded-linux-part-3-buildroot/
- https://ts-soft.info/post/buildroot-arm-qemu/

## References

- https://de.wikipedia.org/wiki/Initramfs
- https://en.wikipedia.org/wiki/Init#SysV-style
- https://www.thirtythreeforty.net/posts/2020/03/mastering-embedded-linux-part-4-adding-features/
