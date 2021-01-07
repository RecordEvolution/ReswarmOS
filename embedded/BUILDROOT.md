
# Buildroot

All packages available are listed under `package/` containing a corresponding
`Config.in` and `<package-name>.mk` file. To locate a package in the `make menuconfig`
menu check the file `package/Config.in` which defines where exactly in the menu
a particular package will show up.

## Buildroot Raspberry Pi 4

1. `git clone https://github.com/buildroot/buildroot --depth=1 --single-branch`
1. `make help`
1. `make list-defconfigs`
1. `make raspberrypi4_defconfig`
1. `make menuconfig`
	1. SystemConfiguration -> /dev management -> Dynamic using devtmpfs + mdev
