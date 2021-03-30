#!/bin/sh

# check for (latest) *.reswarm device configuration file on /boot partition
reswarmcfg=$(ls -t /boot/*.reswarm | head -n1)

# reswarm mode
if [ ! -z ${reswarmcfg} ]; then

  echo "latest *.reswarm configuration ${reswarmcfg}"

  # set up symbolic link targeting latest configuration
  ln -svf ${reswarmcfg} /opt/reagent/device-config.reswarm

  # make sure link to active reagent binary exists
  if [ ! -L /opt/reagent/reagent-active ]; then
    ln -sv /opt/reagent/reagent-latest /opt/reagent/ln-reagent-active
  fi

# standalone/free mode
else

  echo "no *.reswarm configuration found in /boot"

fi
