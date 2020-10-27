#!/bin/bash

while read p; do
	
	echo -e "\nchecking for ${p}....\n-------------------------------------\n"
	
	#which ${p}
	#${p} --version
	
	locbin=$(which ${p})
	
	if [[ -z ${locbin} ]]; then
		echo "ERROR: ${p} missing" >&2
		exit 1
	else
		echo ${locbin}
		${p} --version 2>&1
  	fi

done < prerequisites.txt

