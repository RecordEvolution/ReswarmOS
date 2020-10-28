
<p align="center">
  <a href="https://record-evolution.de/reswarm">
    <img
      alt="reswarm-os.svg"
      src="assets/reswarm-os-3.svg"
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
using the [Reflasher](https://github.com/RecordEvolution/Reflasher). After 
booting up the device it will show up with its _hostname_ as `reckless-reindeer` 
on the local network. ReswarmOS provides _one_ default user login as

```
user: revenant
password: return
```

which is specified along with the _hostname_ in _distro-config.yaml_.

### Reswarm IoT devices

Any devices created within the framework of the IoT Development Studio 
_Reswarm_ are by default equipped with the latest version of _ReswarmOS_
and automatically configured to securely connect and communicate with
the Reswarm server cloud instance. Since this setup is coupled to your
individual Reswarm user account the _ssh login_ is more customized and 
corresponds to the `swarm_name` as user and `device_key` as password,
while the _hostname_ is given by the Reswarm device name. For instance,
the _ssh login_ may look like this:

```
ssh Lab@mf-pi-29 # password: 3056
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

- https://buildroot.org/downloads/manual/manual.html
- https://elinux.org/images/2/2a/Using-buildroot-real-project.pdf

