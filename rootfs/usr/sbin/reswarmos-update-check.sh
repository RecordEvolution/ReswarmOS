#!/bin/bash

# define release file URL of ReswarmOS
releaseURL="https://storage.googleapis.com/reswarmos/supportedImages.json"
echo "using release URL: ${releaseURL}"

# get release file
wget ${releaseURL} -P /tmp

# local path of release file
relFile="/tmp/$(basename ${releaseURL})"

# specify model/board this system is running on
brd=$(cat /etc/setup.yaml | grep "^  board:" | awk -F ':' '{print $2}' | tr -d ' ')
mdl=$(cat /etc/setup.yaml | grep "^  model:" | awk -F ':' '{print $2}' | tr -d ' ')
echo "looking for release for ${brd}:${mdl}"

# obtain build time of latest ReswarmOS image supporting this board/model
latestImage=$(cat ${relFile} | jq --arg brd "$brd" --arg mdl "$mdl" '.boards[] | select(.model == $mdl and .board == $brd) | .latestImage')
echo -e "${latestImage}"
latestImageBldTime=$(cat ${relFile} | jq --arg brd "$brd" --arg mdl "$mdl" '.boards[]  | select(.model == $mdl and .board == $brd) | .latestImage | .buildtime' | tr -d '"')
latestImageUpdate=$(cat ${relFile} | jq --arg brd "$brd" --arg mdl "$mdl" '.boards[]  | select(.model == $mdl and .board == $brd) | .latestImage | .update' | tr -d '"')
latestImageVersion=$(cat ${relFile} | jq --arg brd "$brd" --arg mdl "$mdl" '.boards[]  | select(.model == $mdl and .board == $brd) | .latestImage | .version' | tr -d '"')

# remove any release file
rm -vf ${relFile}.*
rm -vf ${relFile}

if [ -z "${latestImageBldTime}" ]; then
  echo "no ReswarmOS image available supporting this board/model" >&2
  exit 1
else
  echo "build time of latest image supporting ${brd}:${mdl}: ${latestImageBldTime}"
fi

# get build time of ReswarmOS we're running on
thisBldTime=$(cat /etc/os-release | grep "^VERSION=" | awk -F '=' '{print $2}' | awk -F '-' '{print $3}' | tr -d ' ')
echo "build time of running system: ${thisBldTime}"

# compare build times
lstBldTime=$(echo ${latestImageBldTime} | tr -d 'T')
thsBldTime=$(echo ${thisBldTime} | tr -d 'T')
echo $lstBldTime
echo $thsBldTime
if [ $lstBldTime -gt $thsBldTime ]; then
  echo "update available (version ${latestImageVersion})"
  touch "/etc/reswarmos-update"
  echo "${latestImageVersion},${latestImageBldTime},${latestImageUpdate}" > /etc/reswarmos-update
  echo "${latestImage}" > /etc/os-release-latest.json
else
  echo "running system is up to date"
  echo "${latestImage}" > /etc/os-release-latest.json
fi

