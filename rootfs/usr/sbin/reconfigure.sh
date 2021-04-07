#!/bin/sh

# source the configuration parser
. /usr/sbin/reparse-ini.sh

# check configuration file argument
configfile="$1"
if [ -z ${configfile} ]; then
  echo "no configuration file given (e.g. device.ini)" >&2
  exit 1
fi

if [ ! -f ${configfile} ]; then
  echo "configuration file ${configfile} does not exist" >&2
  exit 1
fi

# set up hostname according to given configuration file
hostnm=$(readini ${configfile} device HOSTNAME)
if [ -z ${hostnm} ]; then
  echo "empty hostname found" >&2
  exit 1
fi
echo "using hostname ${hostnm}"
#echo "${hostnm}" > /etc/hostname
#hostname "${hostnm}"
hostnamectl set-hostname "${hostnm}"
hostnamectl
