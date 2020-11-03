#!/bin/bash

#set -e
#set -u

helpuse=$(cat << 'EOF'
	Usage: ./read-ini.sh <filename.ini> <section> <keyword>
EOF
)

read-config-ini()
{
	inifile="$1"
	section="$2"
	keyword="$3"

	if [ -z ${inifile} ]; then
		echo "argument missing: no file provided" >&2
		echo "${helpuse}"
		exit 1
	else
		iniext=$(echo ${inifile} | grep ".ini")
		if [ -z ${iniext} ]; then
			echo "wrong argument: no .ini file provided" >&2
			echo "${helpuse}"
			exit 1
		else
			if [ ! -f ${inifile} ]; then
				echo "file '${inifile}' does not exist" >&2
				echo "${helpuse}"
				exit 1
			fi
		fi
	fi

	if [ -z ${section} ]; then
		echo "missing argument: no section provided" >&2
		echo "${helpuse}"
		exit 1
	fi

	if [ -z ${keyword} ]; then
		echo "missing argument: no keyword provided" >&2
		echo "${helpuse}"
		exit 1
	fi

	# get second part of config.ini following the start of the required section
	sectionaft=$(cat ${inifile} | grep -v "^#" | grep "\[${section}\]" -A 5000)

	# check for intermediate section vs. final section
	sectionini=$(echo "${sectionaft}" | grep -v "\[${section}\]" | grep "^\[.*\]$" -m1 -B 5000 | grep -v "\[.*\]")
	if [ -z "${sectionini}" ]; then
		sectionini=$(echo "${sectionaft}")
	fi

	# check if section is actually present in configuration file
	if [ -z "${sectionini}" ]; then
		echo "section '${section}' not found" >&2
	else
		# extract the value of keyword
		valuekey=$(echo "${sectionini}" | grep "${keyword}")
		if [ -z "${valuekey}" ]; then
			echo "key '${keyword}' not found" >&2
		else
			# check validity of key-value format
			checkvalid=$(echo "${valuekey}" | awk -F '=' '{print NF}')
			if [ "${checkvalid}" -eq 2 ]; then
				valuekeyclean=$(echo "${valuekey}" | awk -F '=' '{print $2}' | tr -d '"' | sed 's/^ *//g' | sed 's/ *$//g')
				#echo "[${section}] ${keyword} = '${valuekeyclean}'"
				echo "${valuekeyclean}"
			else
				echo "corrupt file or invalid format" >&2
			fi
		fi
	fi

}

