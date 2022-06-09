#!/bin/bash

vrsn=$(cat setup.yaml | grep version | awk -F ':' '{print $2}' | tr -d ' \n')
osvr=$(cat setup.yaml | grep osvariant | awk -F ':' '{print $2}' | tr -d ' \n')
gthsh=$(git rev-parse HEAD)
gthshshort=$(git rev-parse --short HEAD)
gtbranch=$(git rev-parse --abbrev-ref HEAD)
# tsdate=$(git log -1 --format=%cd --date=format:"%Y%m%dT%H%M%S")
tsdate=$(date +%Y%m%dT%H%M%S)

osrls=$(cat << EOF
NAME=ReswarmOS-${osvr}
VERSION=v${vrsn}-g${gthshshort}-${tsdate}
ID=reswarmos
VERSION_ID=g${gthsh}
PRETTY_NAME="ReswarmOS-${vrsn}"
EOF
)

echo -e "${osrls}"
