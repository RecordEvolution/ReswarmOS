#!/bin/bash

# set working directory
wrkdir="${HOME}/Downloads/"

# clone buildroot
git clone https://github.com/buildroot/buildroot --single-branch --depth=1 ${wrkdir}

# copy buildroot configuration 
cp buildroot_config-13-10-2020-18-26.conf ${wrkdir}/buildroot/.config
cp wpa_supplicant.conf board/raspberrypi/
cp post-build.sh board/raspberrypi/

pushd ${wrkdir}

time make

popd

