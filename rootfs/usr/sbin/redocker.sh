#!/bin/sh

# JSON parser
JQ=/usr/bin/jq

# include JSON parser
#. /usr/sbin/reparse-json.sh

# check configuration file argument
configfile="$1"
if [ -z ${configfile} ]; then
  echo "no configuration file given (e.g. device-config.reswarm)" >&2
  exit 1
fi

configfileln=$(readlink -f ${configfile})
if [ ! -f ${configfileln} ]; then
  echo "configuration file ${configfile} -> ${configfileln} does not exist" >&2
  exit 1
fi

# extract docker daemon configuration
# TODO *.reswarm configuration should feature its own "docker-daemon" key
# including ALL daemon.json config!!
insecreg=$(cat ${configfile} | $JQ ' . | ."insecure-registries"')
#insecreg=$(parsejsongetkey ${configfile} insecure-registries)

# TODO preliminary
# get rid of outer quotes, replace any single quotes by double quotes
insecreg=$(echo ${insecreg} | sed "s/\"\[/\[/g" | sed "s/\]\"/\]/g")
insecreg=$(echo ${insecreg} | sed "s/'/\"/g")

echo "insecure-registries: ${insecreg}"

if [ "${insecreg}" != "null" ]; then
#if [ ! -z "${insecreg}" ]; then
  # add insecure-registries to /etc/docker/daemon.json
  echo "adding insecure-registries to /etc/docker/daemon.json"
  # sed -i "s/\"insecure-registries\" *: *\[\]/\"insecure-registries\": ${insecreg}/g" /etc/docker/daemon.json
  sed -i "s/\"insecure-registries\" *: *.*,$/\"insecure-registries\": ${insecreg},/g" /etc/docker/daemon.json
  # test it
  #cat rootfs/etc/docker/daemon.json | sed "s/\"insecure-registries\" *: *.*,$/\"insecure-registries\": ${insecreg},/g"
else
  echo "no insecure-registries provided in configuration file"
fi
