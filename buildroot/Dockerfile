#-----------------------------------------------------------------------------#
# Dockerfile

FROM ubuntu:22.04

# set up non-root user
RUN groupadd buildroot && \
    useradd --create-home -g buildroot buildroot

# build environment including packages required by buildroot
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && apt-get upgrade -y && apt-get install -y \
    git make python3 python3-yaml python3-pip \
    build-essential gcc g++ autoconf automake libtool bison flex gettext \
    wget cpio unzip rsync bc iproute2 \
    rauc u-boot-tools dosfstools mtools \
    genext2fs \
    xsltproc \
    jq

# add pip packages
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
chmod +x /usr/bin/yq

# clone buildroot repository (at certain commit)
#RUN git clone https://github.com/buildroot/buildroot --single-branch --depth=1 /home/buildroot

#-----------------------------------------------------------------------------#

# adjust working directory
WORKDIR /home/buildroot

# copy build scripts
COPY ./build-it.sh ./
COPY ./build-agent.sh ./
COPY ./logging.sh ./
RUN chmod 755 ./*.sh

# copy configuration, rootfs overlay and boot directory
COPY setup.yaml ./setup.yaml
COPY config/ ./config
COPY packages/ ./packages
COPY rootfs/ ./rootfs/
COPY boot/ ./boot/

# create directory (make sure to match directory/path given in makefile) to 
# be mounted as volume and transfer ownership
RUN mkdir -v ./reswarmos-build
RUN chown buildroot:buildroot ./reswarmos-build

# set ownership/permissions and switch to non-root user for build process
RUN chown buildroot:buildroot -R ./
USER buildroot

# initialize the build process
CMD ["./build-it.sh"]

#-----------------------------------------------------------------------------#
