#!/bin/bash

# exit immediately on a non-zero status
set -e

# --------------------------------------------------------------------------- #

echo "build Reagent..."
echo "current user: $(whoami)"
echo "working directory: $(pwd)"

# clone agent repository
AGNTREP=https://github.com/RecordEvolution/DeviceManagementAgent.git
git config --global credentials.helper store

if [ ! -d ${BASE_DIR}/build/DeviceManagementAgent ]; then
  git clone --single-branch --depth=1 ${AGNTREP} ${BASE_DIR}/build/DeviceManagementAgent
fi

# golang (cross-) compiler path
GOC=${BASE_DIR}/host/bin/go

# get required architecture from configuration file
ARCH=$(cat ${BR2_CONFIG} | grep 'BR2_ARCH=' | awk -F '=' '{print $2}' | tr -d '" ')
echo "building for architecture: ${ARCH}"

# build agent binary
if [ ! -f ${BASE_DIR}/build/DeviceManagementAgent/src/reagent ]; then
  pushd ${BASE_DIR}/build/DeviceManagementAgent/src/
  ${GOC} get .
  GOOS=linux GOARCH=${ARCH} ${GOC} build .
  popd
fi

# copy binary to rootfs
cp -v ${BASE_DIR}/build/DeviceManagementAgent/src/reagent ${TARGET_DIR}/opt/reagent/

# --------------------------------------------------------------------------- #
