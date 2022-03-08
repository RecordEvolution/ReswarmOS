#!/bin/bash

# specify directory of Reagent binaries and base name of any binary
reagentdir="/opt/reagent"
reagentbin="reagent-"
reagentlin="Reagent-"
echo "using Reagent binaries ${reagentdir}/${reagentbin}*"

# keep three symbolic links to manage binaries including restart/failure/updates
# Rules: (with versions of Active(A), Latest(L), Previous(P); 0=no process, 1=active process)
# (UPDATE: when reagent service is managed by systemd we can rely on an active process)
# 0: L = A = P => start
# 0: L = A > P => A = P, P = L, start
# 0: L = P > A => start
# 1: L > A = P => P = A, A = L, upgrade
# 1: L = P > A => none
# 1: L > P > A => P = A, A = L, upgrade
# 1: L = A > P => none
reagentActive="${reagentdir}/${reagentlin}active"
reagentLatest="${reagentdir}/${reagentlin}latest"
reagentPrevious="${reagentdir}/${reagentlin}previous"

# define length of management cycle
cyclenumsecs=30

# define time-out for version upgrade to be reverted after failure
numcycleout=4
countcycles=999

# check for latest agent
check_latest() {

  #echo "checking for reagent upgrade"

  # find latest reagent binary in given directory
  reagentupgr="${reagentdir}/"$(ls -t ${reagentdir} | grep ${reagentbin} | grep -v ${reagentlin} | head -n1)
  if [ -z ${reagentupgr} ]; then
    echo "no reagent binary ${reagentdir}/${reagentbin}* found"
  else
    # make sure symbolic link points to latest (executable) binary
    if [ ! "${reagentLatest}" == "${reagentupgr}" ]; then
      echo "${reagentupgr} is newer than ${reagentLatest}"
      chmod 755 ${reagentupgr}
      rm -f ${reagentLatest}
      ln -s ${reagentupgr} ${reagentLatest}
    fi
  fi
}

# keep observing reagent process and any incoming binary upgrades
while true
do

  # check for reagent upgrade and evtl. mark latest binary as "reagentLatest"
  check_latest

  # if reagentActive does not yet exist link it to reagentLatest
  if [ ! -L ${reagentActive} ]; then
    echo "linking ${reagentActive} to ${reagentLatest}"
    ln -s ${reagentLatest} ${reagentActive}
  fi
  # if reagentPrevious does not yet exist link it to reagentActive
  if [ ! -L ${reagentPrevious} ]; then
    echo "linking ${reagentPrevious} to ${reagentActive}"
    ln -s ${reagentActive} ${reagentPrevious}
  fi

  # check status of agent
  agentstatus=$(ps aux | grep ${reagentActive} | grep -v "grep" | awk '{print $1}')
  if [ -z ${agentstatus} ]; then

    echo "reagent failed"

    if [ "${reagentLatest}" == "${reagentActive}" ]; then
      if [ "${reagentLatest}" != "${reagentPrevious}" ]; then
        if [ $countcycles -lt $numcycleout ]; then
          echo "revert upgrade to latest failed reagent ${reagentLatest} (cycle: $countcycles / $numcycleout)"
          rm -f ${reagentActive}
          ln -s ${reagentPrevious} ${reagentActive}
          rm -f ${reagentPrevious}
          ln -s ${reagentLatest} ${reagentPrevious}
        fi
      fi
    fi

    # (re)start agent
    agentver=$(${reagentActive} --version)
    echo "(re)starting agent version ${agentver}"
    systemctl start reagent

  else

    if [ "${reagentLatest}" != "${reagentActive}" ]; then
      if [ "${reagentLatest}" != "${reagentPrevious}" ]; then

        echo "upgrading to latest version of reagent ${reagentLatest}"
        rm -f ${reagentPrevious}
        ln -s ${reagentActive} ${reagentPrevious}
        rm -f ${reagentActive}
        ln -s ${reagentLatest} ${reagentActive}

        # check version of binary and restart reagent service
        agentver=$(${reagentActive} --version)
        echo "(re)starting agent version ${agentver}"
        systemctl restart reagent

        countcycles=0
      fi
    fi

  fi

  # count cycles
  countcycles=$((countcycles+1))

  # check for running reagent and any updates every n seconds
  sleep $cyclenumsecs

done
