#!/bin/sh


# analyze boot process
systemd-analyze blame
systemd-analyze plot > plot.svg

# read journal file/directory from mounted system image
journalctl -D /media/mario/rootfs/var/log/journal/

# visualize systemd dependency "tree"
systemd-analyze dot > systemd-init.gv
dot -Tps systemd-init.gv -o sytemd-init.ps
