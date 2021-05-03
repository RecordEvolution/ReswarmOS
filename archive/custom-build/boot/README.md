
# Boot configuration

The VideoCore GPU is responsible for booting the Broadcom BCM283x system on a
chip (SoC), contained on the Raspberry Pi. The SoC will boot up with its main
ARM processor held in reset.

The VideoCore GPU loads the first stage bootloader from a ROM embedded within
the SoC. This extremely simple first stage bootloader is designed to load the
second stage bootloader from a FAT32 or FAT16 filesystem located on the SD Card.

The second stage bootloader – _bootcode.bin_ – is executed on the VideoCore GPU
and loads the third stage bootloader – _start.elf_ . Both these bootloaders are
closed firmware, available as binary blobs from Broadcom.

The third stage bootloader – _start.elf_ – is where all the action happens. It
starts by reading _config.txt_, a text file containing configuration parameters
for both the VideoCore (Video/HDMI modes, memory, console frame buffers etc) and
the Linux Kernel (load addresses, device tree, UART/console baud rates etc).

Once the _config.txt_ file has been parsed, the third stage bootloader will load
_cmdline.txt_ – a file containing the kernel command line parameters to be
passed to the kernel and _kernel.img_ – the Linux kernel.  Both are loaded into
shared memory allocated to the ARM processor. Once complete, the third stage
bootloader will release the ARM processor from reset. Your kernel should now
start booting.

## Boot partition

The _boot_ partition of an operating system image to be run on a Raspberry Pi
is supposed to contain the following kinds of files
(among other less important ones):

- bootloader (.bin, i.e. bootcode.bin, loaded by the SOC)
- firmware binary blobs (.elf, i.a. start.elf,start4cd.elf)
- linker files (.dat, i.a. fixup.dat, fixup4cd.txt)
- configuration files (.txt = config.txt, cmdline.txt, issue.txt, ssh.txt)
- device tree blobs (.dtb, e.g. bcm2708-rpi-b.dtb) + _overlays_ folder
- kernel files (.img, i.a. kernel.img,kernel7l.img)
- wireless network settings (.conf, i.e. wpa_supplicant.conf)

### Bootloader

The bootloader file _bootcode.bin_ is itself loaded by the SOC and loads
_start*.elf_. The bootloader files _is not used anymore on the Raspberry Pi 4_
where it was replaced by code in onboard
SPI(Serial Peripheral Interface)-attached EEPROM (4MBits/512KB).

### Firmware binary blobs

These are binary blobs (firmware) that are loaded on to the VideoCore in the SoC,
which then take over the boot process. For a specific Pi model mutliple of these
files are required:

- start.elf is the basic firmware
- start_x.elf includes camera drivers and codec
- start_db.elf is a debug version of the firmware
- start_cd.elf is a cut-down version with no support hardware blocks like codecs and 3D

Raspberry Pi 4 specific firmware files are:

- start4.elf
- start4x.elf
- start4cd.elf
- start4db.elf

### Linker Files

These are linker files and are matched pairs with the start*.elf files listed
in the previous section. These files are optional used to configure the SDRAM
partition between GPU and CPU.

### Configuration Files

The kernel command line _cmdline.txt_ passed in to the kernel when it boots and
further configuration parameters in _config.txt_ using entires selecting overlays.
When _ssh_ or _ssh.txt_ is present, SSH will be enabled on boot. The contents
don't matter, it can be empty. SSH is otherwise disabled by default.
With _config.txt_ we can choose particular overlays and also the actual kernel
to be loaded!

#### cmdline.txt

for RaspiOS apparently have to use _PARTUUID_

```
root=PARTUUID=907af7d0-02 rootfstype=ext4
```

instead of _LABEL_ and name of partition!

##### System Initialization

`cmdline.txt` provides the possibility to use your own script to initialize
and setup the system by setting `init=/sbin/initos.sh`, e.g.

```
init=/bin/bash -c "mount -t proc proc /proc; mount -t sysfs sys /sys; mount /boot; source /boot/unattended"
```

- https://raspberrypi.stackexchange.com/questions/33817/use-boot-cmdline-txt-for-creating-first-boot-script
- https://gitlab.com/JimDanner/pi-boot-script
- https://github.com/nmcclain/raspberian-firstboot

### Device Tree Blobs

Raspberry Pi kernels and its firmware use a _Device Tree (DT)_ to describe the
_hardware present_ in the Pi. See the next section for detailed explanation.

### Kernel images

This is the actual _Linux kernel_, while the boot folder will usually contain
various kernel image files, used for the different Raspberry Pi models:

| Raspberry Pi Model          | Processor        | Kernel      | Notes    |
| --------------------------- | ---------------- | ----------- | -------- |
| Raspberry PI Model 1 A      |	BCM2835          | kernel.img  |
| Raspberry PI Model 1 A+     |	BCM2835          | kernel.img  |
| Raspberry PI Model 1 B+     |	BCM2835          | kernel.img  |
| Raspberry PI Compute Module | BCM2835          |             |
| Raspberry PI Zero           | BCM2835          | kernel.img  |
| Raspberry PI Zero W         | BCM2835          | kernel.img  |
| Raspberry PI 1              | BCM2835          | kernel.img  |
| Raspberry PI 2 Model B      | BCM2836          | kernel7.img | Later Pi 2 uses the BCM2837 |
| Raspberry PI 3 Model B      |	BCM2837          | kernel7.img |
| Raspberry PI 3 Model B+     |	BCM2837B0        | kernel7.img |
| Raspberry PI 4              |	BCM2837, BCM2711 | kernel8.img | Large Physical Address Extension (LPAE) |


### Wireless network settings

You will need to define a _wpa_supplicant.conf_ file for your particular wireless
network. Put this file in the boot folder, and when the Pi first boots, it will
copy that file into the correct location in the Linux root file system and use
those settings to start up wireless networking. For example the
_wpa_supplicant.conf_ may look like

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=<Insert 2 letter ISO 3166-1 country code here, i.e. "DE" for Germany>

network={
 ssid="<Name of your wireless LAN>"
 psk="<Password for your wireless LAN>"
}
```

The password can be configured either as the ASCII representation, in quotes as
per the example above, or as a pre-encrypted 32 byte hexadecimal number.

### References

- https://www.raspberrypi.org/documentation/configuration/boot_folder.md
- https://github.com/DieterReuter/workshop-raspberrypi-64bit-os/blob/master/part1-bootloader.md

## Device Tree and Overlays

- Raspberry Pi kernels and its firmware use a _Device Tree (DT)_ to describe the
  _hardware present_ in the Pi
- DT overlays allow optional external hardware to be described and configured

### Device Tree

a Device Tree (DT) is a description of the hardware in a system :

- name of the base CPU
- memory configuration
- any internal/external peripherals
- by listing the hardware modules it causes driver modules to be loaded
- DTs are supposed to be OS-neutral
- a _Device Tree_ represents the hardware configuration as a hierarchy of nodes :
  - node may contain properties and subnodes
  - properties are named arrays of bytes, which may contain strings, numbers
    (big-endian), arbitrary sequences of bytes, and any combination thereof
- Device Trees are usually written in a textual form known as _Device Tree
  Source (DTS)_ and stored in files with a .dts suffix
- DTS syntax is C-like, with braces for grouping and semicolons at the end of each line
- the compiled binary format is referred to as _Flattened Device Tree (FDT)_ or
  _Device Tree Blob (DTB)_, and is stored in .dtb file

### Device Tree Overlays

- a modern SoC (System on a Chip) is a very complicated device: a complete
  Device Tree could be hundreds of lines long
- taking that one step further and placing the SoC on a board with other
  components only makes matters worse
- to keep that manageable, particularly if there are related devices that share
  components, it makes sense to put the common elements in .dtsi files to be
  included from possibly multiple .dts files.
- what is needed is a way to describe these optional components using a _partial
  Device Tree_, and then to be able to build a complete tree by taking a _base DT_
  and adding a number of optional elements. You can do this, and these optional
  elements are called _overlays_.

On a Raspberry Pi it is the job of the _loader_ (one of the _start.elf_ images) to
combine _overlays_ with an appropriate _base device tree_, and then to pass a _fully
resolved Device Tree_ to the _kernel_. The _base Device Trees_ are located alongside
start.elf in the _FAT partition_ (/boot from Linux), named _bcm2711-rpi-4-b.dtb,
bcm2710-rpi-3-b-plus.dtb, etc._

### Summary

- Device Tree was invented so that Linux users don't need to compile a different
  kernel for each different ARM board out there
- a full Device Tree is constructed by the loader (start.elf) by combining an
  appropriate base device tree with overlays
- the full Device Tree is then passed to the kernel

### References

- https://www.raspberrypi.org/documentation/configuration/device-tree.md

### Firmware loader and DTB

- firmware loader (start.elf and its variants) is responsible for loading the
  DTB (Device Tree Blob - a machine readable DT file)
- it chooses which one to load based on the board revision number, and makes
  certain modifications to further tailor it (memory size, Ethernet addresses etc.)
- config.txt is scanned for user-provided parameters, along with any overlays
  and their parameters

# References

- https://www.raspberrypi.org/documentation/configuration/
- https://www.raspberrypi.org/documentation/configuration/boot_folder.md
- https://www.beyondlogic.org/compiling-u-boot-with-device-tree-support-for-the-raspberry-pi/

## Further References

### Using the Universal Boot Loader (U-Boot)

- https://www.denx.de/wiki/U-Boot
- https://www.golem.de/news/raspberry-pi-der-mit-dem-64-bit-kernel-tanzt-1611-124475-4.html
