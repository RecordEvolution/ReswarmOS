#!/bin/bash

# use reagent management logger
source /usr/bin/reagent-mgmt-logger.sh

# by default, use (latest) *.reswarm configuration file in /boot directory
reswmexst=$(ls /boot/*.reswarm -t | head -n1)

if [ -z ${reswmexst} ]; then
  log_reagent_mgmt_event "ERROR" ".reswarm file missing in /boot"
  exit 1
fi

# set directory of Reagent binaries and base name of any binary
reagentdir="/opt/reagent"
reagentlink="ln-reagent-"
reagentname="reagent-"
log_reagent_mgmt_event "INFO" "using Reagent binaries ${reagentdir}/${reagentnam}*"

# keep three symbolic links to manage binaries including restart/failure/updates
# Rules: (with versions of Active(A), Latest(L), Previous(P); 0=no process, 1=active process)
# 0: L = A = P => start
# 0: L = A > P => A = P, P = L, start
# 0: L = P > A => start
# 1: L > A = P => P = A, A = L, upgrade
# 1: L = P > A => none
# 1: L > P > A => P = A, A = L, upgrade
# 1: L = A > P => none
reagentActive="${reagentdir}/${reagentlink}active"
reagentLatest="${reagentdir}/${reagentlink}latest"
reagentPrevious="${reagentdir}/${reagentlink}previous"

# check for latest agent
check_latest() {

  log_reagent_mgmt_event "INFO" "checking for new reagent"

  # find latest reagent binary in given directory
  reagentupgr=$(ls ${reagentdir}/${reagentname}* -t | head -n1)

  if [ -z ${reagentupr} ]; then
    log_reagent_mgmt_event "CRITICAL" "no reagent binary ${reagentupr}/${reagentname}* found"
  else
    # make sure symbolic link points to latest binary
    if [ ! "$(readlink -f ${reagentLatest})" == "${reagentupgr}" ]; then  
      log_reagent_mgmt_event "INFO" "${reagentupgr} is newer than $(readlinke -f ${reagentLatest})"
      ln -s $(readlink -f ${reagentupgr}) ${reagentLatest}
    fi
  fi
}

# keep observing reagent process and any incoming binary upgrades
while true
do

  # mark latest binary as "reagentLatest"
  check_latest

  # if reagentActive does not yet exist link it to reagentLatest
  #if [ ! -L ${reagentActive} ]; then
  #  log_reagent_mgmt_event "INFO" "linking ${reagentActive} to ${reagentLatest}"
  #  ln -s $(readlink -f ${reagentLatest}) ${reagentActive}
  #fi
  # if reagentPrevious does not yet exist link it to reagentActive
  if [ ! -L ${reagentPrevious} ]; then
    log_reagent_mgmt_event "INFO" "linking ${reagentPrevious} to ${reagentActive}"
    ln -s $(readlink -f ${reagentActive}) ${reagentPrevious}
  fi

  # check status of agent
  agentstatus=$(/etc/init.d/S97reagent status)
  if [ -z ${agentstatus} ]; then
    
    log_reagent_mgmt_event "ERROR" "reagent is down => going to restart"

    if [ "$(readlink -f ${reagentLatest})" == "$(readlink -f ${reagentActive})" ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious})" ]; then
        log_reagent_mgmt_event "INFO" "revert upgrade to latest failed reagent ${reagentLatest}"
        ln -s $(readlink -f ${reagentPrevious}) ${reagentActive}
        ln -s $(readlink -f ${reagentLatest}) ${reagentPrevious}
      fi
    fi
    /etc/init.d/S97reagent start

  else
 
    if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentActive})" ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious})" ]; then
        log_reagent_mgmt_event "INFO" "upgrading to latest version of reagent ${reagentLatest}"
        ln -s $(readlink -f ${reagentActive}) ${reagentPrevious}
        ln -s $(readlink -f ${reagentLatest}) ${reagentActive}
        /etc/init.d/S97reagent restart
      fi
    fi

  fi

  # check for running reagent and any updates every n seconds
  sleep 30

done

