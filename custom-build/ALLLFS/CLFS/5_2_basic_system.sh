#!/bin/bash

# create a standard directory tree in the target CLFS file system
# for reference of Filesystem Hierarchy Standard (FHS)
# http://refspecs.linuxfoundation.org/fhs.shtml
mkdir -pv ${CLFS}/targetfs/{bin,boot,dev,etc,home,lib/{firmware,modules}}
mkdir -pv ${CLFS}/targetfs/{mnt,opt,proc,sbin,srv,sys}
mkdir -pv ${CLFS}/targetfs/var/{cache,lib,local,lock,log,opt,run,spool}
install -dv -m 0750 ${CLFS}/targetfs/root
install -dv -m 1777 ${CLFS}/targetfs/{var/,}tmp
mkdir -pv ${CLFS}/targetfs/usr/{,local/}{bin,include,lib,sbin,share,src}

# list of mounted file systems
ln -svf ../proc/mounts ${CLFS}/targetfs/etc/mtab


# create the password file (root password will be set later)
cat > ${CLFS}/targetfs/etc/passwd << "EOF"
root::0:0:root:/root:/bin/ash
EOF

# create the groups
cat > ${CLFS}/targetfs/etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
tape:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
EOF
