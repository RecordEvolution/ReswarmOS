#!/bin/bash

source log/logging.sh

# retrieve CLI arguments
#
# path/name of image
imgname="$1"
# ...boot partition
# ...path
bootdir="$2"
# ....filesystem
bootfst="$3"
# ....size
bootsiz="$4"
# ...root partition
# ...path
rootdir="$5"
# ...filesystem
rootfst="$6"
# ...size
rootsiz="$7"
#

logging_message "generate_image.sh"
echo -e "\nCLI arguments:\n"
echo "1: ${imgname}"
echo "2: ${bootdir}"
echo "3: ${bootfst}"
echo "4: ${bootsiz}"
echo "5: ${rootdir}"
echo "6: ${rootfst}"
echo "7: ${rootsiz}"
echo -e ""

# check arguments
if [[ -z "${imgname}" ]]; then
  echo "warning: name and path of image file are missing" >&2
  exit 1
fi
if [[ -z "${bootdir}" ]]; then
  echo "warning: path of boot directory is missing" >&2
  exit 1
fi
if [[ -z "${bootfst}" ]]; then
  echo "warning: filesytem for boot partition is missing" >&2
  exit 1
fi
if [[ -z "${bootsiz}" ]]; then
  echo "warning: size of boot partition is missing" >&2
  exit 1
fi
if [[ -z "${rootdir}" ]]; then
  echo "warning: path of root diretory is missing" >&2
  exit 1
fi
if [[ -z "${rootfst}" ]]; then
  echo "warning: filesytem for root partition is missing" >&2
  exit 1
fi
if [[ -z "${rootsiz}" ]]; then
  echo "warning: size of root partition is missing" >&2
  exit 1
fi

# create image file of appropriate size
totalsize=$(python3 -c "print(str('${bootsiz}').replace('MB',''))")
# str(${bootsize}).replace('MB','') )")
echo $totalsize
