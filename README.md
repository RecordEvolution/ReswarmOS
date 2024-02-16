
<p align="center">
  <a href="https://record-evolution.de/reswarm">
    <img
      alt="Record Evolution GmbH"
      src="https://res.cloudinary.com/dotw7ar1m/image/upload/v1708079370/vli89gsgy2siqcrmvzfm.png"
      width="400"
    />
  </a>
</p>

# ReswarmOS by Record Evolution

_ReswarmOS_ represents a lightweight, customizable and efficient host operating
system for embedded devices in the IoT context and is specifically designed to
meet the requirements of the IoT Development Studio by
_[Record Evolution](https://www.record-evolution.de/reswarm/)_. It was designed with the 
following objectives in mind: _minimal footprint/size_ of the root-filesystem
to ensure quick flashing and easy setup for a myriad of devices, _container support_
for having a robust solution to dynamically run a huge variety of apps on the 
device and _security standards_ matching the latest industry requirements
regarding data safety and network security.

## Overview

* [Usage](#Usage)
* [Build](#Build)
* [Buildsystem](#Buildsystem)
* [References](#References)

## Usage

_ReswarmOS_ may be used in two different ways:

1. as an independent alternative to i.a.
  [Raspberry Pi OS](https://www.raspberrypi.org/downloads/raspberry-pi-os/),
  [HypriotOS](https://blog.hypriot.com),
  [balenaOS](https://www.balena.io/os/),
  or [Tiny Core Linux](http://tinycorelinux.net)

1. as the _default_ operating system empowering the embedded devices connected
   to the IoT Development Studio _Reswarm_

### Independent OS

Just download the latest release, grab the SD card for your device and flash it
using the [Reflasher](https://github.com/RecordEvolution/Reflasher). After the
flash process is successfully finished, open up the _boot partition (vfat)_
labeled _RESWARMOS_ containing the file _/device-config.ini_. Here, you may enter
all configuration parameters for your device like i.a. your prefered _username_ and
corresponding login _password_ to be set up on the device. To be able to immediately
connect to the device via WIFI you have to enter the _SSID_ and _password_ of your
local wireless network. However, I you choose to not enter your WIFI credentials you
may still connect via LAN at any time. After booting up the device, it will show up
with its _hostname_ (the one you provided in _device-config.ini)_ on the local network.
Hence, you can connect to it via _ssh_ and your credentials entered in _device-config.ini_
by

```
ssh <your-username>@<device-hostname/local-ip>
```

### IoT devices

Any devices created within the framework of the IoT Development Studio
_Reswarm_ are by default equipped with the latest version of _ReswarmOS_
and automatically configured to securely connect and communicate with
the Record Evolution server cloud instance. Since this setup is coupled to your
individual Record Evolution user account the _ssh login_ is more customized and
secure. During the initial boot process ReswarmOS will set up a personalized
user account on the device using the fields `swarm_owner_name` and `secret`
of the _.reswarm_ configuration file as username and associated password.
Note, that this username may be modified in order to comply to the
`NAME_REGEX` rule `^[a-z][-a-z0-9]*$`. The device will show up in the local
network with its _hostname_ according to the Record Evolution device name. To ensure
maximal security, by default, this user is the only one able to access the
device directly using public key authentication. The required identity is
consequently provided by the _.reswarm_ file of the device and may,
for example, be prepared by

```
echo -e $(cat /path/to/mydevice/config.reswarm | jq .authentication.key) | tr -d '"' | grep -v "^ *$" > id_rsa
chmod 600 id_rsa
```

Henceforth, performing an _ssh login_ on the Reswarm device looks like this:

```
ssh -i id_rsa <swarm_owner_name>@<device-name/corresponding local ip>
```

## Build

The development of _ReswarmOS_ relies on [Buildroot](https://buildroot.org)
as its build system. To build _ReswarmOS_ yourself, all you need is a
_docker-able_ host machine (with at least 4 threads and 4GB of RAM and
20GB free disk space).

First of all, clone the repository by doing

```Shell
git clone https://github.com/RecordEvolution/ReswarmOS.git
cd ReswarmOS
```

Open up the main configuration file `setup.yaml` and choose i.a. the 
desired target hardware the resulting operating system image is supposed
to run on, e.g. for a Raspberry Pi 4

```
---
  # OS name and version
  osname: ReswarmOS
  osvariant: light
  version: 0.5.2
  # general board description
  board: raspberrypi
  boardname: Raspberry Pi
  # specific model
  model: raspberrypi3
  modelname: Raspberry Pi 3
  # custom (buildroot) configuration file (default: "config/<board>/<model>/config")
  #config: config/raspberrypi/raspberrypi3/config
  # custom linux configuration (default is already specified by (buildroot) config)
  #linuxconfig: config/raspberrypi/raspberrypi3/linux-config-full
  # name of image configuration file (default: "config/<board>/<model>/genimage.cfg")
  image:
...
```

Note, that `board` refers to the family (type) of boards while `model` provides
the specifics of a particular member of this board family. While the corresponding
fields `boardname` and `modelname` are merely arbitrary but meaningful labels, the
`board` and `model` fields have to exactly match the directory structure in the
`config/` folder. Please be aware, that the names, labels and versions provided
here are propagated to the release file and will eventually show up in the
[Reflasher](https://github.com/RecordEvolution/Reflasher) as a hardware board/
image selection option. The fields `config` and `linuxconfig` are optional and may be
used to employ any other custom configurations for buildroot (`config`) and the
Linux kernel (`linuxconfig`). If these fields are undefined or empty the build
system will automatically choose the default configurations determined by the
`config/` directory structure and the given `board` and `model` definitions.
After making the required adjustments save and close the file and proceed with
setting up the build environment and launching the actual build process:

```Shell
make setup
make build
```

where the last step may take about up to one to two hours to finish
depending on your machine. Here are some random (non-averaged, single)
run stats:

| CPU                                      | OS                  | ENV             | buildtime (min) | HD usage (kB) |
|------------------------------------------|---------------------|-----------------|-----------------|---------------|
| Intel(R) Core(TM) i7-8700T CPU @ 2.40GHz | Ubuntu 20.04.1 LTS  | Container       | 49:35           | 13288264      |
| Intel(R) Core(TM) i7-8700T CPU @ 2.40GHz | Ubuntu 20.04.1 LTS  | Host            | 31:02           | 12830624      |
| Intel(R) Core(TM) i5-7500T CPU @ 2.70GHz | Ubuntu 20.10        | Container       | 69:48           | 12855272      |


In order to roll out the image and release the corresponding
RAUC update bundle to our google-cloud storage `gs://reswarmos` do

```Shell
make release
```

This requires `gsutil` to be set up and configured on your localhost.
The `release` target will compress the image, generate a RAUC bundle
and update/extend the release file `config/supportedBoards.json` and push
everything to the google-cloud bucket.

## Buildsystem

The build mechanism is basically a wrapper and an extension to _Buildroot_,
which takes care of setting up the tool-chains, cross-compiling, constructing
the root filesystem and generating the final system image. Buildroot's
configuration concept bears strong similarities with the one of the
[Linux Kernel](https://www.kernel.org). In particular, both use an `.ini` like
configuration file `.config` located in the respositories root directory, i.e.
`buildroot/.config` and `linux/.config`. Furthermore, they both use an
an [ncurses](https://en.wikipedia.org/wiki/Ncurses) based configuration tool,
which is used by `make menuconfig` in the parent directory of the corresponding
repository.

The ReswarmOS build mechanism will use `output-build` as its default output directory
containing the final system image and update bundles:

```
mario@tuxedo:~/ReswarmOS$ ls -lh output-build/
total 615M
drwxr-xr-x 16 mario mario 4,0K Jan 17 11:30 buildroot
-rwxr-xr-x  1 root  root  2,1K Okt 29 12:35 cert.pem
-rwxr-xr-x  1 root  root  3,2K Okt 29 12:35 key.pem
drwxrwxr-x  2 mario mario 4,0K Jan 17 11:53 rauc-bundle
-rw-r--r--  1 mario mario 118M Jan 17 11:53 ReswarmOS-0.5.2-raspberrypi3.raucb
-rw-r--r--  1 mario mario 433M Jan 17 11:09 ReswarmOS-light-0.5.2-raspberrypi3.img
-rw-r--r--  1 mario mario 131M Jan 17 11:52 ReswarmOS-light-0.5.2-raspberrypi3.img.gz
```

Henceforth, to reconfigure any board/hardware specific Buildroot configuration  (`.config`)
the simplest way is to enter the buildroot directory (`cd output-build/buildroot`) which
is generated by the `make build` step and use the text-based user interface via `make menuconfig`.
After updating and saving the configuration you may want to store it and keep it as a
board's (default/custom) configuration by copying it to `config/<board>/<model>/<config-name>`.
Note, that you have to remove any dirty marks (indicating uncommited changes in the buildroot
directory) and evtl. the relative path to the root filesystem overlay (which is auto-injected
when starting up the build process). For instance, we may get

```
$ diff config/raspberrypi/raspberrypi3/config output-build/buildroot/.config

3c3
< # Buildroot 2021.08-646-gd0298f4052 Configuration
---
> # Buildroot -gb8485dc-dirty Configuration
514c514
< BR2_ROOTFS_OVERLAY=""
---
> BR2_ROOTFS_OVERLAY="../../rootfs"
```

### TODO Preliminary PKI for RAUC

The _preliminary_ (without using a Reswarm Platform Root CA) setup requires the `cert.pem` and
`key.pem` for validating RAUC update bundles. Currently, the validity of the certificate is
extended to one year (see make targets `$(OUT)key.pem $(OUT)cert.pem`). The current certificate
and key are located in a restricted access google-cloud bucket, i.e.

```
gsutil ls -lh gs://reswarmos-certs
  2.03 KiB  2022-01-18T11:46:58Z  gs://reswarmos-certs/cert.pem
  3.19 KiB  2022-01-18T11:47:03Z  gs://reswarmos-certs/key.pem
TOTAL: 2 objects, 5350 bytes (5.22 KiB)
```

Make sure to place these in the `output-build/` directory before trying to create
a RAUC update bundle.

## References

### Buildroot

- https://github.com/buildroot/buildroot
- https://buildroot.org/downloads/manual/manual.html
- https://elinux.org/images/2/2a/Using-buildroot-real-project.pdf
- https://firedome.io/wp-content/uploads/2021/02/How-to-build-your-own-tailor-made-IoT-Linux-OS_1.pdf

### Image

- https://github.com/pengutronix/genimage
- https://books.google.de/books/about/Instant_Buildroot.html?id=dZL9AAAAQBAJ&redir_esc=y
- http://lists.busybox.net/pipermail/buildroot/2016-April/160030.html


