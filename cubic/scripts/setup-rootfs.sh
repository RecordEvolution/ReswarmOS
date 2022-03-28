#!/bin/bash

set -e


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

# Install Docker

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

usermod -aG docker $USER

# Setup MOTD

sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news

sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' /etc/pam.d/sshd
sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/g' /etc/pam.d/login

# Disable old network config
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/97-disable-network-config.cfg
systemctl disable motd-news.timer

# Enable new services

systemctl enable reagent-manager.service
systemctl enable reagent.service
systemctl enable redocker.service
systemctl enable rehost.service
systemctl enable reswarm.service
systemctl enable reuser.service
systemctl enable rewifi.service

# install latest NetworkManager

echo "deb http://archive.ubuntu.com/ubuntu/ impish main" >> /etc/apt/sources.list

apt-get update && apt-get install -y network-manager && rm -rf /var/lib/apt/lists/*

mkdir -p /var/lib/apt/lists/partial

sed -i 's@deb http://archive.ubuntu.com/ubuntu/ impish main@@g' /etc/apt/sources.list

# to run after launch --------------------------------------

# snap remove lxd --purge
# snap remove core18 --purge
# snap remove snapd --purge
# apt purge snapd
# rm -rf ~/snap

# echo 'datasource_list: [ None ]' | tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
# apt purge cloud-init
# rm -rf /var/lib/cloud/



# end to run after launch --------------------------------------

# qemu-system-x86_64 --name "Cubic" -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=reswarm.img -cdrom reswarmos-amd64.iso