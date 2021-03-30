#!/bin/sh

log_reagent_mgmt_event()
{
  # define location of logfile
  logfile=/var/log/reagent-manager.log
  
  # get message
  message="$2"

  # (pseudo) log level, i.e. message type
  loglevel="$1"

  echo "[$(date +%Y-%m-%d_%H-%M-%S)][${loglevel}] ${message}" >> ${logfile}
}

