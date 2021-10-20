#!/bin/bash

# update and install docker and vim
apt-get update && apt-get install -y docker.io vim

# install net-tools, iproute, etc.
apt-get update && apt-get install -y net-tools iproute2
apt-get update && apt-get install -y wget
apt-get update && apt-get install -y dnsutils

# install NetworkManager command line tool
apt-get update && apt-get install -y network-manager

# install parsing auxiliaries
apt-get update && apt-get install -y jq

sleep 2

# download Reagent for aarch64 architecture
wget https://storage.googleapis.com/re-agent/linux/arm64/0.6.3.1/reagent -P ~/Downloads/

# create Reagent directory
mkdir -pv /opt/reagent/
mv -v ~/Downloads/reagent /opt/reagent/reagent-latest

