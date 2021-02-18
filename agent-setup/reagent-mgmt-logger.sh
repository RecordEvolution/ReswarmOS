#!/bin/sh

logfile=/var/log/reagent-manager.log

log_reagent_mgmt_event()
{
  # get message
  message="$2"

  # (pseudo) log level, i.e. message type
  loglevel="$1"

  echo "[$(date +%Y-%m-%d_%H-%M-%S-%N)][${loglevel}] ${message}" >> ${logfile}

}
