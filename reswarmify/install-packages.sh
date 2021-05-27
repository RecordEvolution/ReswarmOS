#!/bin/bash

source logging.sh

#-----------------------------------------------------------------------------#

logging_header "install required packages"

# disable unattended upgrades
#logging_message "deactivate any unattended-upgrades.service"
#upgradesrvc=$(systemctl list-units --all | grep "unattended-upgrades.service")
#if [ ! -z "${upgradesrvc}" ]; then
#  systemctl disable unattended-upgrades.service
#  systemctl stop unattended-upgrades.service
#  systemctl status unattended-upgrades.service | cat
#fi

# update system
logging_message "update system"
apt-get update && apt-get upgrade -y

# install docker and git
logging_message "install docker and git"
apt-get update && apt-get install -y docker.io git

# install net-tools, iproute, etc.
logging_message "install net-tools, iproute2, ..."
apt-get update && apt-get install -y net-tools iproute2
apt-get update && apt-get install -y wget

# install NetworkManager command line tool
logging_message "install NetworkManager"
apt-get update && apt-get install -y network-manager

# install parsing auxiliaries
logging_message "install jq JSON parser"
apt-get update && apt-get install -y jq

sleep 2

#-----------------------------------------------------------------------------#
