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
log_reagent_mgmt_event "INFO" "using Reagent binaries ${reagentdir}/${reagentname}*"

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

# define length of management cycle
cyclenumsecs=30

# define time-out for version upgrade to be reverted after failure
numcycleout=4
countcycles=999

# check for latest agent
check_latest() {

  #log_reagent_mgmt_event "INFO" "checking for new reagent"

  # find latest reagent binary in given directory
  reagentupgr="${reagentdir}/"$(ls -t ${reagentdir} | grep ${reagentname} | grep -v ${reagentlink} | head -n1)
  if [ -z ${reagentupgr} ]; then
    log_reagent_mgmt_event "CRITICAL" "no reagent binary ${reagentdir}/${reagentname}* found"
  else
    # make sure symbolic link points to latest binary
    if [ ! "$(readlink -f ${reagentLatest})" == "${reagentupgr}" ]; then  
      log_reagent_mgmt_event "INFO" "${reagentupgr} is newer than $(readlink -f ${reagentLatest})"
      rm ${reagentLatest}
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
  if [ ! -L ${reagentActive} ]; then
    log_reagent_mgmt_event "INFO" "linking ${reagentActive} to ${reagentLatest}"
    ln -s $(readlink -f ${reagentLatest}) ${reagentActive}
  fi
  # if reagentPrevious does not yet exist link it to reagentActive
  if [ ! -L ${reagentPrevious} ]; then
    log_reagent_mgmt_event "INFO" "linking ${reagentPrevious} to ${reagentActive}"
    ln -s $(readlink -f ${reagentActive}) ${reagentPrevious}
  fi

  # check status of agent
  agentstatus=$(ps aux | grep ${reagentActive} | grep -v "grep")
  #log_reagent_mgmt_event "INFO" "${agentstatus}"
  if [ -z ${agentstatus} ]; then
    
    log_reagent_mgmt_event "ERROR" "reagent is down => going to restart"

    if [ "$(readlink -f ${reagentLatest})" == "$(readlink -f ${reagentActive})" ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious})" ]; then
        if [ $countcycles -lt $numcycleout ]; then
	  log_reagent_mgmt_event "INFO" "revert upgrade to latest failed reagent ${reagentLatest} (cycle: $countcycles / $numcycleout)"
	  rm ${reagentActive}
          ln -s $(readlink -f ${reagentPrevious}) ${reagentActive}
	  rm ${reagentPrevious}
          ln -s $(readlink -f ${reagentLatest}) ${reagentPrevious}
	fi
      fi
    fi
    /etc/init.d/S97reagent start

  else
 
    if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentActive})" ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious})" ]; then
        log_reagent_mgmt_event "INFO" "upgrading to latest version of reagent ${reagentLatest}"
	rm ${reagentPrevious}
        ln -s $(readlink -f ${reagentActive}) ${reagentPrevious}
	rm ${reagentActive}
        ln -s $(readlink -f ${reagentLatest}) ${reagentActive}
        /etc/init.d/S97reagent restart
	countcycles=0
      fi
    fi

  fi

  # count cycles
  countcycles=$((countcycles+1))

  # check for running reagent and any updates every n seconds
  sleep $cyclenumsecs

done
