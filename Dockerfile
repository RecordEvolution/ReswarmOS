
FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

# build environment including packages required by buildroot
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git make python3 \
    build-essential gcc g++ autoconf automake libtool bison flex gettext \
    wget cpio unzip rsync bc

# clone buildroot repository (at certain commit)
#RUN git clone https://github.com/buildroot/buildroot --single-branch --depth=1 /home/buildroot

# copy build scripts
COPY ./build-it.sh /home/build-it.sh
COPY ./logging.sh /home/logging.sh
RUN chmod 755 /home/build-it.sh
RUN chmod 755 /home/logging.sh

# copy configuration
COPY distro-config.yaml /home/distro-config.yaml
COPY configs /home/configs

# start in /home directory
WORKDIR /home

# initialize the build process
CMD ["./build-it.sh"]

