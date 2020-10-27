
FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git make \
    build-essential gcc g++ autoconf automake libtool bison flex gettext \
    wget cpio unzip rsync bc

RUN git clone https://github.com/buildroot/buildroot --single-branch --depth=1 /home/buildroot

COPY ./build-it.sh /home/build-it.sh
COPY ./logging.sh /home/logging.sh
RUN chmod 755 /home/build-it.sh
RUN chmod 755 /home/logging.sh
COPY distro-config.yaml /home/distro-config.yaml
COPY configs /home/configs

WORKDIR /home

CMD ["./build-it.sh"]


