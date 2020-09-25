#!/bin/bash

# --------------------------------------------------------------------------- #
#
#  @file build-gcc.sh
#  @author Mario Fink
#  @date 2020-09-24
#
# --------------------------------------------------------------------------- #

# check required tools
./prerequisites-check.sh

gcc --version
ld --version

# dependencies: Building GCC requires GMP 4.2+, MPFR 3.1.0+ and MPC 0.8.0+
echo -e "\ninstalling GMP 4.2+, MPFR 3.1.0+ and MPC 0.8.0+"
apt-get install -y libgmp-dev libmpfr-dev libmpc-dev
echo -e "\n\n"

# set directory for build and installation
#gccAll="${HOME}/Downloads/"
gccAll="/gcc-build/"

# source directory
gccsrc="${gccAll}/gcc"
if [[ ! -d ${gccsrc} ]]; then
	mkdir -pv ${gccsrc}
fi

# build directory
gccbld="${gccAll}/gcc-build"
if [[ ! -d ${gccbld} ]]; then
	mkdir -pv ${gccbld}
fi

# installation directory
gccint="${gccAll}/gcc-install"
if [[ ! -d ${gccint} ]]; then
	mkdir -pv ${gccint}
fi

ls -lh /
ls -lh ${gccAll}

# git repository URL (check list of available tags, i.e. releases)
gccgit="https://gcc.gnu.org/git/gcc.git"

# ./gcc/configure --help
#
# System types:
#  --build=BUILD     configure for building on BUILD [guessed]
#  --host=HOST       cross-compile to build programs to run on HOST [BUILD]
#  --target=TARGET   configure for building compilers for TARGET [HOST]
#
# build
bld=$(gcc -dumpmachine)
# host 
hst="aarch64-pc-linux-gnu" # "aarch64-linux-gnu"  # "aarch64-unknown-linux-gnu"
# specifc target architecture
tgt="${bld}"

echo ""
echo "machtype: $MACHTYPE"
echo "build:  ${bld}"
echo "host:   ${hst}"
echo "target: ${tgt}"
echo ""

# choose release
btag="releases/gcc-10.2.0"

# get gcc sources
if [[ ! -d ${gccdir} ]]; then
  # git clone git://gcc.gnu.org/git/gcc.git ${gccdir}
  git clone git://gcc.gnu.org/git/gcc.git ${gccsrc} -b ${btag} --depth=1 --branch=master
fi

# list branches and tags
# git branch -a
# git tag -l
#
# # choose branch and tag
# git checkout

# check git sources
pushd ${gccsrc}
git branch
git log | head -n 20
git status

# find supported languages
echo -e "\ngcc: check for supported languages:\n"
grep ^language= gcc/*/config-lang.in
#ls gcc/ -lh | grep "^d" | awk -F ' ' '{print $NF}' | while read dl; do if [[ -f gcc/$dl/config-lang.in ]]; then cat gcc/$dl/config-lang.in | grep '^language='; fi; done;
echo -e "\n"

popd

# create build directory
mkdir -pv ${gccbld}

# configure build process
# (see https://gcc.gnu.org/install/configure.html,
# for target see https://gcc.gnu.org/install/specific.html#m68k-x-x)
pushd ${gccbld}
# check configure options
# $ configure --help
# do configuration
${gccsrc}/configure \
  --with-pkgversion="ReswarmOS gcc 2020-09-25" \
  --build=${bld} \
  --host=${bld} \
  --target=${tgt} \
  --prefix=${gccint} \
  --with-local-prefix=${gccint} \
  --with-gmp \
  --with-mpfr \
  --with-mpc \
  --enable-threads \
  --enable-languages=c,c++ \
  --disable-multilib
 
# start build process with n threads
make -j2
  
# install package
make install

popd

echo -e "\nfinished gcc cross-build\n"

