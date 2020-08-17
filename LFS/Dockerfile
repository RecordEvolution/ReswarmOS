
FROM ubuntu:latest

MAINTAINER MAINTAINER Record Evolution GmbH

# run installation non-interactively
ENV DEBIAN_FRONTEND=noninteractive

# install required packages
RUN apt-get -y update && apt-get install -y \
  build-essential \
  texinfo \
  gawk \
  bison \
  python3 \
  wget

# set bash as default shell
RUN ln -sf /usr/bin/bash /bin/sh

# set build directory, posix and target architecture
ENV LFS=/mnt/lfs
ENV LC_ALL=POSIX
ENV LFS_TGT=x86_64-lfs-linux-gnu
# or use $(uname -m)-lfs-linux-gnu

# set number of workers for building process, e.g. $ make -j2
ENV MAKEFLAGS="-j 1"

# create source directory and set permission "sticky"
RUN mkdir -pv $LFS/sources
RUN chmod -v a+wt $LFS/sources

# create build directory
RUN mkdir -pv $LFS/tools

# copy (shell) scripts
COPY ./*.sh ./
RUN chmod u+x ./*.sh
COPY ./prepare/*.sh /prepare/
RUN chmod u+x ./prepare/*.sh

CMD ["./setup_and_run.sh"]
