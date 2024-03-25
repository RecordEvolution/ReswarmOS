echo "Cleaning leftover systen files..."

# Remove Docker related files
rm /etc/docker/daemon-nvidia.json
rm /etc/docker/daemon.json

# Remove NetworkManager related files
rm /etc/NetworkManager/03-interface-changed
rm /etc/NetworkManager/NetworkManager.conf

# Remove MOTD
rm /etc/profile/motd.sh

# Remove disabling of auto-updates
rm /etc/apt/apt.conf.d/20auto-upgrades

echo "Finished cleaning up overlay"

exit 0