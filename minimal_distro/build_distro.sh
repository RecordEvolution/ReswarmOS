#!/bin/bash

source minimal_distro/logging.sh

# implementation of reference
# https://www.linuxjournal.com/content/diy-build-custom-minimal-linux-distribution-source

#-----------------------------------------------------------------------------#
# Configuring the Environment

# turn on bash hash functions
set +h

# newly created files/directories are only writeable/readable by the current user
umask 022

# choose and create main build directory
export LXOS=$HOME/mf-os

if [[ -d "$LXOS" ]]; then
  logging_message "main build directory ${LXOS} already exists"
else
  logging_message "creating main build directory ${LXOS}"
  mkdir -pv ${LXOS}
fi

# define auxiliary environment variables
export LC_ALL=POSIX
export PATH=${LXOS}/cross-tools/bin:/bin:/usr/bin

# create target image`s filesystem hierachy (see https://refspecs.linuxfoundation.org/fhs.shtml)
logging_message "creating/ensuring target image's filesystem hierachy"
mkdir -pv ${LXOS}/{bin,boot{,grub},dev,{etc/,}opt,home,lib/{firmware,modules},lib64,mnt}
mkdir -pv ${LXOS}/{proc,media/{floppy,cdrom},sbin,srv,sys}
mkdir -pv ${LXOS}/var/{lock,log,mail,run,spool}
mkdir -pv ${LXOS}/var/{opt,cache,lib/{misc,locate},local}
install -dv -m 0750 ${LXOS}/root
install -dv -m 1777 ${LXOS}{/var,}/tmp
install -dv ${LXOS}/etc/init.d
mkdir -pv ${LXOS}/usr/{,local/}{bin,include,lib{,64},sbin,src}
mkdir -pv ${LXOS}/usr/{,local/}share/{doc,info,locale,man}
mkdir -pv ${LXOS}/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv ${LXOS}/usr/{,local/}share/man/man{1,2,3,4,5,6,7,8}
for dir in ${LXOS}/usr{,/local}; do
  ln -sv share/{man,doc,info} ${dir}
done
