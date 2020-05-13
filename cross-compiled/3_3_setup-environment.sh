#!/bin/bash

# ensure completely empty environment
cat > ~/.bash_profile << "EOF"
exec env -i HOME=${HOME} TERM=${TERM} PS1='\u:\w\$ ' /bin/bash
EOF

# setup a .bashrc
cat > ~/.bashrc << "EOF"
set +h
umask 022
CLFS=${CLFS}
LC_ALL=POSIX
PATH=${CLFS}/cross-tools/bin:/bin:/usr/bin
export CLFS LC_ALL PATH
EOF

source ~/.bash_profile
