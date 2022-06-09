#!/bin/bash

relPathConfig="$1"
if [ -z "${relPathConfig}" ]; then
  echo "missing path to buildroot/packages/Config.in" >&2
  exit 1
fi

addEntry()
{
  # full configuration
  fullConfig="$1"
  # name of menu the new entry is supposed to be inserted in
  menuConfig="$2"
  # new entry, i.e. path of package`s Config.in
  menuEntry="$3"

  if [ -z "${fullConfig}" ]; then
    echo "fullConfig argument is missing" >&2
    return 1
  fi
  if [ -z "${menuConfig}" ]; then
    echo "menuConfig argument is missing" >&2
    return 1
  fi
  if [ -z "${menuEntry}" ]; then
    echo "menuEntry argument is missing" >&2
    return 1
  fi

  # check for existing entry
  exstEntry=$(echo -e "${fullConfig}" | grep "${menuEntry}")

  if [ -z "${exstEntry}" ]; then
    # extract required menu section
    sectionList=$(echo -e "${fullConfig}" | grep "${menuConfig}" -A 99999 | grep "endmenu" -m1 -B 99999)
    # remove prefix/postfix 'menu'/'endmenu'
    cleanList=$(echo -e "${sectionList}" | grep -v '^menu' | grep -v '^endmenu')
    # append new entry and sort all entries
    newList=$(echo -e "${cleanList}\n\t${menuEntry}")
    newListSorted=$(echo -e "${newList}" | sort)

    # replace newlines with some other entity in both original and new list
    clnList=$(echo -e "${cleanList}" | tr '\n' '\Z' | sed 's/\//\\\//g')
    sedList=$(echo -e "${newListSorted}" | tr '\n' '\Z' | sed 's/\//\\\//g')

    # replace newlines in full Config.in
    fullList=$(echo -e "${fullConfig}" | tr '\n' '\Z')

    # perform replacement of old with new package list in specific menu section
    fullListRepl=$(echo "${fullList}" | sed "s/${clnList}/${sedList}/g" | tr '\Z' '\n')

    echo -e "${fullListRepl}"
  else
    echo -e "${fullConfig}"
  fi
}

# --------------------------------------------------------------------------- #

# get full config
fullConfig=$(cat ${relPathConfig})

# list packages with the menu name they are supposed to go in and their entry

# ...shadow
shadowMenu="Miscellaneous"
shadowEntry="source \"package/shadow/Config.in\""
fullConfig=$(addEntry "${fullConfig}" "${shadowMenu}" "${shadowEntry}")

# ...next package...
# ...

echo -e "${fullConfig}"

