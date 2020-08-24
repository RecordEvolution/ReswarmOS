#!/bin/bash

source log/logging.sh

logging_timestamp_message "current date/time settings $(date)"
logging_timestamp_message "filesystem and directories: ls /"
ls /
logging_timestamp_message "filesystem and directories: ls /mnt/"
ls /mnt/ -R

logging_timestamp_message "run version checks of required packages"
./version-check.sh

logging_timestamp_message "check environment variables"
env

logging_timestamp_message "check current working directory"
pwd

# get sources
./prepare/get_sources.sh
