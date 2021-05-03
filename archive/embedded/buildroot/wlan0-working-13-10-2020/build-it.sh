#!/bin/bash

# set working directory
wrkdir="${HOME}/Downloads/"

# clone buildroot
git clone https://github.com/buildroot/buildroot --single-branch --depth=1 ${wrkdir}/buildroot

# copy buildroot configuration 
cp -v buildroot_config-13-10-2020-18-26.conf ${wrkdir}/buildroot/.config
cp -v wpa_supplicant.conf ${wrkdir}/buildroot/board/raspberrypi/
cp -v sshd_config ${wrkdir}/buildroot/board/raspberrypi/
cp -v post-build.sh ${wrkdir}/buildroot/board/raspberrypi/

pushd ${wrkdir}/buildroot

time make

popd

