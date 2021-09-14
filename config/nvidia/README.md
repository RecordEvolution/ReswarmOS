
# ReswarmOS for Nvidia boards

## Documentation of Nvidia Boards

For general documentation and overview of available boards and their specifications, see:

https://developer.nvidia.com/embedded/learn/getting-started-jetson#documentation
https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3243/index.html
https://developer.nvidia.com/embedded/linux-tegra-r3261

A step by step walkthrough for the initial setup:

https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit

### Jetson AGX Xavier

In particular, the Jetson AGX Xavier documentation can be found at:

https://developer.nvidia.com/embedded/jetson-agx-xavier-developer-kit
https://developer.nvidia.com/embedded/downloads#?search=Jetson%20AGX%20Xavier%20Developer%20Kit%20User%20Guide
https://developer.download.nvidia.com/assets/embedded/secure/jetson/xavier/docs/jetson_agx_xavier_developer_kit_user_guide.pdf

More detailed specifications of the Jetson AGX Xavier:

https://elinux.org/Jetson_AGX_Xavier

Some Medium article about setting it up:

https://medium.com/geekculture/getting-started-with-real-time-image-processing-on-nvidia-jetson-agx-xavier-9e2ba008b665

Setup of Jetpack on Jetson:

https://developer.nvidia.com/embedded/jetpack
https://developer.nvidia.com/nvidia-sdk-manager

To download the Nvidia Developer SDK you may have to sign up at:

https://developer.nvidia.com/login

L4T archive:

https://developer.nvidia.com/embedded/linux-tegra-archive

#### Setup

Follow the setup steps given in the documentation at

- https://docs.nvidia.com/jetson/
- https://docs.nvidia.com/jetson/l4t/index.html
- https://docs.nvidia.com/jetson/l4t/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/quick_start.html#wwpID0E05C0HA
- https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3261/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/quick_start.html#wwpID0E05C0HA

1. install Ubuntu 18.04 on an external machine
1. on the Ubuntu host:
  1. update the repositories and make sure the system is up-to-date: `sudo apt-get update && sudo apt-get upgrade
  1. install _qemu-user-static_ by `sudo apt-get install qemu-user-static`
  1. Download both L4T drivers and sample root filesystem to `~/Downloads`:
    ```
      wget https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/t186/jetson_linux_r32.6.1_aarch64.tbz2 -P ~/Downloads/
      wget https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/t186/tegra_linux_sample-root-filesystem_r32.6.1_aarch64.tbz2 -P ~/Downloads/
    ```
  1. expand the archive `jetson_linux_r32...` by `tar xf` producing the new directory `Linux_for_Tegra/
  1. move to `Linux_for_Tegra/rootfs` as the current working directory and expand the root filesystem from there by:
     `tar xpf ../../tegra_linux_sample_root_filesystem...` where the `p` option is ESSENTIAL to get the right 
     file ownerships, permissions and suid bits.
  1. move to the directory `Linux_for_Tegra` and execute the script `apply_binares.sh` as root
1. put the developer board a.k.a. the Nvidia Jetson AGX Xavier into _FORCE RECOVERY MODE_ by
   1. press and hold the force recovery button (the button in the center)
   1. press, hold and release the power button
   1. release the force recovery button
1. make sure the board is in force recovery mode by doing on connected Linux machine:
   `lsusb | grep -i nvidia`
  and checking the output for `Bus xxx Device ddd: ID 0955:7019 Nvidia Corp.`
1. run `sudo ./flash.sh ${BOARD} mmcblk0p1` after making sure that `BOARD=jetson-agx-xavier-devkit` is defined
   
ISSUE: since in even in 2018 python3 is already the default while python2 has already been dropped you may
   encounter this issue during flashing: [Python2 flashing issue](https://forums.developer.nvidia.com/t/solved-cannot-flash-tx2-in-jetpack-3-3-usr-bin-env-python-no-such-directory/67645).
   This seems to be solved by actually installing python2 and creating the symlink
   `/usr/bin/python` pointing to `/usr/bin/python2.7` if it does not exist.
1. wait for the flash process to finish succesfully, after it's done the board will reboot automatically
1. make sure the Jetson board has ethernet connection, attach keyboard/mouse and follow the GUI setup

A list of known issues and what to do:

- https://forums.developer.nvidia.com/t/jetpack-4-2-flashing-issues-and-how-to-resolve/73387

To build Nvidia kernel and DTB from source:

- https://developer.ridgerun.com/wiki/index.php?title=Jetson_Nano/Development/Building_the_Kernel_from_Source

## Jetpack

The officially supported OS image by Nvidia is part of the _JetPackSDK_ with
its latest version being _4.6_. It is available at 
[JetPackSDK SD Card image](https://developer.nvidia.com/jetson-nx-developer-kit-sd-card-image).

## Custom OS

A template for a buildroot based OS running on a Jetson Nano can be found at
[Nvidia Forum](https://forums.developer.nvidia.com/t/embedded-linux/70101/7) and 
explicitly at 
[Nano Buildroot Config](https://forums.developer.nvidia.com/uploads/short-url/n77Rsk01vxqzC1XmzNAdQnXKMB5.txt).
There's another buildroot repository that includes the Jetson Nano configuration
an supported board: [Buildroot repo](https://github.com/celaxodon/buildroot/tree/board/jetson-nano-squashed).

### Bootloader

- https://docs.nvidia.com/jetson/l4t/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/uboot_guide.html#

## References

- https://forums.developer.nvidia.com/t/nvidia-jetson-and-buildroot/77935/3
- https://github.com/celaxodon/buildroot/tree/board/jetson-nano-squashed
- https://forums.developer.nvidia.com/t/minimal-working-buildroot-on-jetson-nano/169138
 
