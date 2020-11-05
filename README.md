
<p align="center">
  <a href="https://record-evolution.de/reswarm">
    <img
      alt="reswarm-os.svg"
      src="assets/reswarm-os.svg"
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
depending on your machine.

### References

#### Buildroot

- https://buildroot.org/downloads/manual/manual.html
- https://elinux.org/images/2/2a/Using-buildroot-real-project.pdf

#### Image

- https://github.com/pengutronix/genimage
- https://books.google.de/books/about/Instant_Buildroot.html?id=dZL9AAAAQBAJ&redir_esc=y
- http://lists.busybox.net/pipermail/buildroot/2016-April/160030.html
