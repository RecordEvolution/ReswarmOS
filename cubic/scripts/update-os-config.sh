#!/bin/bash

vrsn=$(cat project/rootfs-overlay/etc/setup.yaml | grep version | awk -F ':' '{print $2}' | tr -d ' ')
gthsh=$(git rev-parse HEAD)
gthshshort=$(git rev-parse --short HEAD)
gtbranch=$(git rev-parse --abbrev-ref HEAD)
tsdate=$(date +%Y%m%dT%H%M%S)
#basename=$(cat /etc/os-release-base | grep "^NAME=" | awk -F '=' '{print $2}' | tr -d '" ')
#basevrsn=$(cat /etc/os-release-base | grep "^VERSION=" | awk -F '=' '{print $2}' | tr -d '" ')
#NAME=ReswarmOS (based on ${basename} ${basevrsn})
osrls=$(cat << EOF
NAME=ReswarmOS
VERSION=v${vrsn}-${gthshshort}-${tsdate}
ID=reswarmos
VERSION_ID=${gthsh}
PRETTY_NAME="ReswarmOS-x86_64-${vrsn}"
EOF
)
echo -e "${osrls}" > project/rootfs-overlay/etc/os-release