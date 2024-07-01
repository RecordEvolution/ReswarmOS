#!/bin/bash

set -e

echo "current user: $(whoami)"
echo "working directory: $(pwd)"

# get required architecture/version from configuration file
ARCH=$(cat ${BR2_CONFIG} | grep 'BR2_ARCH=' | awk -F '=' '{print $2}' | tr -d '" ')
ARCV=$(cat ${BR2_CONFIG} | grep 'BR2_arm1176j' | grep -v "^#" | awk -F '=' '{print $1}')

case $ARCH in
    "x86_64")
        ARCH="amd64"
        BUILD_ARCH=amd64
      ;;
    "arm")
        if [ -z "${ARCV}" ]; then
            BUILD_ARCH=armv7
        else
            BUILD_ARCH=armv6
        fi
      ;;
esac

echo -e "Downloading Agent binary... ($BUILD_ARCH)\n"

wget -O ${BASE_DIR}/build/DeviceManagementAgent/src/reagent "https://storage.googleapis.com/re-agent/linux/$BUILD_ARCH/$(curl -s https://storage.googleapis.com/re-agent/availableVersions.json | jq -r '.production')/reagent"

# copy binary to rootfs as 'reagent-latest'
mkdir -pv ${TARGET_DIR}/opt/reagent/
cp -v ${BASE_DIR}/build/DeviceManagementAgent/src/reagent ${TARGET_DIR}/opt/reagent/reagent-latest
chmod +x ${TARGET_DIR}/opt/reagent/reagent-latest

# check binary
file ${TARGET_DIR}/opt/reagent/reagent-latest

# --------------------------------------------------------------------------- #