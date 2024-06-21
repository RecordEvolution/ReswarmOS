# Reswarmify CLI

Reswarmify CLI is a command-line tool designed to configure your device for connection to the Record Evolution platform. 

It sets up essential services, scripts, and binaries, allowing you to establish a connection using a configuration file from a virtual device created on Record Evolution.

## Requirements for Reswarmification

- Debian or Ubuntu-based operating system
- Systemd initialization system
- Docker<sup>*</sup> 

<small>* Installed by the CLI tool if not already present.</small>

## Installation

To install Reswarmify CLI, use one of the following commands:

Using curl:
```
curl -sSL https://storage.googleapis.com/reswarmos/reswarmify/setup.sh | bash
```

Using wget:
```
wget -qO- https://storage.googleapis.com/reswarmos/reswarmify/setup.sh | bash
```

## Usage

```
CLI tool to help reswarmify your device

Usage:
  reswarmify-cli [flags]
  reswarmify-cli [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  remove      Removes the current reswarmify installation
  version     Displays the current version of the Reswarmify binary

Flags:
  -c, --config string   Path to .reswarm config file
  -h, --help            help for reswarmify-cli
```

## Development

### Architecture

The Reswarmify CLI overlays the root filesystem of the runner and executes `.sh` scripts, enabling customization of the reswarmification setup process.

Reswarmify CLI utilizes the [Cobra](https://github.com/spf13/cobra) Go package, facilitating the addition of new commands and features to the CLI, including help output commands. Additionally, it uses the popular [prompt](https://github.com/cqroot/prompt) package to provide user options for reswarmification.

### Rootfs

A crucial step in reswarmifying a system involves overlaying the existing root filesystem with required files and services to connect to the Record Evolution platform. Reswarmify CLI downloads these necessary files from Google Cloud and overlays them onto the runner's root filesystem.

#### Updating the Rootfs Overlay

After updating the contents of the rootfs folder in this repository, use the `make rollout-rootfs` command to update the remote rootfs files.

Reswarmify CLI redownloads the overlay filesystem each time it reswarmifies a device.

## Setup.sh

The setup shell script automatically detects the system's architecture and downloads the latest `reswarmify-cli` tool with a matching architecture.

The remote setup.sh file can be found here: 
https://storage.googleapis.com/reswarmos/reswarmify/setup.sh

## Versioning and Rollout

### Reswarmify CLI

First, we need to update the version embedded in the `reswarmify-cli` binary by modifying the `cli/release/version.txt` file. Next, we must update the remote version of the binary in the `availableVersions.json` file.

After committing and pushing these changes, the build and publish process can be completed with a single command: make rollout.


### Setup.sh

Upload the updated `setup.sh` file to the `reswarmos/reswarmify` directory on the Record Evolution cloud.