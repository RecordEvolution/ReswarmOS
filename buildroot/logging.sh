#!/bin/bash

# 1. include function by $ source logging.sh
# 2. call function by $ logging_message "show some logging output"
#
# Keep in mind that the "tput ..." requires the environment variable 
# "TERM=xterm-256color"

# --------------------------------------------------------------------------- #

logging_header()
{
  # get name of header
  header="$1"

  # get name of calling script (including line number)
  scrcallnam=$(caller | awk -F ' ' '{print $2}')
  scrcalllno=$(caller | awk -F ' ' '{print $1}')

  if [ -z "${header}" ]; then
    echo "logging.sh: logging_header(): ${scrcallnam}:${scrcalllno}: argument 'header' missing" >&2
    exit 1
  fi
  
  echo "$(tput setaf 1)"
  echo -e "${header}"
  echo -e "----------------------------------------------------------------------"
  echo "$(tput sgr0)"
}

# --------------------------------------------------------------------------- #

logging_message()
{
  # get message
  message="$1"
  
  if [ -z "${message}" ]; then
    echo "logging.sh: logging_message(): argument 'message' missing" >&2
    exit 1
  fi

  # get log level and generate string
  loglevel="$2"
  logd=""
  if [[ ! -z ${loglevel} ]]; then
    logd="[${loglevel}]"
  fi

  # get name of calling script (including line number)
  scrcallnam=$(caller | awk -F ' ' '{print $2}')
  scrcalllno=$(caller | awk -F ' ' '{print $1}')

  echo "$(tput setaf 2)[$(date +%Y-%m-%d_%H-%M-%S-%N)]$(tput setaf 1)[${scrcallnam}:${scrcalllno}]$(tput sgr0)${logd} ${message}"
}

# --------------------------------------------------------------------------- #

logging_error()
{
  # get message
  message="$1"

  if [ -z "${message}" ]; then
    echo "logging.sh: logging_error(): argument 'message' missing" >&2
    exit 1
  fi

  # get name of calling script (including line number)
  scrcallnam=$(caller | awk -F ' ' '{print $2}')
  scrcalllno=$(caller | awk -F ' ' '{print $1}')

  echo "$(tput setaf 2)[$(date +%Y-%m-%dT%H-%M-%S.%N)]$(tput setaf 1)[${scrcallnam}:${scrcalllno}]$(tput sgr0)${message}" >&2 
}

# --------------------------------------------------------------------------- #

