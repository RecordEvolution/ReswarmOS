#!/bin/bash

# check .reswarm file argument
reswarmfile="$1"
if [ -z "${reswarmfile}" ]; then
  echo "please provide .reswarm file path" >&2
  exit 1
fi

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
wget https://storage.googleapis.com/re-agent/linux/arm64/0.6.3.1/reagent -P ./

# create Reagent directory
mkdir -pv /opt/reagent/
mv -v ./reagent /opt/reagent/reagent-latest
chmod +x /opt/reagent/reagent-latest

# Reagent systemd service
reagentservice=$(cat << EOF
[Unit]
Description=Reagent
ConditionPathExists=/opt/reagent/reswarm-mode
After=network-online.target
Requires=network-online.target

[Service]
Type=simple
ExecStart=/opt/reagent/reagent-latest -config /opt/reagent/device-config.reswarm -appsDir /apps -debug
RestartSec=30
Restart=yes
Restart=always
CPUWeight=2048
Nice=-16
# CPUAccounting=1
# MemoryAccounting=1
# BlockIOAccounting=1
# IPAccounting=true

[Install]
WantedBy=multi-user.target
EOF
)

# activate IronFlock mode
touch /opt/reagent/reswarm-mode

# set up the service
echo -e "${reagentservice}" > reagent.service
mv -v reagent.service /etc/systemd/system/reagent.service
systemctl enable reagent.service

# configure .reswarm file
cp -v "${reswarmfile}" /opt/reagent/device-config.reswarm
chown root:root /opt/reagent/device-config.reswarm

ls -lh /opt/reagent/

# create apps directory
mkdir -pv /apps
ls -lhd /apps

# start the Reagent service
systemctl restart reagent.service

sleep 5

systemctl status reagent.service | cat

