#!/bin/bash

array=($(ls build))
VERSION=`cat cli/release/version.txt`

for element in "${array[@]}"; do
    OS=$(echo "$element" | cut -d "-" -f 2)
    ARCH=$(echo "$element" | cut -d "-" -f 3)
    BINARY_NAME="reswarmify-cli"

    GCLOUD="gs://reswarmos/reswarmify/${OS}/${ARCH}/${VERSION}/${BINARY_NAME}"
    gsutil cp "build/$element" $GCLOUD
done

gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/reswarmify