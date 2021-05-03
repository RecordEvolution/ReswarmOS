#!/bin/bash

make mrproper

# configure
make ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- menuconfig

# compile
make ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}-

# build modules
make ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- \
    INSTALL_MOD_PATH=${CLFS}/targetfs modules_install
