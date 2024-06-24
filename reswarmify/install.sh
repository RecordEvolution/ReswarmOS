#!/bin/bash

set -e

uname_result=$(uname -m)

architecture=""

case $uname_result in
    x86_64)
        architecture="amd64"
        ;;
    arm)
        architecture="armv5"
        ;;
    arm64)
        architecture="arm64"
        ;;
    armv6l)
        architecture="armv6"
        ;;
    armv7l)
        architecture="armv7"
        ;;
    aarch64)
        architecture="arm64"
        ;;
    aarch64_be)
        architecture="arm64"
        ;;
    armv8b)
        architecture="arm64"
        ;;
    armv8l)
        architecture="arm64"
        ;;
    *)
        # Default case if architecture doesn't match any of the above
        echo "Unsupported architecture: $uname_result"
        exit 1
        ;;
esac

echo -e "Downloading IronFlock initialization binary... ($architecture)\n"

latest_version=$(wget -qO- https://storage.googleapis.com/reswarmos/reswarmify/version.txt)

# Define the base URL
ironflock_init_download_url="https://storage.googleapis.com/reswarmos/reswarmify/linux/$architecture/$latest_version/ironflock-init"

wget -qO ironflock-init $ironflock_init_download_url --show-progress

echo

chmod +x ironflock-init

binaryPath=$(realpath .)
echo "Download complete!"
echo

echo "To initialize your device use the following example command:"
echo "$binaryPath/ironflock-init -c /path/to/device-config.reswarm"
echo

echo "For other usage and more information, run the following help command:"
echo "$binaryPath/ironflock-init -h"