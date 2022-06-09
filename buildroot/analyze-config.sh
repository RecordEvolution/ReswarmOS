#!/bin/bash

configpath="$1"

# include timestamp in logfile
#tmstmp=$(date +%FT%H-%M-%S)
tmstmp=$(date +%F)
#clncfg="./config_clean_${tmstmp}.log"
clncfg="./config_clean.log"
brtype="./config_types.log"
analog="./config_analy.log"
analst="./config_detai.log"

# check CLI argument, i.e. configuration file path
if [ -z "${configpath}" ]; then
  echo "missing configuration file" >&2
  exit 1
fi

# clean configuration from comments and empty lines
cfgclean=$(cat ${configpath} | grep -v "^#" | grep -v "^ *$")
echo "${cfgclean}" > "${clncfg}"
echo -e "\nnumber of lines in clean configuration\n"
echo "${cfgclean}" | wc -l

# determine list of "BR2_*" types
br2types=$(echo "${cfgclean}" | awk -F '_' '{print $1"_"$2}' | awk -F '=' '{print $1}' | sort | uniq)
br2typesnum=$(echo "${br2types}" | wc -l)
echo -e "\nBR2 types (${br2typesnum})\n"
echo "$(echo ${br2types} | sed 's/$/ /g' | tr -d '\n')"
echo -e "${br2types}" > "${brtype}"

# non "BR2_*" lines ?
echo -e "\nnon BR2 types\n"
echo "${cfgclean}" | grep -v "^BR2"

# find number of occurences
br2typesstats=""
br2typecount=0
for cfg in ${br2types}; do
  # count occurences of "cfg" and append result to string
  cfgnum=$(grep -Pc "^${cfg}[_=]{1}" "${clncfg}")
  br2typesstats=$(echo -e "${br2typesstats}\n${cfgnum},${cfg}")
  # total count
  br2typecount=$((br2typecount+cfgnum))
done

# BR2 types sorted by frequency
echo -e "\nBR2 type frequency (${br2typecount})\n"
br2typessort=$(echo "${br2typesstats}" | sort --numeric-sort --reverse)
echo -e "${br2typessort}"
echo -e "${br2typessort}" > "${analog}"

# list all BR2 entries of every type
echo "" > "${analst}"
for cfg in ${br2typessort}; do
  brt=$(echo "${cfg}" | awk -F ',' '{print $2}')
  cfgnum=$(grep -Pc "^${brt}[_=]{1}" "${clncfg}")
  echo -e "\n${brt}:${cfgnum}" >> "${analst}"
  grep -P "^${brt}[_=]{1}" "${clncfg}" >> "${analst}"
done

