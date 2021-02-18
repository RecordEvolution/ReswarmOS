#!/bin/bash

# use reagent management logger
source reagent-mgmt-logger.sh

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

# set directory of Reagent binaries and base name of any binary
reagentdir="/opt/reagent"
reagentnam="reagent-"
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
reagentActive="${reagentdir}/${reagentnam}active"
reagentLatest="${reagentdir}/${reagentnam}latest"
reagentPrevious="${reagentdir}/${reagentnam}previous"

# (re)start reagent
start_agent() {

  log_reagent_mgmt_event "INFO" "attempting to launch ${reagentActive} with parameters..."
  log_reagent_mgmt_event "INFO" "...appsDirectory: ${appsDir}"
  log_reagent_mgmt_event "INFO" "...config: ${resfile}"

  nohup \
  # nice -2 \
  ${reagentActive} -appsDirectory ${appsDir} \
                   -config ${resfile} \
#                   -compressedBuildExtension ${cbldExt} \
#                   -dbFileName ${dbfilen} \
#                   -debug ${debuglg} \
#                   -debugMessaging ${debugMs} \
#                   -initScripts ${initScripts} \
#                   -logFile ${logfile}
  &
}

kill_agent() {

  log_reagent_mgmt_event "INFO" "preparing to kill agent process"

  # check process and get id
  prcs=$(check_agent)
  prcsid=$(echo ${prcs} | awk -F ' ' '{print $2}')
  log_reagent_mgmt_event "INFO" "reagent process: ${prcs} with id: ${prcsid}"

  # send SIGTERM to process
  log_reagent_mgmt_event "INFO" "sending SIGTERM to process id ${prcsid}"
  kill -TERM ${prcsid}

  # check process once more
  prcs=$(check_agent)
  prcsid=$(echo ${prcs} | awk -F ' ' '{print $2}')
  if [ -z ${prcs} ]; then

    log_reagent_mgmt_event "INFO" "reagent process successfully terminated"

  else

    log_reagent_mgmt_event "INFO" "reagent process did not terminate => waiting..."
    sleep 30

    # check process third time
    prcs=$(check_agent)
    prcsid=$(echo ${prcs} | awk -F ' ' '{print $2}')
    if [ -z ${prcs} ]; then
      log_reagent_mgmt_event "INFO" "reagent process finally terminated"
    else
      log_reagent_mgmt_event "INFO" "reagent process refused to terminate => going to kill it"
      kill -KILL ${prcsid}
    fi

  fi
}

# check agent process
check_agent() {

  log_reagent_mgmt_event "INFO" "check for reagent process"

  # check for running reagent process
  prcs=$(ps aux | grep "${reagentnam}" | grep -v "grep")

  if [ -z ${prcs} ]; then
    log_reagent_mgmt_event "CRITICAL" "no reagent process found"
  else
    log_reagent_mgmt_event "INFO" "found reagent process: ${prcs}"
  fi

  echo "${prcs}"
}

# check for latest agent
check_latest() {

  log_reagent_mgmt_event "INFO" "checking for new reagent"

  # find latest reagent binary in given directory
  reagentupgr=$(ls ${reagentdir}/${reagentnam}* -t | head -n1)

  if [ -z ${reagentupr} ]; then
    log_reagent_mgmt_event "CRITICAL" "no reagent binary ${reagentupr}/${reagentnam}* found"
  else
    # make sure symbolic link points to latest binary
    compbin=$(readlink -f ${reagentLatest})
    if [ ! "${compbin}" == "${reagentupgr}" ]; then  
      log_reagent_mgmt_event "INFO" "${reagentupgr} is newer than ${compbin}"
      ln -s ${reagentupgr} ${reagentLatest}
    fi
  fi
}

# check for upgrade
check_upgrade() {

  log_reagent_mgmt_event "INFO" "check for reagent upgrade"


}

# update reagent
update_agent() {

  log_reagent_mgmt_event "INFO" "updating reagent from ${reagentActive} to ${reagentLatest}"

  # kill the active reagent process
  kill_agent

  # start the new one
  start_agent
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

  # check agent process
  prcs=$(check_agent)

  # if there's no reagent process, restart the "reagentActive" one
  if [ -z ${prcs} ]; then

    if [ "$(readlink -f ${reagentLatest})" == "$(readlink -f ${reagentActive} ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious} ]; then
        ln -s $(readlink -f ${reagentPrevious}) ${reagentActive}
        ln -s $(readlink -f ${reagentLatest}) ${reagentPrevious}
      fi
    fi
    start_agent

  # check prerequisites for update
  else
 
    if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentActive} ]; then
      if [ "$(readlink -f ${reagentLatest})" != "$(readlink -f ${reagentPrevious} ]; then
        ln -s $(readlink -f ${reagentActive}) ${reagentPrevious}
        ln -s $(readlink -f ${reagentLatest}) ${reagentActive}
	update_agent
      fi
    fi

  fi

  # check for running reagent and any updates every n seconds
  sleep 30

done

