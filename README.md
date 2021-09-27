
<p align="center">
  <a href="https://record-evolution.de/reswarm">
    <img
      alt="reswarm-os.svg"
      src="archive/assets/reswarm-os.svg"
      width="400"
    />
  </a>
</p>

# ReswarmOS

_ReswarmOS_ represents a lightweight, customizable and efficient host operating
system for embedded devices in the IoT context and is specifically designed to
meet the requirements of the IoT Development Studio
_[Reswarm](https://www.record-evolution.de/reswarm/)_. It was designed with the 
following objectives in mind: _minimal footprint/size_ of the root-filesystem
to ensure quick flashing and easy setup for a myriad of devices, _container support_
for having a robust solution to dynamically run a huge variety of apps on the 
device and _security standards_ matching the latest industry requirements
regarding data safety and network security.

## Overview

* [Usage](#Usage)
* [Build](#Build)
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
with its _hostname_ (you provided in _device-config.ini)_ on the local network.
Hence, you can connect to it via _ssh_ and your credentials entered in _device-config.ini_
by

```
ssh <your-username>@<device-hostname>
```

### Reswarm IoT devices

Any devices created within the framework of the IoT Development Studio
_Reswarm_ are by default equipped with the latest version of _ReswarmOS_
and automatically configured to securely connect and communicate with
the Reswarm server cloud instance. Since this setup is coupled to your
individual Reswarm user account the _ssh login_ is more customized and
secure. During the initial boot process ReswarmOS will set up a personalized
user account on the device using the fields `swarm_owner_name` and `secret`
of the _.reswarm_ configuration file as username and associated password.
Note, that this username may be modified in order to comply to the
`NAME_REGEX` rule `^[a-z][-a-z0-9]*$`. The device will show up in the local
network with its _hostname_ according to the Reswarm device name. To ensure
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
20GB free disk space). Clone the repository, customize _device-config.yaml_
to your needs, build the docker image and start the container by

```Shell
git clone https://github.com/RecordEvolution/ReswarmOS.git
cd ReswarmOS
```

Open up the main configuration file `setup.yaml` and choose i.a. the 
desired target hardware the resulting operating system image is supposed
to run on:

```
  # OS name and version
  os-name: 'ReswarmOS'
  version: 0.4.0
  # general board description
  board: raspberrypi
  boardname: 'Raspberry Pi'
  # specific model
  model: raspberrypi4
  modelname: 'Raspberry Pi 4'
  # custom configuration file (default: "config/<board>/<model>/config")
  config:
  # name of image configuration file (default: "config/<board>/<model>/genimage.cfg")
  image:
```

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


## References

### Buildroot

- https://github.com/buildroot/buildroot
- https://buildroot.org/downloads/manual/manual.html
- https://elinux.org/images/2/2a/Using-buildroot-real-project.pdf

### Image

- https://github.com/pengutronix/genimage
- https://books.google.de/books/about/Instant_Buildroot.html?id=dZL9AAAAQBAJ&redir_esc=y
- http://lists.busybox.net/pipermail/buildroot/2016-April/160030.html


