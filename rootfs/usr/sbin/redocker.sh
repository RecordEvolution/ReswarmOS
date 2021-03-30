#!/bin/sh

# check for (latest) *.reswarm device configuration file on /boot partition
reswarmcfg=$(ls -t /boot/*.reswarm | head -n1)

# reswarm mode
if [ ! -z ${reswarmcfg} ]; then

  echo "latest *.reswarm configuration ${reswarmcfg}"

  # extract docker daemon configuration
  # TODO *.reswarm configuration should feature its own "docker-daemon" key
  # including ALL daemon.json config!!
  insecreg=$(cat ${reswarmcfg} | /usr/bin/jq ' . | ."insecure-registries"')
  # TODO preliminary
  # get rid of outer quotes
  insecreg=$(echo ${insecreg} | sed "s/\"\[/\[/g" | sed "s/\]\"/\]/g")
  
  echo "insecure-registries: ${insecreg}"

  # add insecure-registries to /etc/docker/daemon.json
  sed -i "s/\"insecure-registries\" *: *\[\]/\"insecure-registries\": ${insecreg}/g" /etc/docker/daemon.json

# standalone/free mode
else

  echo "no *.reswarm configuration found in /boot"

fi
