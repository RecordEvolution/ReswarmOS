#!/bin/bash

# 1. include function by $ source logging.sh
# 2. call function by $ logging_timestamp_message "show some logging output"

logging_message()
{
	message="$1"
	echo "$(tput setaf 2)[LOG $(date +%Y-%m-%d_%H-%M-%S-%N)]$(tput sgr0) ${message}"
}

section_message()
{
	header="$1"
	echo -e "\n"
	echo "$(tput setaf 1)--------------------------------------------------------------------------------------------"
	echo "${header}$(tput sgr0)"
	echo -e "\n"
}
