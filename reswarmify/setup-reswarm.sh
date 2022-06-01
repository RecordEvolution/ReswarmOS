#!/bin/bash

while getopts "f:" flag
do
    case "${flag}" in
        f) file=${OPTARG};;
    esac
done

if [ -z "$file" ]; then
    echo "'-f' argument is required, please provide the device config file."
    exit 1
fi

filePath=$(realpath ${file})

cat $filePath | jq type >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "The device configuration file is invalid."
    exit 1
fi

set -e

echo "Intialising Reswarmify process with config file: $filePath"

# setup folders

mkdir -p /opt/reagent/docker-apps

# Install main packages

apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    net-tools \
    iproute2 \
    dnsutils \
    network-manager \
    jq \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Overlay filesystem

wget https://storage.googleapis.com/reswarmos/reswarmify/rootfs.tar.gz -O /tmp/rootfs.tar.gz && tar -xvzf /tmp/rootfs.tar.gz -C /tmp

cp -R /tmp/rootfs/* /

# Download agent

UNAME_ARCH=$(uname -m)

if [ "$UNAME_ARCH" == "x86_64" ]; then
    arch="amd64"
fi

if [ "$UNAME_ARCH" == "aarch64" ]; then
    arch="arm64"
fi

curl "https://storage.googleapis.com/re-agent/linux/$arch/$(curl https://storage.googleapis.com/re-agent/availableVersions.json | jq -r '.production')/reagent" -o /opt/reagent/reagent
chmod +x /opt/reagent/reagent

# Install Docker

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker $USER

# Disable old network config
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/97-disable-network-config.cfg || true >/dev/null 2>&1

systemctl disable motd-news.timer

# Setup MOTD

sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news || true >/dev/null 2>&1

sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' /etc/pam.d/sshd
sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' /etc/pam.d/login

# Enable new services

systemctl enable reagent-manager.service
systemctl enable reagent.service
systemctl enable redocker.service
systemctl enable rehost.service
systemctl enable reswarm.service
systemctl enable reuser.service
systemctl enable rewifi.service

reboot