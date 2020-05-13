#!/bin/bash

# create directory for cross-compiler build
sudo mkdir -p clfs/

# assign corresponding environment variable
export CLFS="$(pwd)/clfs/"
echo "cross-compiled linux from scratch environment path variable: ${CLFS}"

# make directory accessable to anyone
sudo chmod 777 ${CLFS}

# add source directory
mkdir -pv ${CLFS}sources
