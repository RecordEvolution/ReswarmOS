#!/bin/bash

source logging.sh

logging_timestamp_message "obtain list of required sources"
wgetlist="http://www.linuxfromscratch.org/lfs/view/stable/wget-list"
wget ${wgetlist}

logging_timestamp_message "download all sources in list"
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
ls -lh

logging_timestamp_message "list sources"
ls -lh $LFS/sources

logging_timestamp_message "check integrity of sources"
md5sums="http://www.linuxfromscratch.org/lfs/view/stable/md5sums"
wget ${md5sums}
mv md5sums $LFS/sources
pushd $LFS/sources
md5sum -c md5sums
popd
