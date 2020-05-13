#!/bin/bash

# get kernel tarball
# latest stable (13.05.2020)
# https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/
# https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.6.11.tar.xz
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.6.11.tar.xz
tar xf linux-5.6.11.tar.xz

# install header files common to all architectures
make mrproper                            # clean up
make ARCH=${CLFS_ARCH} headers_check
make ARCH=${CLFS_ARCH} INSTALL_HDR_PATH=${CLFS}/cross-tools/${CLFS_TARGET} headers_install

# intiliaze logging protocol file
touch ${CLFS}/targetfs/var/log/lastlog
chmod -v 664 ${CLFS}/targetfs/var/log/lastlog

# provide libgcc for compiling dynamically linked software using GCC, GCC
cp -v ${CLFS}/cross-tools/${CLFS_TARGET}/lib/libgcc_s.so.1 ${CLFS}/targetfs/lib/

# strip libgcc
${CLFS_TARGET}-strip ${CLFS}/targetfs/lib/libgcc_s.so.1

# build the 'musl' package containing the main C library
# https://git.musl-libc.org/cgit/musl
wget https://git.musl-libc.org/cgit/musl/snapshot/musl-1.2.0.tar.gz
./configure \
  CROSS_COMPILE=${CLFS_TARGET}- \
  --prefix=/ \
  --disable-static \
  --target=${CLFS_TARGET}

# compile package and install shared library only
make
DESTDIR=${CLFS}/targetfs make install-libs
