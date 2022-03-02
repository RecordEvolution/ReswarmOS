# Ubuntu-based ReswarmOS (Installer) using Cubic


## About Cubic
Cubic (Custom Ubuntu ISO Creator) is a GUI wizard to create a customized Live ISO image for Ubuntu based distributions.

Cubic permits effortless navigation through the ISO customization steps and features an integrated virtual command line environment to customize the Linux file system. You can create new customization projects or modify existing projects. Important parameters are dynamically populated with intelligent defaults to simplify the customization process.

## Setup

NOTE: the following commands assumes you have the ReswarmOS repository installed under `$HOME/git/ReswarmOS`

**Install the Cubic application (Linux Only)**

```
$ sudo apt-add-repository universe
$ sudo apt-add-repository ppa:cubic-wizard/release
$ sudo apt update
$ sudo apt install --no-install-recommends cubic
```

**Download the source ISO to base ReswarmOS off of**

```
$ make download-source
```

**Update the Cubic configuration to match your home directory.**

```
$ make update-config
```

**Download and extract the latest ReswarmOS Cubic project files from gcloud**
```
$ make install-project
```

**Start modifying!**

```
$ make setup
```

## Release

To release and update the remote Cubic project files, one must first bump the target version in the `versions.json`

Afterwards you can archive your local Cubic project files and push them to the gcloud repository using:

```
$ make release
```