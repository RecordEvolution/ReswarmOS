#!/bin/bash

# set working directory
wrkdir="${HOME}/Downloads/"

# clone buildroot
git clone https://github.com/buildroot/buildroot --single-branch --depth=1 ${wrkdir}

# copy buildroot configuration 
cp buildroot_config-13-10-2020-18-26.conf ${wrkdir}/buildroot/.config
cp wpa_supplicant.conf ${wrkdir}/buildroot/board/raspberrypi/
cp post-build.sh ${wrkdir}/buildroot/board/raspberrypi/

pushd ${wrkdir}/buildroot

time make

popd

