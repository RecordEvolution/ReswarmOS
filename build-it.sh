#!/bin/bash

# exit immediately on a non-zero status
set -e

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

logging_message "ReswarmOS configuration"

# --------------------------------------------------------------------------- #

# set main ReswarmOS configuration file
reswarmcfg="./setup.yaml"
cat ${reswarmcfg}

# parse and validate .yaml configuration file
osname=$(cat ${reswarmcfg} | yq .osname | tr -d "\"" | sed 's/null//g')
osvariant=$(cat ${reswarmcfg} | yq .osvariant | tr -d "\"" | sed 's/null//g')
osversion=$(cat ${reswarmcfg} | yq .version | tr -d "\"" | sed 's/null//g')
board=$(cat ${reswarmcfg} | yq .board | tr -d "\"" | sed 's/null//g')
model=$(cat ${reswarmcfg} | yq .model | tr -d "\"" | sed 's/null//g')
confg=$(cat ${reswarmcfg} | yq .config | tr -d "\"" | sed 's/null//g')
lnxconfg=$(cat ${reswarmcfg} | yq .linuxconfig | tr -d "\"" | sed 's/null//g')
imcfg=$(cat ${reswarmcfg} | yq .image | tr -d "\"" | sed 's/null//g')

if [ -z ${osname} ]; then
  echo "failed to validate configuration .yaml: missing osname specifier" >&2
  exit 1
fi
if [ -z ${osversion} ]; then
  echo "failed to validate configuration .yaml: missing osversion specifier" >&2
  exit 1
fi
if [ -z ${board} ]; then
  echo "failed to validate configuration .yaml: missing board specifier" >&2
  exit 1
fi
if [ -z ${model} ]; then
  echo "failed to validate configuration .yaml: missing model specifier" >&2
  exit 1
fi

# construct image file name
if [ -z ${osvariant} ]; then
  imgname=$(echo "${osname}-${osversion}-${model}.img")
else
  imgname=$(echo "${osname}-${osvariant}-${osversion}-${model}.img")
fi
echo "final image name will be: ${imgname}"

# buildroot configuration file
if [ ! -z ${confg} ]; then
  echo -e "custom configuration specified:"
  cfgfile="./${confg}"
else
  echo "no custom configuration specified: using default:"
  cfgfile="./config/${board}/${model}/config"
fi
echo "${cfgfile}"

# linux configuration file
if [ ! -z ${lnxconfg} ]; then
  echo -e "linux custom configuration specified:"
  lnxcfgfile="./${lnxconfg}"
  echo "${lnxcfgfile}"
else
  echo "no linux custom configuration specified: using default"
  lnxcfgfile=""
fi

# image configuration file
if [ ! -z ${imcfg} ]; then
  echo -e "custom image configuration specified:"
  imcfgfile="./${imcfg}"
else
  echo "no custom image configuration specified: using default:"
  imcfgfile="./config/${board}/${model}/genimage.cfg"
fi
echo "${imcfgfile}"

# determine relative path of rootfs overlay directory
rfsovly=$(realpath --relative-to=./reswarmos-build/buildroot ./rootfs)
echo "relative path of overlay directory: ${rfsovly}"
rfsovly=$(echo ${rfsovly} | sed 's/\//\\\//g')
sed -i "s/BR2_ROOTFS_OVERLAY=\"\"/BR2_ROOTFS_OVERLAY=\"${rfsovly}\"/g" ${cfgfile}
cat ${cfgfile} | grep BR2_ROOTFS_OVERLAY

# employ linux custom configuration
if [ ! -z ${lnxcfgfile} ]; then
  echo "employing custom linux configuration:"
  echo "${lnxcfgfile}"
  lnxcfgpath=$(realpath --relative-to=./reswarmos-build/buildroot ${lnxcfgfile})
  echo "relative path: ${lnxcfgpath}"
  lnxcfgpath=$(echo ${lnxcfgpath} | sed 's/\//\\\//g')
  sed -i "s/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/\# BR2_LINUX_KERNEL_USE_DEFCONFIG is not set/g" ${cfgfile}
  sed -i "/BR2_LINUX_KERNEL_DEFCONFIG=.*/d" ${cfgfile}
  sed -i "s/\# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y\nBR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=\"${lnxcfgpath}\"/g" ${cfgfile}
else
  echo "using linux default configuration"
fi
cat ${cfgfile} | grep -P "BR2_LINUX_KERNEL_.*DEFCONFIG"
cat ${cfgfile} | grep -P "BR2_LINUX_KERNEL_.*CUSTOM_CONFIG"

# --------------------------------------------------------------------------- #

logging_message "github credentials configuration (to access Reagent repo)"

# take care of any (github) credentials
read -p "please enter your username:       " gitusername
read -p "please enter your password/token: " gitpassword

echo "https://${gitusername}:${gitpassword}@github.com" > ~/.git-credentials
git config --global credential.helper store
git config --global --list
ls -lha ~/.

# --------------------------------------------------------------------------- #

logging_message "extracting required buildroot commit from buildroot configuration"

# extract buildroot commit required by particular configuration
comcfg=$(cat ${cfgfile} | grep "^# Buildroot .*-g.*Configuration" | awk -F '-g' '{print $2}' | awk -F ' ' '{print $1}' | tr -d ' ')
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

# --------------------------------------------------------------------------- #

# copy configuration file to buildroot directory
logging_message "copy required configuration file"

if [[ -f ${cfgfile} ]]; then
  #if [[ -f ./reswarmos-build/buildroot/.config ]]; then
  #  echo "buildroot configuration .config already present: remove it to employ a new one"
  #else
  cp -v ${cfgfile} ./reswarmos-build/buildroot/.config
  #fi
else
  echo "sorry, the required config file '${cfgfile}' does not exist!" >&2
  exit 1
fi

# --------------------------------------------------------------------------- #

# inserting external packages
logging_message "adding external packages"

cp -rv ./packages/* ./reswarmos-build/buildroot/package/
./packages/add-to-config.sh ./reswarmos-build/buildroot/package/Config.in > ./Config.in
mv -v ./Config.in ./reswarmos-build/buildroot/package/Config.in

# --------------------------------------------------------------------------- #

# show and check buildroot directory
logging_message "listing buildroot directory"

ls -lhd ./reswarmos-build/buildroot/
ls -lha ./reswarmos-build/buildroot/

# --------------------------------------------------------------------------- #

logging_message "image configuration"

# employ genimage configuration for partitions and image
cp -v "${imcfgfile}" "./reswarmos-build/buildroot/board/${board}/genimage-${model}.cfg" 
# output-build/buildroot/board/raspberrypi/genimage-raspberrypi4.cfg

# insert relative path of boot directory
echo "employ post-build.sh"
cp -v ./config/${board}/${model}/post-build.sh "./reswarmos-build/buildroot/board/${model}/"

# --------------------------------------------------------------------------- #

logging_message "initializing build process"

# generate/update os-version file in rootfs overlay directory
echo "${osname}-${osversion}" > ./rootfs/etc/reswarmos
cat ./rootfs/etc/reswarmos

ls -lhR ./rootfs

# get starting timestamp
startts=$(date)
startsec=$(date +%s)

pushd ./reswarmos-build/buildroot
make -j4
popd

# show produced image file
logging_message "manage image file"
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
