
FROM ubuntu:20.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  ostree ostree-boot rauc rauc-service squashfs-tools

WORKDIR /app

COPY bundler.sh .

COPY certs/* .

COPY manifest.raucm .

COPY rootfs.ext4 .

COPY name.txt .

RUN /app/bundler.sh