#!/bin/bash

source minimal_distro/logging.sh

# implementation of reference
# https://www.linuxjournal.com/content/diy-build-custom-minimal-linux-distribution-source

#-----------------------------------------------------------------------------#
# Configuring the Environment

# turn on bash hash functions
set +h

# newly created files/directories are only writeable/readable by the current user
umask 022

# choose and create main build directory
export LXOS=$HOME/mf-os

if [[ -d "$LXOS" ]]; then
  logging_message "main build directory ${LXOS} already exists"
else
  logging_message "creating main build directory ${LXOS}"
  mkdir -pv ${LXOS}
fi

# define auxiliary environment variables
export LC_ALL=POSIX
export PATH=${LXOS}/cross-tools/bin:/bin:/usr/bin

# create target image`s filesystem hierachy (see https://refspecs.linuxfoundation.org/fhs.shtml)
logging_message "creating/ensuring target image's filesystem hierachy"
mkdir -pv ${LXOS}/{bin,boot{,grub},dev,{etc/,}opt,home,lib/{firmware,modules},lib64,mnt}
mkdir -pv ${LXOS}/{proc,media/{floppy,cdrom},sbin,srv,sys}
mkdir -pv ${LXOS}/var/{lock,log,mail,run,spool}
mkdir -pv ${LXOS}/var/{opt,cache,lib/{misc,locate},local}
install -dv -m 0750 ${LXOS}/root
install -dv -m 1777 ${LXOS}{/var,}/tmp
install -dv ${LXOS}/etc/init.d
mkdir -pv ${LXOS}/usr/{,local/}{bin,include,lib{,64},sbin,src}
mkdir -pv ${LXOS}/usr/{,local/}share/{doc,info,locale,man}
mkdir -pv ${LXOS}/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv ${LXOS}/usr/{,local/}share/man/man{1,2,3,4,5,6,7,8}
for dir in ${LXOS}/usr{,/local}; do
  ln -svf share/{man,doc,info} ${dir}
done

# directory for cross-compilation
logging_message "creating directory for cross-compilation"
install -dv ${LXOS}/cross-tools{,/bin}

# maintain list of mounted filesystems
logging_message "maintain list of mounted filesystems"
ln -svf /proc/mounts ${LXOS}/etc/mtab

# generate password/user file
# as reference:
#   every line in /etc/password relates to one user and has seven fields separated
#   by colons, i.e.
#   username : password : userid : groupid : user info : home directory : default shell
logging_message "generating /etc/password file"
cat << "EOF" > ${LXOS}/etc/passwd
root::0:0:root:/root:/bin/ash
EOF

# NOTE: as reference for the "Here Documents" see
# $ man bash | grep "Here Documents" -A 22

# show result
cat ${LXOS}/etc/passwd

# create /etc/group file
# as reference:
#   every line in /etc/passwd relates to one group and has four fields separated
#   by colons, i.e.
#   groupname : password : groupid : group list (list of users that are members)
logging_message "generating /etc/group file"
cat << "EOF" > ${LXOS}/etc/group
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
daemon:x:6:
disk:x:8:
dialout:x:10:
video:x:12:
utmp:x:13:
usb:x:14:
EOF

# show result
cat ${LXOS}/etc/group

# automate partition mounting
# as reference:
#   - each filesystem is described by a separate line with six fields each
logging_message "generating /etc/fstab file"
cat << "EOF" > ${LXOS}/etc/fstab
# filesystem    mount-point     fstype  options         dump  fsckorder
rootfs          /               auto    defaults        1      1
proc            /proc           proc    defaults        0      0
sysfs           /sys            sysfs   defaults        0      0
devpts          /dev/pts        devpts  gid=4,mode=620  0      0
tmpfs           /dev/shm        tmpfs   defaults        0      0
EOF

# show result
cat ${LXOS}/etc/fstab

# establish profile for root user
logging_message "generating /etc/profile"
cat << "EOF" > ${LXOS}/etc/profile
export PATH=/bin:/usr/bin

if [ `id -u` -eq 0 ] ; then
        PATH=/bin:/sbin:/usr/bin:/usr/sbin
        unset HISTFILE
fi

# Set up some environment variables.
export USER=`id -un`
export LOGNAME=$USER
export HOSTNAME=`/bin/hostname`
export HISTSIZE=1000
export HISTFILESIZE=1000
export PAGER='/bin/more '
export EDITOR='/bin/vi'
EOF

# show result
cat ${LXOS}/etc/profile

# set the target machine`s hostname
logging_message "set target machine's hostname"
echo "linux-machine" > ${LXOS}/etc/hostname

# show result
cat ${LXOS}/etc/hostname

# define content for login prompt
logging_message "set login prompt message"
cat << "EOF" > ${LXOS}/etc/issue
mf.os version 0.1
Kernel \r on an \m

EOF

# show result
cat ${LXOS}/etc/issue

# manage initialization process for BusyBox
logging_message "manage init process of BusyBox"
cat << "EOF" > ${LXOS}/etc/inittab
::sysinit:/etc/rc.d/startup

tty1::respawn:/sbin/getty 38400 tty1
tty2::respawn:/sbin/getty 38400 tty2
tty3::respawn:/sbin/getty 38400 tty3
tty4::respawn:/sbin/getty 38400 tty4
tty5::respawn:/sbin/getty 38400 tty5
tty6::respawn:/sbin/getty 38400 tty6

::shutdown:/etc/rc.d/shutdown
::ctrlaltdel:/sbin/reboot
EOF

# show result
cat ${LXOS}/etc/inittab

# use mdev instead of udev due to usage of BusyBox
logging_message "manage mdev for BusyBox"
cat << "EOF" > ${LXOS}/etc/mdev.conf
# Devices:
# Syntax: %s %d:%d %s
# devices user:group mode

# null does already exist; therefore ownership has to
# be changed with command
null    root:root 0666  @chmod 666 $MDEV
zero    root:root 0666
grsec   root:root 0660
full    root:root 0666

random  root:root 0666
urandom root:root 0444
hwrandom root:root 0660

# console does already exist; therefore ownership has to
# be changed with command
console root:tty 0600 @mkdir -pm 755 fd && cd fd && for x in 0 1 2 3 ; do ln -sf /proc/self/fd/$x $x; done

kmem    root:root 0640
mem     root:root 0640
port    root:root 0640
ptmx    root:tty 0666

# ram.*
ram([0-9]*)     root:disk 0660 >rd/%1
loop([0-9]+)    root:disk 0660 >loop/%1
sd[a-z].*       root:disk 0660 */lib/mdev/usbdisk_link
hd[a-z][0-9]*   root:disk 0660 */lib/mdev/ide_links

tty             root:tty 0666
tty[0-9]        root:root 0600
tty[0-9][0-9]   root:tty 0660
ttyO[0-9]*      root:tty 0660
pty.*           root:tty 0660
vcs[0-9]*       root:tty 0660
vcsa[0-9]*      root:tty 0660

ttyLTM[0-9]     root:dialout 0660 @ln -sf $MDEV modem
ttySHSF[0-9]    root:dialout 0660 @ln -sf $MDEV modem
slamr           root:dialout 0660 @ln -sf $MDEV slamr0
slusb           root:dialout 0660 @ln -sf $MDEV slusb0
fuse            root:root  0666

# misc stuff
agpgart         root:root 0660  >misc/
psaux           root:root 0660  >misc/
rtc             root:root 0664  >misc/

# input stuff
event[0-9]+     root:root 0640 =input/
ts[0-9]         root:root 0600 =input/

# v4l stuff
vbi[0-9]        root:video 0660 >v4l/
video[0-9]      root:video 0660 >v4l/

# load drivers for usb devices
usbdev[0-9].[0-9]       root:root 0660 */lib/mdev/usbdev
usbdev[0-9].[0-9]_.*    root:root 0660
EOF

# configuration for GRUB bootloader
logging_message "creating configuration file for GRUB bootloader"
cat << "EOF" > ${LXOS}/boot/grub/grub.cfg

set default=0
set timeout=5

set root=(hd0,1)

menuentry "mf.os version 0.1" {
        linux   /boot/vmlinuz-4.16.3 root=/dev/sda1 ro quiet
}
EOF

# show result
cat ${LXOS}/boot/grub/grub.cfg

# initialize log files and set their permissions
logging_message "initializing log files and settings associated permissions"
touch ${LXOS}/var/run/utmp ${LXOS}/var/log/{btmp,lastlog,wtmp}
chmod -v 664 ${LXOS}/var/run/utmp ${LXOS}/var/log/lastlog

# show result
ls -lhR ${LXOS}/var/run
ls -lhR ${LXOS}/var/log

#-----------------------------------------------------------------------------#
# Building the Cross Compiler

#-----------------------------------------------------------------------------#
