#!/bin/bash

source logging.sh

logging_header "starting to build ReswarmOS"

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

logging_message "initializing build process"

# get starting timestamp
startts=$(date)

pushd buildroot
make
popd

# finishing timestamp
finishts=$(date)

logging_message "finished build process"
echo "started:  ${startts}"
echo "finished: ${finishts}"

logging_message "please find image file in here"
ls -lh buildroot/output/images



