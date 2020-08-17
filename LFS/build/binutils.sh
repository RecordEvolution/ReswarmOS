#!/bin/bash

source logging.sh

# URL to fetch sources and package`s basename
srcurl="http://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz"
srcbas=$(basename ${srcurl})
srcdir=$(echo ${srcbas} | sed 's/.tar.xz//g')

# get source and build directories
src="$1"
bld="$2"
if [ -z "$src" ]; then
  echo "please provide source directory"
  exit 1
fi
if [ -z "$bld" ]; then
  echo "please provide build directory"
  exit 1
fi

# check existence of directories
logging_timestamp_message "checking source and build directories"
if [ ! -d "$src" ]; then
  echo "directory ${src} does not exist => creating it"
  mkdir ${src}
fi
if [ ! -d "$bld" ]; then
  echo "directory ${bld} does not exist => creating it"
  mkdir ${bld}
fi

# get source archive
if [[ -f "$src/$srcbas" ]]
then
  logging_timestamp_message "sources already downloaded"
else
  logging_timestamp_message "downloading sources"
  wget ${srcurl} --directory-prefix=${src}
  # check signature
  # logging_timestamp_message "check signature"
  # wget ${srcurl}.sig --directory-prefix=${src}
  # gpg --verify ${src}/${srcbas}.sig ${src}/${srcbas}
fi

# extract sources
logging_timestamp_message "creating build directory and extracting sources"
tar -xf "${src}/${srcbas}" -C ${src}
mv ${src}/${srcdir} ${src}/binutils

logging_timestamp_message "configuring build process"
pushd ${src}/binutils/
ls
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
popd
