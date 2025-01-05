# IronFlock Init

IronFlock Init is a command-line tool designed to configure your device for connection to the IronFlock platform. 

It sets up essential services, scripts, and binaries, allowing you to establish a connection using a configuration file from a virtual device created on IronFlock.

## Requirements for Reswarmification

- Debian or Ubuntu-based operating system
- Systemd initialization system
- Docker<sup>*</sup> 

<small>* Installed by the CLI tool if not already present.</small>

## Installation

To install IronFlock Init, use one of the following commands:

Using curl:
```
curl -sSL https://storage.googleapis.com/reswarmos/reswarmify/install.sh | bash
```

Using wget:
```
wget -qO- https://storage.googleapis.com/reswarmos/reswarmify/install.sh | bash
```

## Usage

```
CLI tool to initialize your IronFlock device

Usage:
  ironflock-init [flags]
  ironflock-init [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  remove      Removes the currently installed ironflock setup
  version     Displays the current version of the ironflock-init binary

Flags:
  -c, --config string   Path to .flock config file
  -h, --help            help for ironflock-init
  -a, --autoconfirm     execute the installation without user interaction choosing all defaults
```

## Development

### Architecture

The IronFlock Init overlays the root filesystem of the runner and executes `.sh` scripts, enabling customization of the IronFlock initialization process.

IronFlock Init utilizes the [Cobra](https://github.com/spf13/cobra) Go package, facilitating the addition of new commands and features to the CLI, including help output commands. Additionally, it uses the popular [prompt](https://github.com/cqroot/prompt) package to provide user options for reswarmification.

### Rootfs

A crucial step in setting up ironflock on your system involves overlaying the existing root filesystem with required files and services to connect to the IronFlock platform. ironflock-init downloads these necessary files and overlays them onto the runner's root filesystem.

#### Updating the Rootfs Overlay

After updating the contents of the rootfs folder in this repository, use the `make rollout-rootfs` command to update the remote rootfs files.

IronFlock Init redownloads the overlay filesystem each time it reswarmifies a device.

## Install.sh

The setup shell script automatically detects the system's architecture and downloads the latest `ironflock-init` tool with a matching architecture.

The remote install.sh file can be found here: 
https://storage.googleapis.com/reswarmos/reswarmify/install.sh

## Versioning and Rollout

### Rollout ironflock-init

First, we need to update the version embedded in the `ironflock-init` binary by modifying the `cli/release/version.txt` file. Next, we must update the remote version of the binary in the `availableVersions.json` file.

After committing and pushing these changes, the build and publish process can be completed with a single command: `make rollout`.

### Rollout rootfs

If you changed something in the rootfs folder you also need to `make rollout-rootfs`.

### Rollout Install.sh

Upload the updated `install.sh` file to the `reswarmos/reswarmify` directory on the IronFlock cloud.