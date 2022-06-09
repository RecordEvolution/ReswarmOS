#!/bin/bash

set -e

rootfs_ext4=$(realpath $1)
type="image"
cert_path="certs/cert.pem"
key_path="certs/key.pem"
mkdir -p certs
mkdir -p bundles
os=$(uname -s)
version=$(cat ../setup.yaml | grep "^  version:" | awk -F ':' '{print $2}' | tr -d ' ')
model=$(cat ../setup.yaml | grep "^  model:" | awk -F ':' '{print $2}' | tr -d ' ')
bundle_name="ReswarmOS-$type-$version-$model.raucb"

if [[ ! -f "$cert_path" ]]; then
    gsutil cp gs://reswarmos-certs/cert.pem certs/cert.pem
fi

if [[ ! -f "$key_path" ]]; then
    gsutil cp gs://reswarmos-certs/key.pem certs/key.pem
fi

if [[ "$os" == "Darwin" ]]; then
    gsed -E -i "s/ReswarmOS-image-.*/ReswarmOS-image-$model/g" manifest.raucm
    gsed -E -i "s/version=.*/version=$version/g" manifest.raucm
else
    sed -E -i "s/ReswarmOS-image-.*/ReswarmOS-image-$model/g" manifest.raucm
    sed -E -i "s/version=.*/version=$version/g" manifest.raucm
fi

echo $bundle_name > name.txt
cp $rootfs_ext4 rootfs.ext4

echo "Starting bundling process for: $bundle_name"

docker build -t bundle_creator .
docker create --name bundle_creator_copy bundle_creator
docker cp bundle_creator_copy:/app/$bundle_name ${HOME}/git/ReswarmOS/update/bundles
docker rm bundle_creator_copy
