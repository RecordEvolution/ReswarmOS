#!/bin/bash

# exit immediately on a non-zero status
set -e

# --------------------------------------------------------------------------- #

echo "building (latest) Reagent..."
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

# get required architecture/version from configuration file
ARCH=$(cat ${BR2_CONFIG} | grep 'BR2_ARCH=' | awk -F '=' '{print $2}' | tr -d '" ')
ARCV=$(cat ${BR2_CONFIG} | grep 'BR2_arm1176j' | grep -v "^#" | awk -F '=' '{print $1}')
echo "building for architecture: ${ARCH} (${ARCV})"

# build agent binary
if [ ! -f ${BASE_DIR}/build/DeviceManagementAgent/src/reagent ]; then
#if [ 0 == 0 ]; then
  pushd ${BASE_DIR}/build/DeviceManagementAgent/src/
  git pull
  ${GOC} get .
  # for reference, see:
  # - https://github.com/goreleaser/goreleaser/issues/36
  #GOOS=linux GOARCH=${ARCH} CGO_ENABLED=1 GOARM=6(Pi A,B,...,Zero),7(Pi 2,3,4) ${GOC} build .
  # TODO use proper a build-system in DeviceManagementAgent
  if [ -z "${ARCV}" ]; then
    echo "building for GOARM=7"
    CGO_ENABLED=1 GOOS=linux GOARCH=${ARCH} GOARM=7 ${GOC} build -ldflags "-X 'reagent/system.BuildArch=armv7'" .
  else
    echo "building for GOARM=6"
    CGO_ENABLED=1 GOOS=linux GOARCH=${ARCH} GOARM=6 ${GOC} build -ldflags "-X 'reagent/system.BuildArch=armv6'" .
  fi
  popd
fi

# copy binary to rootfs as 'reagent-latest'
mkdir -pv ${TARGET_DIR}/opt/reagent/
cp -v ${BASE_DIR}/build/DeviceManagementAgent/src/reagent ${TARGET_DIR}/opt/reagent/reagent-latest

# check binary
file ${TARGET_DIR}/opt/reagent/reagent-latest

# --------------------------------------------------------------------------- #
