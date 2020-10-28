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

# find required configuration file
model=$(cat distro-config.yaml | grep "^ *model" | awk -F ':' '{print $2}' | tr -d ' ')
confg=$(cat distro-config.yaml | grep "^ *config" | awk -F ':' '{print $2}' | tr -d ' ')

# construct image file name
osname=$(cat distro-config.yaml | grep "^ *os-name" | awk -F ':' '{print $2}' | tr -d "\" ")
osversion=$(cat distro-config.yaml | grep "^ *version" | awk -F ':' '{print $2}' | tr -d "\" ")
imgname=$(echo "${osname}-${osversion}-${model}.img")

# path of configuration (derived from distro-config.yaml)
cfgfile="configs/${model}/${confg}"

# --------------------------------------------------------------------------- #

#logging_message "clone buildroot repository"
#
#if [[ -d reswarmos-build/buildroot ]]; then
#  echo "buildroot directory already exists: please remove to get a fresh clone"
#else
#  git clone https://github.com/buildroot/buildroot --single-branch --depth=1 ./reswarmos-build/buildroot
#fi

# extract required commit (note, that any buildroot configuration corresponds to specific commit)
logging_message "extracting required commit from buildroot configuration"
comcfg=$(cat ${cfgfile} | grep "^# Buildroot -g.*Configuration" | awk -F ' ' '{print $3}' | sed 's/-g//g' | tr -d ' ')
echo "chosen configuration corresponds to buildroot commit ${comcfg}"

#logging_message "checking out the required commit"
#
#pushd ./reswarmos-build/buildroot/
#reqcom=$(git log --pretty=short | grep commit | awk '{print $2}' | tr -d ' ' | grep "^${comcfg}")
#echo "given configuration corresponds to commit ${comcfg} -> ${reqcom}"
#git reset --hard ${reqcom}
#popd

# get archive of specific commit
logging_message "obtaining buildroot respository of commit ${comcfg}"

wget https://github.com/buildroot/buildroot/archive/${comcfg}.zip
unzip -q "${comcfg}.zip" -d ./reswarmos-build/
mv ./reswarmos-build/buildroot-* ./reswarmos-build/buildroot

ls -lhd ./
ls -lh ./
ls -lh reswarmos-build/

# copy configuration file to buildroot directory
logging_message "copy required configuration file"

# copy configuration file
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

ls -lhd ./reswarmos-build/buildroot/
ls -lha ./reswarmos-build/buildroot/

# --------------------------------------------------------------------------- #

logging_message "initializing build process"

# get starting timestamp
startts=$(date)

pushd ./reswarmos-build/buildroot
#make
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
