#!/bin/bash

# --------------------------------------------------------------------------- #

download_and_extract()
{
  # retrieve arguments
  # ...URL to download
  urlpath="$1"
  if [[ -z "$urlpath" ]]; then
    echo "ERROR: download_and_extract: argument 1 missing" >&2
    exit 1
  fi
  # ...download directory
  urlsave="$2"
  if [[ -z "$urlsave" ]]; then
    echo "ERROR: download_and_extract: argument 2 missing" >&2
    exit 1
  fi

  # extract basename of file
  packnam=$(basename ${urlpath})

  # specify directory name
  packdir=$(echo ${packnam} | sed 's/.tar.xz//g' | sed 's/.tar.gz//g')

  # check for downloaded file
  if [[ -f ${urlsave}/${packnam} ]]; then
    echo "package '${packnam}' is already downloaded at ${urlsave}/${packnam}"
  else
    echo "downloading package '${packnam}' to ${urlsave}/${packnam}"
    wget ${urlpath} -P ${urlsave}
  fi

  # check for extracted directory
  if [[ -d ${urlsave}/${packdir} ]]; then
    echo "package '${packnam}' is already extracted to ${urlsave}/${packdir}"
  else
    echo "extracting package '${packnam}' to ${urlsave}/${packdir}"
    mkdir -pv ${urlsave}/${packdir}
    if [[ ! -z "$(echo $packnam | grep '.tar.xz')" ]]; then
      tar -xvf ${urlsave}/${packnam} -C ${urlsave}/${packdir}
    elif [[ ! -z "$(echo $packnam | grep '.tar.gz')" ]]; then
      tar -xvzf ${urlsave}/${packnam} -C ${urlsave}/${packdir}
    else
      echo "unknown extension in ${packnam}"
    fi
  fi

}

# --------------------------------------------------------------------------- #

# URL of gcc
gcc_url="http://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz"
# ...binutils
binu_url="http://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz"
# ...glib
libc_url="https://ftp.gnu.org/gnu/glibc/glibc-2.32.tar.xz"
# ...gmp
gmp_purl="http://ftp.gnu.org/gnu/gmp/gmp-6.2.0.tar.xz"
# ...mpfr
mpfr_url="https://www.mpfr.org/mpfr-current/mpfr-4.1.0.tar.xz"
# ...mpc
mpc_url="https://ftp.gnu.org/gnu/mpc/mpc-1.2.0.tar.gz"

# target, build platforms
echo $MACHTYPE

download_and_extract ${gcc_url} $HOME/Downloads
