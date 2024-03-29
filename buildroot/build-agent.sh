#!/bin/bash

# --------------------------------------------------------------------------- #
# build manually on standard Ubuntu distro
#
# install cross-compiler toolchain
#
# $ apt-get install -y gcc-arm-linux-gnueabihf \ # for armhf
#                      gcc-aarch64-linux-gnu     # for aarch64
#
# $ which arm-linux-gnueabihf-gcc aarch64-linux-gnu-gcc
# $ /usr/bin/arm-linux-gnueabihf-gcc
# $ /usr/bin/aarch64-linux-gnu-gcc
#
# armhf
#
# $ CC=arm-linux-gnueabihf-gcc CGO_ENABLED=1 GOOS=linux GOARCH=arm GOARM=7 go get .
# $ CC=arm-linux-gnueabihf-gcc CGO_ENABLED=1 GOOS=linux GOARCH=arm GOARM=7 go build -ldflags "-X 'reagent/release.BuildArch=armv7'" .
#
# aarch64
#
# $ CC=aarch64-linux-gnu-gcc CGO_ENABLED=1 GOOS=linux GOARCH=arm64 GOARM=7 go get .
# $ CC=aarch64-linux-gnu-gcc CGO_ENABLED=1 GOOS=linux GOARCH=arm64 GOARM=7 go build -ldflags "-X 'reagent/release.BuildArch=armv7'" .
#
# --------------------------------------------------------------------------- #

# exit immediately on a non-zero status
set -e

# --------------------------------------------------------------------------- #

echo "building (latest) Reagent..."
echo "current user: $(whoami)"
echo "working directory: $(pwd)"

# clone agent repository
AGNTREP=https://DewitteRuben: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@github.com/RecordEvolution/DeviceManagementAgent.git
git config --global credentials.helper store

if [ ! -d ${BASE_DIR}/build/DeviceManagementAgent ]; then
  git clone ${AGNTREP} ${BASE_DIR}/build/DeviceManagementAgent
  sleep 2
else
  pushd ${BASE_DIR}/build/DeviceManagementAgent/src/
  git pull
  popd
fi

# golang (cross-)compiler path
GOC=${BASE_DIR}/host/bin/go

# get required architecture/version from configuration file
ARCH=$(cat ${BR2_CONFIG} | grep 'BR2_ARCH=' | awk -F '=' '{print $2}' | tr -d '" ')
ARCV=$(cat ${BR2_CONFIG} | grep 'BR2_arm1176j' | grep -v "^#" | awk -F '=' '{print $1}')
echo "building for architecture: ${ARCH} (${ARCV})"

pushd ${BASE_DIR}/build/DeviceManagementAgent/src/

# manage git
git log -1
git status

# get dependencies
${GOC} get .

# AUXILIARY: build independently outside of ReswarmOS build container (given you have arm cross-compiler installed on your host)
# CC=arm-linux-gnueabihf-gcc CGO_ENABLED=1 GOOS=linux GOARCH=arm GOARM=7 go get .
# CC=arm-linux-gnueabihf-gcc CGO_ENABLED=1 GOOS=linux GOARCH=arm GOARM=7 go build -ldflags "-X 'reagent/release.BuildArch=armv7'" .

# for reference, see:
# - https://github.com/goreleaser/goreleaser/issues/36
#GOOS=linux GOARCH=${ARCH} CGO_ENABLED=1 GOARM=6(Pi A,B,...,Zero),7(Pi 2,3,4) ${GOC} build .
# TODO use proper a build-system in DeviceManagementAgent
case $ARCH in
    "x86_64")
        ARCH="amd64"
        BUILD_ARCH=amd64
        CGO_ENABLED=1 GOOS=linux GOARCH=${ARCH} ${GOC} build -ldflags "-X 'reagent/release.BuildArch=${BUILD_ARCH}'" .
      ;;
    "arm")
        if [ -z "${ARCV}" ]; then
            echo "building for GOARM=7"
            BUILD_ARCH=armv7
            CGO_ENABLED=1 GOOS=linux GOARCH=${ARCH} GOARM=7 ${GOC} build -ldflags "-X 'reagent/release.BuildArch=${BUILD_ARCH}'" .
        else
            echo "building for GOARM=6"
            BUILD_ARCH=armv6
            CGO_ENABLED=1 GOOS=linux GOARCH=${ARCH} GOARM=6 ${GOC} build -ldflags "-X 'reagent/release.BuildArch=${BUILD_ARCH}'" .
        fi
      ;;
esac

popd

# copy binary to rootfs as 'reagent-latest'
mkdir -pv ${TARGET_DIR}/opt/reagent/
cp -v ${BASE_DIR}/build/DeviceManagementAgent/src/reagent ${TARGET_DIR}/opt/reagent/reagent-latest

# check binary
file ${TARGET_DIR}/opt/reagent/reagent-latest

# --------------------------------------------------------------------------- #
