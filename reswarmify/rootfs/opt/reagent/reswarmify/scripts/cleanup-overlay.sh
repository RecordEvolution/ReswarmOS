echo "Cleaning leftover systen files..."

# Remove Docker related files
rm /etc/docker/daemon-nvidia.json 2>/dev/null
rm /etc/docker/daemon.json 2>/dev/null

# Remove NetworkManager related files
rm /etc/NetworkManager/03-interface-changed 2>/dev/null
rm /etc/NetworkManager/NetworkManager.conf 2>/dev/null

# Remove MOTD
rm /etc/profile/motd.sh 2>/dev/null

# Remove disabling of auto-updates
rm /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null

echo "Finished cleaning up overlay"

exit 0