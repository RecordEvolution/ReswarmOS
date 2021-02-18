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

# set directory of Reagent binaries and base name of any binary
reagentdir="/opt/reagent"
reagentnam="reagent-"
log_reagent_mgmt_event "INFO" "using Reagent binaries ${reagentdir}/${reagentnam}*"

# keep three symbolic links to manage binaries and their updates
reagentActive="${reagentdir}/${reagentnam}active"
reagentLatest="${reagentdir}/${reagentnam}latest"
reagentPrevious="${reagentdir}/${reagentnam}previous"

# (re)start reagent
start_agent() {

  log_reagent_mgmt_event "INFO" "attempting to launch ${REAGENT} with parameters..."
  log_reagent_mgmt_event "INFO" "...appsDirectory: ${appsDir}"
  log_reagent_mgmt_event "INFO" "...config: ${resfile}"

  # nice -2 \
  ${reagentActive} -appsDirectory ${appsDir} \
                   -config ${resfile}
  #            -compressedBuildExtension ${cbldExt} \
  #            -dbFileName ${dbfilen} \
  #            -debug ${debuglg} \
  #            -debugMessaging ${debugMs} \
  #            -initScripts ${initScripts} \
  #            -logFile ${logfile}
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

# get latest agent
get_latest_agent() {

}

# update reagent
update_agent() {

}

# keep observing reagent process and any updates
while true
do

  # check agent process
  prcs=$(check_agent)

  if [ -z ${prcs} ]; then
    start_agent
  fi

  # check for running reagent and any updates every n seconds
	sleep 30

done
