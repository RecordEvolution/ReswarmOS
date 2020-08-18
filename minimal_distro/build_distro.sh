#!/bin/bash

source minimal_distro/logging.sh

# implementation of reference
# https://www.linuxjournal.com/content/diy-build-custom-minimal-linux-distribution-source

# get timestamp at start
startts=$(date)

#-----------------------------------------------------------------------------#
# Configuring the Environment

section_message "Preparation and Configuration"

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
mkdir -pv ${LXOS}/{bin,boot/{,grub},dev,{etc/,}opt,home,lib/{firmware,modules},lib64,mnt}
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

section_message "Building the Cross Compiler"

# unset some environment variables (just to be sure)
unset CFLAGS
unset CXXFLAGS

# create sources directory
logging_message "creating sources directory"
mkdir -pv ${LXOS}/sources

# get the kernel
kernelurl="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.8.1.tar.xz"
kernelbas=$(basename ${kernelurl})
kerneldir=$(echo ${kernelbas} | sed 's/.tar.xz//g')
if [[ -f "${LXOS}/sources/${kernelbas}" ]]; then
  logging_message "Linux kernel was already downloaded to ${LXOS}/sources/${kernelbas}"
else
  logging_message "retrieving the Linux kernel"
  wget ${kernelurl} -P ${LXOS}/sources
fi

# define environment variables for compilation
logging_message "setting environment variables for build process"
export LXOS_HOST=$(echo ${MACHTYPE} | sed 's/-[^-]*/-cross/')
export LXOS_TARGET=x86_64-unknown-linux-gnu
export LXOS_CPU=k8
export LXOS_ARCH=$(echo ${LXOS_TARGET} | sed -e 's/-.*//' -e 's/i.86/i386/')
export LXOS_ENDIAN=little

# show result
env | grep "LXOS"

# extract kernel sources
if [[ -d "${LXOS}/sources/${kerneldir}" ]]; then
  logging_message "kernel sources were already extracted"
else
  logging_message "extracting kernel sources"
  tar -xf "${LXOS}/sources/${kernelbas}" -C "${LXOS}/sources/"
fi

# start compilation/preparation of kernel
logging_message "preparing kernel"
pushd ${LXOS}/sources/${kerneldir}
make mrproper
make ARCH=${LXOS_ARCH} headers_check && make ARCH=${LXOS_ARCH} INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* ${LXOS}/usr/include
popd

# getting the binutils
binutilsurl="http://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz"
binutilsbas=$(basename ${binutilsurl})
binutilsdir=$(echo ${binutilsbas} | sed 's/.tar.xz//g')
if [[ -f "${LXOS}/sources/${binutilsbas}" ]]; then
  logging_message "Binutils were already downloaded to ${LXOS}/sources/${binutilsbas}"
else
  logging_message "retrieving Binutils"
  wget ${binutilsurl} -P ${LXOS}/sources
fi

# extract binutils sources
if [[ -d "${LXOS}/sources/${binutilsdir}" ]]; then
  logging_message "Binutils sources were already extracted"
else
  logging_message "extracting Binutils sources"
  tar -xf "${LXOS}/sources/${binutilsbas}" -C "${LXOS}/sources/"
fi

# create binutils build directory
logging_message "building Binutils"
mkdir -pv ${LXOS}/sources/binutils-build
pushd ${LXOS}/sources/binutils-build
../${binutilsdir}/configure --prefix=${LXOS}/cross-tools --target=${LXOS_TARGET} \
                            --with-sysroot=${LXOS} --disable-nls --enable-shared \
                            --disable-multilib
make configure-host && make
ln -sv lib ${LXOS}/cross-tools/lib64
make install

# copy libiberty.h header file to target filesystem
cp -v ../${binutilsdir}/include/libiberty.h ${LXOS}/usr/include
popd

# get gcc sources
# gccurl="http://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz"
gccurl="https://ftp.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.xz"
gccbas=$(basename ${gccurl})
gccdir=$(echo ${gccbas} | sed 's/.tar.xz//g')
if [[ -f "${LXOS}/sources/${gccbas}" ]]; then
  logging_message "gcc was already downloaded to ${LXOS}/sources/${gccbas}"
else
  logging_message "retrieving gcc"
  wget ${gccurl} -P ${LXOS}/sources
fi

# extract gcc sources
if [[ -d "${LXOS}/sources/${gccdir}" ]]; then
  logging_message "gcc sources were already extracted"
else
  logging_message "extracting gcc sources"
  tar -xf "${LXOS}/sources/${gccbas}" -C "${LXOS}/sources/"
fi

# get gmp sources (GNU Multiple Precision Arithmetic Library)
gmpurl="http://ftp.gnu.org/gnu/gmp/gmp-6.2.0.tar.xz"
gmpbas=$(basename ${gmpurl})
gmpdir=$(echo ${gmpbas} | sed 's/.tar.xz//g')
if [[ -f "${LXOS}/sources/${gmpbas}" ]]; then
  logging_message "gmp was already downloaded to ${LXOS}/sources/${gmpbas}"
else
  logging_message "retrieving gmp"
  wget ${gmpurl} -P ${LXOS}/sources
fi

# extract gmp sources
if [[ -d "${LXOS}/sources/${gmpdir}" ]]; then
  logging_message "gmp sources were already extracted"
else
  logging_message "extracting gmp sources"
  tar -xf "${LXOS}/sources/${gmpbas}" -C "${LXOS}/sources/"
fi

# get mpfr sources (Multi Precision Floating Point with Rounding for C)
mpfrurl="https://www.mpfr.org/mpfr-4.0.2/mpfr-4.0.2.tar.xz"
mpfrbas=$(basename ${mpfrurl})
mpfrdir=$(echo ${mpfrbas} | sed 's/.tar.xz//g')
if [[ -f "${LXOS}/sources/${mpfrbas}" ]]; then
  logging_message "mpfr was already downloaded to ${LXOS}/sources/${mpfrbas}"
else
  logging_message "retrieving mpfr"
  wget ${mpfrurl} -P ${LXOS}/sources
fi

# extract mpfr sources
if [[ -d "${LXOS}/sources/${mpfrdir}" ]]; then
  logging_message "mpfr sources were already extracted"
else
  logging_message "extracting mpfr sources"
  tar -xf "${LXOS}/sources/${mpfrbas}" -C "${LXOS}/sources/"
fi

# get mpc sources (GNU MPC is a complex floating-point library )
mpcurl="https://ftp.gnu.org/gnu/mpc/mpc-1.2.0.tar.gz"
mpcbas=$(basename ${mpcurl})
mpcdir=$(echo ${mpcbas} | sed 's/.tar.gz//g')
if [[ -f "${LXOS}/sources/${mpcbas}" ]]; then
  logging_message "mpc was already downloaded to ${LXOS}/sources/${mpcbas}"
else
  logging_message "retrieving mpc"
  wget ${mpcurl} -P ${LXOS}/sources
fi

# extract mpc sources
if [[ -d "${LXOS}/sources/${mpcdir}" ]]; then
  logging_message "mpc sources were already extracted"
else
  logging_message "extracting mpc sources"
  tar -xzf "${LXOS}/sources/${mpcbas}" -C "${LXOS}/sources/"
fi

# move helper packages gmp, mpfr and mpc into gcc directory
cp -r "${LXOS}/sources/${gmpdir}" "${LXOS}/sources/${gccdir}/gmp/"
cp -r "${LXOS}/sources/${mpfrdir}" "${LXOS}/sources/${gccdir}/mpfr/"
cp -r "${LXOS}/sources/${mpcdir}" "${LXOS}/sources/${gccdir}/mpc/"

# create statically compiled gcc
mkdir -pv "${LXOS}/sources/gcc-static/"
pushd "${LXOS}/sources/gcc-static/"
AR=ar LDFLAGS="-Wl,-rpath,${LXOS}/cross-tools/lib" ../${gccdir}/configure \
--prefix=${LXOS}/cross-tools --build=${LXOS_HOST} --host=${LXOS_HOST} \
--target=${LXOS_TARGET} --with-sysroot=${LXOS}/target --disable-nls \
--disable-shared --with-mpfr-include=$(pwd)/../${gccdir}/mpfr/src \
--with-mpfr-lib=$(pwd)/mpfr/src/.libs --without-headers --with-newlib \
--disable-decimal-float --disable-libgomp --disable-libmudflap --disable-libssp \
--disable-threads --enable-languages=c,c++ --disable-multilib --with-arch=${LXOS_CPU}
make all-gcc all-target-libgcc && make install-gcc install-target-libgcc
ln -vs libgcc.a "${LXOS_TARGET}-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'"
popd

# prepare glic
glicurl="https://ftp.gnu.org/gnu/glibc/glibc-2.32.tar.xz"
glibcbas=$(basename ${glibcurl})
glibcdir=$(echo ${glibcbas} | sed 's/.tar.xz//g')
if [[ -f "${LXOS}/sources/${glibcbas}" ]]; then
  logging_message "glibc was already downloaded to ${LXOS}/sources/${glibcbas}"
else
  logging_message "retrieving glibc"
  wget ${glibcurl} -P ${LXOS}/sources
fi

# extract glibc sources
if [[ -d "${LXOS}/sources/${glibcdir}" ]]; then
  logging_message "glibc sources were already extracted"
else
  logging_message "extracting glibc sources"
  tar -xf "${LXOS}/sources/${glibcbas}" -C "${LXOS}/sources/"
fi

# configure and build glibc
mkdir -pv "${LXOS}/sources/glibc-build/"
pushd "${LXOS}/sources/glibc-build/"
cat << "EOF" > config.cache
libc_cv_forced_unwind=yes
libc_cv_c_cleanup=yes
libc_cv_ssp=no
libc_cv_ssp_strong=no
EOF
BUILD_CC="gcc" CC="${LXOS_TARGET}-gcc" \
AR="${LXOS_TARGET}-ar" \
RANLIB="${LXOS_TARGET}-ranlib" CFLAGS="-O2" ../${glibcdir}/configure --prefix=/usr \
--host=${LXOS_TARGET} --build=${LXOS_HOST} --disable-profile --enable-add-ons --with-tls \
--enable-kernel=2.6.32 --with-__thread --with-binutils=${LXOS}/cross-tools/bin
--with-headers=${LXOS}/usr/include --cache-file=config.cache
make && make install_root=${LXOS}/ install

#-----------------------------------------------------------------------------#
# Building the Target Image

section_message "Building the Target Image"

#-----------------------------------------------------------------------------#

# get final timestamp
finishts=$(date)

# show timing
echo -e "\n started: ${startts}"
echo -e "finished: ${finishts}\n"

#-----------------------------------------------------------------------------#
