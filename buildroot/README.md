## Buildroot

To build ReswarmOS for Raspberry Pi and other platforms, we will run Buildroot inside a Docker container. The downloaded Buildroot environment and the output folder will be mounted on the host system. The Buildroot environment and output files will be located in the `output-build` folder.

To set up the Buildroot environment, you can start by running the `make setup` command. This command prepares the build environment using Docker.

## Setup.yaml

The `setup.yaml` file is a custom configuration file that specifies the configuration files, names, and other parameters to be used for the Buildroot build system. This file is read by the `build-it.sh` script, which is executed by the Docker container. The script reads the configuration file and copies the necessary files for compilation to the `output-build` directory.

```yaml
---
# OS name and version
osname: ReswarmOS
osvariant: image
version: 0.5.6
architecture: armv7
# general board description
board: raspberrypi
boardname: Raspberry Pi
# specific model
model: raspberrypi3
modelname: Raspberry Pi 3
config: config/raspberrypi/raspberrypi3/config-full
image:
```

The important keys for us are `board`, `boardname`, `model`, `modelname`, and `config`.

Our `.config` files are modified `defconfigs` provided by Buildroot. These configuration files determine what packages, kernel, boot system, bootloaders, etc., will be compiled into the image.

If no `config` field is provided, the `build-it.sh` script will, by default, use the configuration file located at `config/${board}/${model}/config`.

The `.config` file is also used to determine which Buildroot version the Docker container will download and use to compile the final image. The `build-it.sh` script uses the hash located at the top of the configuration file to clone the corresponding Buildroot version. ([View in code](https://github.com/RecordEvolution/ReswarmOS/blob/093d0e0ed48a37f0227c9105715bd5dcee620c11/buildroot/build-it.sh#L179))

The `build-it.sh` script will copy the configuration file specified in the `setup.yaml` to the `output-build/buildroot/.config` path. This file will then be used by Buildroot to compile the requested disk image.

## Editing an Existing .config File

Once the `.config` file has been copied to the `output-build/buildroot` directory, you can use the `make menuconfig` command in that directory to open the interactive Buildroot configuration screen. (Read more about the Buildroot toolchain [here](https://buildroot.org/downloads/manual/manual.html))

## Rootfs

The rootfs folder is used to overlay the installed root filesystem of the image. This is configured through the BR2_ROOTFS_OVERLAY key in the `.config` file. The `BR2_ROOTFS_OVERLAY` key is set by the `build-it.sh` [entrypoint script](https://github.com/RecordEvolution/ReswarmOS/blob/c2941c67beec4046bb5c56fd3a7c3d6096394b32/buildroot/build-it.sh#L105) upon building the disk image. 

You can easily update the rootfs by modifying the files in the folders before building the final image.

## Building the ReswarmOS Image

You can start building the image by running the `make build` command.

The Buildroot build process can take a long time (around 30 minutes to 1 hour) as it downloads all dependencies and builds them step by step.

## Release

To release the final disk image, run the `make release` command. This will utilize the current board information configured in `setup.yaml` to update the remote `supportedBoards.json`, gzip the final image, and upload it to the `reswarmos` gcloud bucket. 