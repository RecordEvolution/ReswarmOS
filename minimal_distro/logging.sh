#!/bin/bash

# 1. include function by $ source logging.sh
# 2. call function by $ logging_timestamp_message "show some logging output"

logging_message()
{
	message="$1"
	echo "$(tput setaf 2)[$(date +%Y-%m-%d_%H-%M-%S-%N)]$(tput sgr0) ${message}"
}
