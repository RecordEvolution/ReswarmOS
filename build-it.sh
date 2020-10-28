#!/bin/bash

source logging.sh

logging_header "starting to build ReswarmOS"

# --------------------------------------------------------------------------- #

logging_message "set up and check environment"
export FORCE_UNSAFE_CONFIGURE=1
env

logging_message "check directories and files"

echo "working directory: $(pwd)"
 
ls -lhd ./
ls -lh

ls -lhd ./reswarmos-build/
ls -lh ./reswarmos-build/

logging_message "list available configurations"
ls -lhR configs/

logging_message "ReswarmOS configuration"

cat distro-config.yaml

# construct image file name
osname=$(cat distro-config.yaml | grep "os-name" | awk -F ':' '{print $2}' | tr -d "\" ")
osversion=$(cat distro-config.yaml | grep "version" | awk -F ':' '{print $2}' | tr -d "\" ")
imgname=$(echo "${osname}-${osversion}.img")

# --------------------------------------------------------------------------- #

logging_message "clone buildroot repository"

if [[ -d reswarmos-build/buildroot ]]; then
  echo "buildroot directory already exists: please remove to get a fresh clone"
else
  git clone https://github.com/buildroot/buildroot --single-branch --depth=1 ./reswarmos-build/buildroot
fi

logging_message "copy required configuration file"

model=$(cat distro-config.yaml | grep "^ *model" | awk -F ':' '{print $2}' | tr -d ' ')
confg=$(cat distro-config.yaml | grep "^ *config" | awk -F ':' '{print $2}' | tr -d ' ')
cfgfile="configs/${model}/${confg}"

if [[ -f ${cfgfile} ]]; then
  if [[ -f ./reswarmos-build/buildroot/.config ]]; then
    echo "buildroot configuration .config already present: remove it to employ a new one"
  else
    cp -v ${cfgfile} ./reswarmos-build/buildroot/.config
  fi
else
  echo "sorry, the required config file '${cfgfile}' does not exist!" >&2
  exit 1
fi

logging_message "listing buildroot directory"

ls -lha ./reswarmos-build/buildroot/

# --------------------------------------------------------------------------- #

logging_message "initializing build process"

# get starting timestamp
startts=$(date)

pushd ./reswarmos-build/buildroot
make
popd

# show produced image file
logging_message "image file"
if [[ -f "./reswarmos-build/buildroot/output/images/sdcard.img" ]]; then
  ls -lh reswarmos-build/buildroot/output/images/
  cp -v reswarmos-build/buildroot/output/images/sdcard.img ./reswarmos-build/${imgname}
  ls -lhd ./reswarmos-build/
  ls -lh ./reswarmos-build/${imgname}
else
  echo "build incomplete: no image file produced"
fi

# finishing timestamp
finishts=$(date)

logging_message "finished build process"
echo "started:  ${startts}"
echo "finished: ${finishts}"

# --------------------------------------------------------------------------- #
