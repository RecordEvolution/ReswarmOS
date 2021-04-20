#!/bin/bash

vrsn=$(cat config.yaml | grep version | awk -F ':' '{print $2}' | tr -d ' ')
gthsh=$(git rev-parse HEAD)
gthshshort=$(git rev-parse --short HEAD)
# tsdate=$(git log -1 --format=%cd --date=format:"%Y%m%dT%H%M%S")
tsdate=$(date +%Y%m%dT%H%M%S)

osrls=$(cat << EOF
NAME=ReswarmOS
VERSION=v${vrsn}-${gthshshort}-${tsdate}
ID=reswarmos
VERSION_ID=${gthsh}
PRETTY_NAME="ReswarmOS-${vrsn}"
EOF
)

echo -e "${osrls}"
