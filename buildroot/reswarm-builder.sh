#!/bin/bash

CDR=$(pwd)
MDL=$(cat setup.yaml | grep "model:" | sed 's/model://g' | tr -d '\n ')
OUT="builds/$MDL"


mkdir -pv $OUT
chmod -R 777 $OUT

# Generate keys

openssl req -new -x509 -newkey rsa:4096 -nodes \
-keyout "$OUT/key.pem" -out "$OUT/cert.pem" -days 365 \
-subj "/C=DE/ST=Hesse/L=Frankfurt am Main/O=RecordEvolutionGmbH/CN=www.record-evolution.com"
chmod +rx "$OUT/key.pem" "$OUT/cert.pem"
openssl x509 -in "$OUT/cert.pem" -dates -noout
openssl x509 -noout -modulus -in "$OUT/cert.pem" | openssl md5
openssl rsa -noout -modulus -in "$OUT/key.pem" | openssl md5

cp -v $OUT/cert.pem rootfs/etc/rauc/cert.pem

./os-release.sh > rootfs/etc/os-release
cp -v setup.yaml rootfs/etc/setup.yaml
docker build ./ --tag=reswarmos-builder:latest
rm -vf $OUT/buildroot/output/target/etc/os-release

# docker run -it --rm --name $(CNM) --volume $(CDR)/$(OUT):$(VLP) $(TNM)
docker run -it --rm --name reswarmos-builder --volume $CDR/$OUT:/home/buildroot/reswarmos-build reswarmos-builder:latest