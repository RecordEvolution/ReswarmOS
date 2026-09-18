#!/bin/bash

while getopts "f:s" flag
do
    case "${flag}" in
        f) file=${OPTARG};;
        s) disable_suspend=1;;
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

echo "Intialising ironflock-init process with config file: $filePath"

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
    earlyoom \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Overlay filesystem

echo "Preparing the root filesystem...."

wget https://instance-registry.ironflock.com/dl/reswarmos/reswarmify/rootfs.tar.gz -O /tmp/rootfs.tar.gz && tar -xvzf /tmp/rootfs.tar.gz -C /tmp

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

curl "https://instance-registry.ironflock.com/dl/re-agent/linux/$arch/$(curl https://instance-registry.ironflock.com/dl/re-agent/availableVersions.json | jq -r '.production')/reagent" -o /opt/reagent/reagent-latest
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

# The reagent publishes apps with the legacy build+push API, which cannot push
# images that live in containerd's content store: the push aborts with
# "content digest sha256:<layer>: not found" and the release never appears.
# Docker 29 makes the containerd image store the default on FRESH installs, so
# the daemon.json shipped in the rootfs above turns it off again. A host that
# already ran docker keeps its live configuration until the daemon restarts, so
# apply the setting here too and restart only when the store is actually wrong.
# (The graph driver is deprecated upstream — when it is removed the reagent's
# publish path has to learn the containerd store instead.)

echo "Making sure Docker uses the image store the reagent can publish from...."

if command -v docker >/dev/null 2>&1; then
    if [ -f /etc/docker/daemon.json ]; then
        daemon_tmp=$(mktemp)
        if jq '.features = ((.features // {}) + {"containerd-snapshotter": false})' \
            /etc/docker/daemon.json >"$daemon_tmp" 2>/dev/null; then
            install -m 0644 "$daemon_tmp" /etc/docker/daemon.json
        else
            echo "WARNING: could not update /etc/docker/daemon.json - publishing apps from this device may fail." >&2
        fi
        rm -f "$daemon_tmp"
    fi

    if docker info --format '{{json .DriverStatus}}' 2>/dev/null | grep -q 'io.containerd.snapshotter'; then
        echo "Docker is running on the containerd image store; restarting it to pick up the new setting...."
        echo "Note: images held in that store are no longer listed afterwards, so apps get pulled again."
        systemctl restart docker || true

        for _ in $(seq 1 30); do
            docker info >/dev/null 2>&1 && break
            sleep 1
        done

        if docker info --format '{{json .DriverStatus}}' 2>/dev/null | grep -q 'io.containerd.snapshotter'; then
            echo "WARNING: Docker still uses the containerd image store - publishing apps from this device will fail." >&2
        fi
    fi
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

# earlyoom: userspace OOM killer to prevent low-memory hangs that take the device
# offline. The apt package enables it on install; ensure it's active explicitly.
systemctl enable earlyoom.service || true
systemctl start earlyoom.service || true

# Opt-in (-s): prevent the host from auto-suspending. Desktop installs
# (Ubuntu/Debian with GDM/GNOME) ship an idle-suspend timer that fires even at
# the login screen; on the sleep signal NetworkManager tears the NIC down, so
# the host drops offline every ~15 minutes, killing every WAMP session.
# Masking the sleep targets makes logind report CanSuspend=no, so desktop
# sessions stop even trying. Undo with `systemctl unmask <targets>`.
if [ -n "$disable_suspend" ]; then
    echo "Disabling host suspend (masking systemd sleep targets)...."
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target || true
fi