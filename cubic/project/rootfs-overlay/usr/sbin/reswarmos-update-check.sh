#!/bin/bash

# define release file URL of ReswarmOS
releaseURL="https://storage.googleapis.com/reswarmos/supportedBoardsImages.json"
echo "using release URL: ${releaseURL}"

# get release file
wget ${releaseURL} -P /tmp

# local path of setup.yaml
stpyml=/etc/setup.yaml

# path of running system's release file
sysRls=/etc/os-release

# local path of release file
relFile="/tmp/$(basename ${releaseURL})"

# specify model/board and OS name/variant this system is running on
brd=$(cat ${stpyml} | grep "^  board:" | awk -F ':' '{print $2}' | tr -d ' ')
mdl=$(cat ${stpyml} | grep "^  model:" | awk -F ':' '{print $2}' | tr -d ' ')
osn=$(cat ${stpyml} | grep "^  osname:" | awk -F ':' '{print $2}' | tr -d ' ')
osv=$(cat ${stpyml} | grep "^  osvariant:" | awk -F ':' '{print $2}' | tr -d ' ')
echo "looking for release for ${brd}:${mdl} and ${osn}:${osv}"

# obtain object (build time) of latest (ReswarmOS) image supporting this board/model
boardRelease=$(cat ${relFile} | jq --arg brd "$brd" --arg mdl "$mdl" '.boards[] | select(.model == $mdl and .board == $brd)')
echo -e "${boardRelease}"
imageRelease=$(echo "${boardRelease}" | jq --arg osn "$osn" --arg osv "$osv" '.latestImages[] | select(.osname == $osn and .osvariant == $osv )')
echo -e "${imageRelease}"
latestImageBldTime=$(echo "${imageRelease}" | jq .buildtime | tr -d '"')
latestImageUpdate=$(echo "${imageRelease}" | jq .update | tr -d '"')
latestImageVersion=$(echo "${imageRelease}" | jq .version | tr -d '"')

# remove any release file
rm -vf ${relFile}.*
rm -vf ${relFile}

if [ -z "${latestImageBldTime}" ]; then
  echo "no ReswarmOS image available supporting this board/model with same OS name/version" >&2
  exit 1
else
  echo "build time of latest image supporting ${brd}:${mdl} and ${osn}:${osv} : ${latestImageBldTime}"
fi

# get build time of ReswarmOS we're running on
thisBldTime=$(cat ${sysRls} | grep "^VERSION=" | awk -F '=' '{print $2}' | awk -F '-' '{print $3}' | tr -d ' ')
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

