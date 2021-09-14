

## Nvidia Jetson AGX Xavier 32GB

## Boot sequence

In order to modify the boot device priority you have to modify the file
`/boot/extlinux/extlinux.conf` and change the order and name of the 
block device

### References

- https://www.jetsonhacks.com/2017/01/26/run-jetson-tx1-sd-card/
- https://elinux.org/Boot_from_sd
- https://forums.developer.nvidia.com/t/does-jetson-agx-xavier-support-boot-from-sd/65872/7

## Reagent on armv8 aarch64

1. make sure to have the cross-compiler installed on the host system:

```
  apt-cache search gcc-aarch
  apt-get install gcc-aarch64-linux-gnu 
  which aarch64-linux-gnu-gcc
```

1. compile the go binary with (while providing the flag `CC=` pointing to the cross-comiler)

```
  CGO_ENABLED=1 GOOS=linux GOARCH=arm64 GOARM=7 CC=aarch64-linux-gnu-gcc go build .
```

1. However, when built on an up-to-date host using `GLIBC_2.28`, on the Jetson Xavier you will probably end up with the issue:

```
  /reagent: /lib/aarch64-linux-gnu/libc.so.6: version `GLIBC_2.28' not found (required by ./reagent)
```

since Nvidia provides a root filesystem based on Ubuntu 18.04, which still uses
`/lib/aarch64-linux-gnu/libc-2.27.so`. Therefore, use an Ubuntu 18.04 based container to build
the reagent binary!!

