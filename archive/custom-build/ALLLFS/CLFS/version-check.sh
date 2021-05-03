#!/bin/bash

# reference:
# https://clfs.org/view/clfs-embedded/arm/introduction/hostreqs.html

# Simple script to list version numbers of critical development tools
set -e
bash --version | head -n1 | cut -d" " -f2-4
echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1
gcc --version | head -n1
ldd $(which ${SHELL}) | grep libc.so | cut -d ' ' -f 3 | ${SHELL} | head -n 1 \
| cut -d ' ' -f 1-10
grep --version | head -n1
gzip --version | head -n1
m4 --version | head -n1
make --version | head -n1
echo "#include <ncurses.h>" | gcc -E - > /dev/null
patch --version | head -n1
sed --version | head -n1
sudo -V | head -n1
tar --version | head -n1
makeinfo --version | head -n1
