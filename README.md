
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
_[Reswarm](https://www.record-evolution.de/reswarm/)_.

- Hardware (Rasbperry Pi Models)
- Container support (Docker)
- Size
- Architecture

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
corresponds to the `swarm_owner_name` as user and `secret` as password,
while the _hostname_ is given by the Reswarm device name. Henceforth,
the _ssh login_ looks like this:

```
ssh <swarm_owner_name>@<name> # password: <secret>
```   

## Build Process

The development of _ReswarmOS_ relies on [Buildroot](https://buildroot.org)
as its build system. To build _ReswarmOS_ yourself, all you need is a
_docker-able_ host machine (with at least 4 threads and 4GB of RAM and
20GB free disk space). Clone the repository, customize _device-config.yaml_
to your needs, build the docker image and start the container by

```
git clone https://github.com/RecordEvolution/ReswarmOS.git
cd ReswarmOS
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

### Root Filesystem

To decrease the overall size of the root filesystem, we first have to analyse
the size accumulation of objects contributing to the final extend. The analysis
of the root filesystem built with configuration [v0.0.4](configs/raspberrypi4/config_v0.0.4)
shows the following main contributions:

| Size | Dir   | Size   | Dir               | Size | Dir                          |
|------|-------|--------|-------------------|------|------------------------------|
| 175M | /usr  | 115M   | /usr/bin          | 37M  | /usr/bin/dockerd             |
|      |       |        |                   | 33M  | /usr/bin/docker              |
|      |       |        |                   | 26M  | /usr/bin/containerd          |
|      |       |        |                   | 7,0M | /usr/bin/runc                |
|      |       |        |                   | 5,4M | /usr/bin/containerd-shim     |
|      |       |        |                   | 1,8M | /usr/bin/vim                 |
|      |       | 36M    | /usr/lib          | 25M  | /usr/lib/python3.9           |
|      |       |        |                   | 2,3M | /usr/lib/libpython3.9.so.1.0 |
|      |       |        |                   | 1,9M | /usr/lib/libcrypto.so.1.1    |
|      |       |        |                   | 1,2M | /usr/lib/libstdc++.so.6.0.28 |
|      |       | 21M    | /usr/share        |      |                              |
|      |       | 3,2M   | /usr/sbin         |      |                              |
|      |       | 1,2M   | /usr/libexec      |      |                              |
| 63M  | /lib  | 59M    | /lib/modules      |      |                              |
|      |       | 1,3M   | /lib/libc-2.31.so |      |                              |
|      |       | 1,1M   | /lib/firmware     |      |                              |
| 2,3M | /sbin |        |                   |      |                              |
| 1,7M | /bin  |        |                   |      |                              |
| 1,6M | /etc  |        |                   |      |                              |
| 16K  | /var  |        |                   |      |                              |

### References

#### Buildroot

- https://github.com/buildroot/buildroot
- https://buildroot.org/downloads/manual/manual.html
- https://elinux.org/images/2/2a/Using-buildroot-real-project.pdf

#### Image

- https://github.com/pengutronix/genimage
- https://books.google.de/books/about/Instant_Buildroot.html?id=dZL9AAAAQBAJ&redir_esc=y
- http://lists.busybox.net/pipermail/buildroot/2016-April/160030.html
