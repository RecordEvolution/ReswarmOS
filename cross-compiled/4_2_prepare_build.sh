#!/bin/bash

# disable/unset any CFLAGS
unset CFLAGS
echo unset CFLAGS >> ~/.bashrc

# for reference:
# https://clfs.org/view/clfs-embedded/arm/cross-tools/variables.html

# target processor with hardware floating point capability ?
# for instance: Raspberry Pi 4 Model B
# -> Broadcom BCM2711 Chip
# -> Quad-core Cortex-A72 (ARM v8) 64-bit SoC @ 1.5 GHz
export CLFS_FLOAT="[hard, softfp, or soft]"

# if yes, specify floating point hardware
export CLFS_FPU="[fpu version]"

# set host and target triplets
export CLFS_HOST=$(echo ${MACHTYPE} | sed "s/-[^-]*/-cross/")  # e.g. x86_64-pc-linux-gnu
export CLFS_TARGET="[target triplet]"  # e.g. arm-linux-gnueabihf
# see
# - https://wiki.osdev.org/Target_Triplet
# - https://raspberrypi.stackexchange.com/questions/10627/how-can-i-cross-compile-to-the-raspberry-pi-using-clang-llvm

# architecture of the target CPU
export CLFS_ARCH=arm

# choose specific ARM architecture
export CLFS_ARM_ARCH="[architecture]"

# summarize all the above and add to .bashrc
echo export CLFS_HOST=\""${CLFS_HOST}\"" >> ~/.bashrc
echo export CLFS_TARGET=\""${CLFS_TARGET}\"" >> ~/.bashrc
echo export CLFS_ARCH=\""${CLFS_ARCH}\"" >> ~/.bashrc
echo export CLFS_ARM_ARCH=\""${CLFS_ARM_ARCH}\"" >> ~/.bashrc
echo export CLFS_FLOAT=\""${CLFS_FLOAT}\"" >> ~/.bashrc
echo export CLFS_FPU=\""${CLFS_FPU}\"" >> ~/.bashrc

# create sysroot directory and link its 'usr' directory to itself
mkdir -p ${CLFS}/cross-tools/${CLFS_TARGET}
ln -sfv . ${CLFS}/cross-tools/${CLFS_TARGET}/usr
