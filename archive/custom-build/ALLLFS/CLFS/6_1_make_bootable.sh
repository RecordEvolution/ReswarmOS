#!/bin/bash

# let bootloader tell Linux where to find the root file system
cat > ${CLFS}/targetfs/etc/fstab << "EOF"
# file-system  mount-point  type   options          dump  fsck
EOF
