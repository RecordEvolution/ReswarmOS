#!/bin/sh

# define reagent directory
#reagentdir=/opt/reagent/
reagentdir=/root/reagent-bin/

# name of symlink to active reagent binary
reagentact=Reagent-active

# make sure link to active reagent binary exists
#if [ ! -L /opt/reagent/Reagent-active ]; then
#  ln -sv /opt/reagent/reagent-latest /opt/reagent/Reagent-active
#fi

# Raspbian-based ReswarmOS requires architecture dependent reagent
#
# detect current working architecture
archverb=$(lscpu | grep Architecture | awk '{print $2}' | tr -d ' ')
arch=$(echo "${archverb}" | grep -oP "armv[0-9]{1}")
echo "running on architecture: ${archverb}/${arch}"

# base setup of reagent binary directory structure
# /opt/reagent/{reagent-armv6,reagent-armv7}
# where both child directories may contain any number
# of updated binaries, where by definition the one 
# with the latest timestamp for the appropriate architecture

# check for existing link to reagent binary
if [ -L ${reagentdir}${reagentact} ]; then
  # read existing link to get previous working architecture
  prevpath=$(readlink ${reagentdir}${reagentact})
  echo "existing ${reagentdir}${reagentact} is linked to ${prevpath}"
  ls -lh ${reagentdir}${reagentact}
  # compare to current working architecture
  cmparch=$(echo "${prevpath}" | grep -i ${arch})
  # architectures do not agree since apparently device/SD-card was
  # previously booted on a different architecture 
  if [ -z "${cmparch}" ]; then
    echo "previous working architecture differs from current one"
    # remove existing links to previously used reagent binary
    rm -vf ${reagentdir}Reagent-*
    # get latest binary corresponding to current architecture
    lstbin="$(ls -t ${reagentdir}${arch}/reagent*)"
    # set up Reagent-active link
    ln -sv ${lstbin} ${reagentdir}${reagentact}
  fi
# since Reagent link does not exist at all, we have to set it up anyway
else
  echo "no reagent binary symlink found => creating one"
  # get latest binary corresponding to current architecture
  lstbin="$(ls -t ${reagentdir}${arch}/reagent*)"
  echo "latest binary: ${lstbin}"
  # set up Reagent-active link
  ln -sv ${lstbin} ${reagentdir}${reagentact}
fi

# check entire setup
ls -lh ${reagentdir}

