#!/bin/bash

source logging.sh

logging_header "starting to build ReswarmOS"

# --------------------------------------------------------------------------- #

logging_message "set up and check environment"
#export FORCE_UNSAFE_CONFIGURE=1
env
echo "current user: $(whoami)"

logging_message "check directories and files"

echo "working directory: $(pwd)"
 
ls -lhd ./
ls -lh

ls -lhd ./reswarmos-build/
ls -lh ./reswarmos-build/

logging_message "list available configurations"
ls -lhR configs/

logging_message "ReswarmOS configuration"

reswarmcfg="./distro-setup/distro-config.yaml"
cat ${reswarmcfg}

# find required configuration file
board=$(cat ${reswarmcfg} | grep "^ *board" | awk -F ':' '{print $2}' | tr -d ' ')
model=$(cat ${reswarmcfg} | grep "^ *model" | awk -F ':' '{print $2}' | tr -d ' ')
confg=$(cat ${reswarmcfg} | grep "^ *config" | awk -F ':' '{print $2}' | tr -d ' ')
imcfg=$(cat ${reswarmcfg} | grep "^ *image" | awk -F ':' '{print $2}' | tr -d ' ')

# construct image file name
osname=$(cat ${reswarmcfg} | grep "^ *os-name" | awk -F ':' '{print $2}' | tr -d "\" ")
osversion=$(cat ${reswarmcfg} | grep "^ *version" | awk -F ':' '{print $2}' | tr -d "\" ")
imgname=$(echo "${osname}-${osversion}-${board}.img")

# path of configuration (derived from distro-config.yaml)
cfgfile="configs/${model}/${confg}"

# show device configuration
logging_message "device configuration"
cat device-setup/device-config.ini

# --------------------------------------------------------------------------- #

# extract required commit (note, that any buildroot configuration corresponds to specific commit)
logging_message "extracting required commit from buildroot configuration"
comcfg=$(cat ${cfgfile} | grep "^# Buildroot -g.*Configuration" | awk -F ' ' '{print $3}' | sed 's/-g//g' | tr -d ' ')
echo "chosen configuration corresponds to buildroot commit ${comcfg}"

if [[ -z ${comcfg} ]]; then
  echo "invalid buildroot configuration: no 'Buildroot -g.* Configuration' flag found!" >&2
  exit 1
fi

# get archive of specific commit
logging_message "obtaining buildroot respository of commit ${comcfg}"

if [[ -d ./reswarmos-build/buildroot ]]; then

  echo "buildroot repository already exists: please remove it to update it!"

else

  archiveurl="https://github.com/buildroot/buildroot/archive/${comcfg}.zip"
  wget ${archiveurl}

  if [[ -f ${comcfg}.zip ]]; then
    echo "unzip buildroot archive ${comcfg}.zip"
    unzip -q "${comcfg}.zip"
    mkdir -pv ./reswarmos-build/buildroot
    echo "moving buildroot directory to ./reswarmos-build/"
    mv ./buildroot-*/* ./reswarmos-build/buildroot
  else
    echo "failed to download ${archiveurl}" >&2
    exit 1
  fi

fi

ls -lhd ./
ls -lh ./
ls -lh reswarmos-build/

# copy configuration file to buildroot directory
logging_message "copy required configuration file"

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

logging_message "performing distribution configuration"

# obtain required path of post-build.sh script in buildroot config
pstbldscr="./reswarmos-build/buildroot/$(cat ${cfgfile} | grep "BR2_ROOTFS_POST_BUILD_SCRIPT" | awk -F '=' '{print $2}' | tr -d '" ')"
echo "setting post-build actions in ${pstbldscr}"

# copy post-build.sh of distribution to buildroot subdirectory
cp -v ./configs/${model}/post-build.sh ${pstbldscr}

## perform distribution configuration (buildroot directory must already exist!!)
#python3 distro-setup/distro-setup.py ./distro-setup/ ./configs/ ./reswarmos-build/buildroot/

# employ genimage configuration for partitions and image
cp -v "./configs/${model}/genimage.cfg" "./reswarmos-build/buildroot/board/${model}/${imcfg}"

# show final post-build.sh
echo "final post-build.sh"
cat ${pstbldscr}

# generate/update os-version file
echo "${osname}-${osversion}" > ./assets/reswarmos.txt

# --------------------------------------------------------------------------- #

logging_message "initializing build process"

# get starting timestamp
startts=$(date)
startsec=$(date +%s)

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

# --------------------------------------------------------------------------- #

# finishing timestamp
finishts=$(date)
finishsec=$(date +%s)

logging_message "finished build process"
echo "started:  ${startts}"
echo "finished: ${finishts}"
# use ISO 8601 for representation
elapsec=$((finishsec-startsec))
elapmin=$((elapsec/60))
elapsecrem=$((elapsec-elapmin*60))
echo "elapsed:  ${elapmin}M${elapsecrem}S"

# --------------------------------------------------------------------------- #
