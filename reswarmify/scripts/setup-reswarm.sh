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

jq_check="$(dpkg --get-selections | grep -w "jq")"
if [[ "$jq_check" != *"install"* ]]; then
    echo "Installing prerequisites.... (jq)"
    apt-get update  >/dev/null 2>&1 && apt-get install -y jq >/dev/null 2>&1
fi

cat $filePath | jq type >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "The device configuration file is invalid."
    exit 1
fi

set -e

echo "Intialising Reswarmify process with config file: $filePath"

cp $filePath /boot

# setup folders

mkdir -p /opt/reagent/docker-apps

echo "Installing neccessary packages...."

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

echo "Reswarmifying the root filesystem...."

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

echo "Downloading and Installing the REagent...."

curl "https://storage.googleapis.com/re-agent/linux/$arch/$(curl https://storage.googleapis.com/re-agent/availableVersions.json | jq -r '.production')/reagent" -o /opt/reagent/reagent-latest
chmod +x /opt/reagent/reagent-latest

# Install Docker

if [ ! -f "/usr/share/keyrings/docker-archive-keyring.gpg" ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
fi

if [[ $(which docker) && $(docker --version) ]]; then
    echo "Docker is already installed, skipping installation...."
else
    echo "Installing Docker...." # add pipe yes to it
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io || true
fi

echo "Setting up network configuration...."

# Disable old network config
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/97-disable-network-config.cfg || true >/dev/null 2>&1 # fails here

systemctl disable motd-news.timer

echo "Setting up MOTD...."

# Setup MOTD

sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news >/dev/null 2>&1 || true
sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' /etc/pam.d/sshd || true
sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' /etc/pam.d/login || true

echo "Enabling services...."

# Enable new services

systemctl enable reagent-manager.service
systemctl enable reagent.service
systemctl enable redocker.service
systemctl enable rehost.service
systemctl enable reswarm.service
systemctl enable reuser.service
systemctl enable rewifi.service

systemctl start reagent-manager.service
systemctl start reagent.service
systemctl start redocker.service
systemctl start rehost.service
systemctl start reswarm.service
systemctl start reuser.service
systemctl start rewifi.service