#!/bin/bash

relPathConfig="$1"
if [ -z "${relPathConfig}" ]; then
  echo "missing relative path to buildroot/packages/Config.in" >&2
  exit 1
fi

shadowMenu="Miscellaneous"
shadowEntry="source \"package/shadow/Config.in\""

cat "${relPathConfig}" | grep "${shadowMenu}" -A 99999 | grep "endmenu" -m1 -B 99999

