#!/bin/bash

# use reagent management logger
. reagent-mgmt-logger.sh

# by default, use (latest) *.reswarm configuration file in /boot directory
reswmexst=$(ls /boot/*.reswarm -t | head -n1)

if [ -z ${reswmexst} ]; then
  log_reagent_mgmt_event "ERROR" ".reswarm file missing in /boot"
  exit 1
fi

# assemble CLI parameters
appsDir="/opt/reagent/apps"
cbldExt="tgz"
resfile="${reswmexst}"
dbfilen="reagent.db"
debuglg=""
debugMs=""
initScripts=""
logfile=""

# set directory of Reagent binaries
reagentdir="/opt/reagent"

log_reagent_mgmt_event "INFO" "looking for Reagent binary in ${reagentdir}"

# default symbolic link for "active" binary
reagentactive="${reagentdir}/reagent-active"

# check for soft link to "active" binary
if [ ! -L ${reagentactive} ] || [ ! -e ${reagentactive} ]; then
  log_reagent_mgmt_event "INFO" "reagent soft-link ${reagentactive} is broken or does not exist yet"

  # find latest Reagent binary
  reagentlatest=$(ls -t ${reagentdir}/reagent-* | head -n1)

  if [ -z ${reagentlatest} ]; then
    log_reagent_mgmt_event "ERROR" "no reagent binary (reagent-*) in ${reagentdir}"
    exit 1
  fi

  log_reagent_mgmt_event "INFO" "latest Reagent binary: ${reagentlatest} => creating link"
  ln -s ${reagentlatest} ${reagentactive}

fi

# use latest Reagent
REAGENT=${reagentactive}

log_reagent_mgmt_event "INFO" "attempting to launch ${REAGENT} with parameters..."
log_reagent_mgmt_event "INFO" "...appsDirectory: ${appsDir}"
log_reagent_mgmt_event "INFO" "...config: ${resfile}"

$(REAGENT) -appsDirectory ${appsDir} \
           -config ${resfile}
#            -compressedBuildExtension ${cbldExt} \
#            -dbFileName ${dbfilen} \
#            -debug ${debuglg} \
#            -debugMessaging ${debugMs} \
#            -initScripts ${initScripts} \
#            -logFile ${logfile}
