#!/bin/bash

source logging.sh

logging_header "starting to build ReswarmOS"

# --------------------------------------------------------------------------- #

logging_message "set up and check environment"
export FORCE_UNSAFE_CONFIGURE=1
env

logging_message "check directories and files"

echo "working directory: $(pwd)"
 
ls -lh
ls -lh buildroot

logging_message "list available configurations"
ls -lhR configs/

logging_message "ReswarmOS configuration"

cat distro-config.yaml

# --------------------------------------------------------------------------- #

logging_message "clone buildroot repository"

if [[ -d buildroot/ ]]; then
  echo "buildroot directory already exists: please remove to get a fresh clone"
else
  git clone https://github.com/buildroot/buildroot --single-branch --depth=1
fi

logging_message "copy required configuration file"

model=$(cat distro-config.yaml | grep "^ *model" | awk -F ':' '{print $2}' | tr -d ' ')
confg=$(cat distro-config.yaml | grep "^ *config" | awk -F ':' '{print $2}' | tr -d ' ')
cfgfile="configs/${model}/${confg}"

if [[ -f ${cfgfile} ]]; then
  cp -v ${cfgfile} buildroot/.config
else
  echo "sorry, the required config file '${cfgfile}' does not exist!" >&2
  exit 1
fi

logging_message "listing buildroot directory"

ls -lha buildroot/

# --------------------------------------------------------------------------- #

logging_message "initializing build process"

# get starting timestamp
startts=$(date)

pushd buildroot
#make
popd

# show produced image file
logging_message "image file"
if [[ -d buildroot/output/ ]]; then
  ls -lh buildroot/output/images
else
  echo "build incomplete: no image file produced"
fi

# finishing timestamp
finishts=$(date)

logging_message "finished build process"
echo "started:  ${startts}"
echo "finished: ${finishts}"

# --------------------------------------------------------------------------- #
