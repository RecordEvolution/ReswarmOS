
# Building a Linux system

To build a custom Linux image and make it production ready we have to consider
_four building blocks_  corresponding to a four step production process.
These essentials compontents are

1. Boot Process and Bootloader
1. Kernel
1. Root Filesystem
1. Flash Drive Image

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
