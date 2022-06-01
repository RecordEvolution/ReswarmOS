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

# check architecture
archverb=$(lscpu | grep Architecture | awk '{print $2}' | tr -d ' ')
arch=$(echo "${archverb}" | grep -oP "armv[0-9]{1}")
echo "detected architecture: ${arch}"

# check for latest agent
check_latest() {

  #echo "checking for reagent upgrade"

  # find latest reagent binary in given directory
  reagentupgr=$(ls -t ${reagentdir} | grep ${reagentbin} | grep -v ${reagentlin} | head -n1)
  if [ ! -z ${reagentupgr} ]; then
  #echo "no upgraded reagent binary ${reagentdir}/${reagentbin}* found"
  #else
    # get full path
    reagentupgr="${reagentdir}/${reagentupgr}"
    # make sure new binary is executable
    chmod 755 ${reagentupgr}
    # check its architecture
    # TODO
    # check its version
    rgntversion=$(${reagentupgr} -version)
    # move binary to folder according to current architecture
    mv -v ${reagentupgr} ${reagentdir}/${arch}/${reagentbin}${rgntversion}
    # make sure symbolic link points to latest (executable) binary
    echo "${reagentupgr} is newer than $(readlink -f ${reagentLatest})"
    rm -f ${reagentLatest}
    ln -s ${reagentdir}/${arch}/${reagentbin}${rgntversion} ${reagentLatest}
    ls -lh ${reagentLatest}
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
    if [ ! -L ${reagentLatest} ]; then
      echo "neither ${reagentActive} nor ${reagentLatest} exist" >&2
      exit 1
    fi
    ln -s $(readlink -f ${reagentLatest}) ${reagentActive}
    ls -lh ${reagentActive}
  fi
  # if reagentPrevious does not yet exist link it to reagentActive
  if [ ! -L ${reagentPrevious} ]; then
    echo "linking ${reagentPrevious} to ${reagentActive}"
    if [ ! -L ${reagentActive} ]; then
      echo "neither ${reagentPrevious} nor ${reagentActive} exist" >&2
      exit 1
    fi
    ln -s $(readlink -f ${reagentActive}) ${reagentPrevious}
    ls -lh ${reagentPrevious}
  fi
  # if reagentLatest does not yet exist link it to reagentActive
  if [ ! -L ${reagentLatest} ]; then
    echo "linking ${reagentLatest} to ${reagentActive}"
    if [ ! -L ${reagentActive} ]; then
      echo "neither ${reagentLatest} nor ${reagentActive} exist" >&2
      exit 1
    fi
    ln -s $(readlink -f ${reagentActive}) ${reagentLatest}
    ls -lh ${reagentLatest}
  fi

  # check status of agent
  agentstatus=$(ps aux | grep ${reagentActive} | grep -v "grep" | awk '{print $1}')
  if [ -z ${agentstatus} ]; then

    echo "reagent not started yet/failed"

    if [ "$(readlink -f ${reagentLatest})" == "$(readlink -f ${reagentActive})" ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious})" ]; then
        if [ $countcycles -lt $numcycleout ]; then
          echo "revert upgrade to latest failed reagent ${reagentLatest} (cycle: $countcycles / $numcycleout)"
          rm -f ${reagentActive}
          ln -s $(readlink -f ${reagentPrevious}) ${reagentActive}
          rm -f ${reagentPrevious}
          ln -s $(readlink -f ${reagentLatest}) ${reagentPrevious}
        fi
      fi
    fi

    # (re)start agent
    agentver=$(${reagentActive} --version)
    echo "(re)starting agent version ${agentver}"
    systemctl start reagent

  else

    if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentActive})" ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious})" ]; then

        echo "upgrading to latest version of reagent ${reagentLatest}"
        rm -f ${reagentPrevious}
        ln -s $(readlink -f ${reagentActive}) ${reagentPrevious}
        rm -f ${reagentActive}
        ln -s $(readlink -f ${reagentLatest}) ${reagentActive}

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
