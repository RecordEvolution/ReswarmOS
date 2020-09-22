
# Build systems for Embedded Linux Distributions

[Buildroot](https://buildroot.org) and [Yocto](https://www.yoctoproject.org/)

## Buildroot

### First Steps

Get the code and unpack

```Shell
wget https://buildroot.org/downloads/buildroot-2020.08.tar.gz -P $HOME/Downloads
cd $HOME/Downloads && tar -xvzf builroot-2020.08.tar.gz
```

Enter the buildroot directory and check out the available commands

```
make help
```

_builroot_ already has a lot of preconfigured build configurations available,
which can be listed by

```
make list-defconfigs
```

Among these we also find default configurations for multiple Rasberry Pi models:

```
raspberrypi0_defconfig              - Build for raspberrypi0
raspberrypi0w_defconfig             - Build for raspberrypi0w
raspberrypi2_defconfig              - Build for raspberrypi2
raspberrypi3_64_defconfig           - Build for raspberrypi3_64
raspberrypi3_defconfig              - Build for raspberrypi3
raspberrypi3_qt5we_defconfig        - Build for raspberrypi3_qt5we
raspberrypi4_64_defconfig           - Build for raspberrypi4_64
raspberrypi4_defconfig              - Build for raspberrypi4
raspberrypi_defconfig               - Build for raspberrypi
```

### Quick Start

To employ one of the default configurations simply do, e.g.

```Shell
make raspberrypi4_defconfig
```

The current configuration is by default saved in _.config/_. To start building
the image simply type

```Shell
make all
```

Depending on the setup and host this may take about 30-60 minutes.
The actual OS-image should then be located in _output/images/_ including the
image `output/images/sdcard.img`.

### References

- https://ltekieli.com/buildroot-with-raspberry-pi-what-where-and-how/
- https://medium.com/@hungryspider/building-custom-linux-for-raspberry-pi-using-buildroot-f81efc7aa817
- http://oa.upm.es/53063/1/RPIembeddedLinuxSystems_raspberry.pdf

#### Setting up WIFI

- https://blog.crysys.hu/2018/06/enabling-wifi-and-converting-the-raspberry-pi-into-a-wifi-ap/

## Yocto

### References

- https://www.embeddeduse.com/2020/05/26/qt-embedded-systems-1-build-linux-image-with-yocto/

## References

- https://elinux.org/images/9/9a/Buildroot-vs-Yocto-Differences-for-Your-Daily-Job-Luca-Ceresoli-AIM-Sportline.pdf
- https://blog.3mdeb.com/2019/2019-06-26-smallest-embedded-system-yocto-vs-buildroot/
- https://www.ginzinger.com/de/techtalk/artikel/yocto-vs-buildroot-141/
