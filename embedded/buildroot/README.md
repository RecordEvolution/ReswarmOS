
# buildroot

## Configure for docker

To use ReswarmOS as a docker host we need three components:

1. docker-cli
1. docker-engine
1. containerd

```
make menuconfig
```

1. Toolchain -> glibc (most important!!)
1. Target Packages -> System Tools -> docker-cli
1. Target Packages -> System Tools -> docker-compose
1. Target Package -> System Tools -> <all further docker compontents>...

## Obsolete

Add remaining packages by hand by appending to _.config_ (check
list of packages [Buildroot packages](https://github.com/buildroot/buildroot/tree/master/package)

```
BR2_PACKAGE_DOCKER_CLI=y
BR2_PACKAGE_DOCKER_CONTAINERD=y
BR2_PACKAGE_DOCKER_ENGINE=y
```

## Issue

```
failed to start daemon: devices cgroup is not mounded
```

- https://gist.github.com/hayderimran7/d2e40534016f7f07da44
- https://packages.debian.org/de/jessie/cgroupfs-mount
- https://github.com/docker/cli/issues/2104

