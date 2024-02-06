#!/bin/bash

array=($(ls build))
VERSION=`cat src/release/version.txt`

for element in "${array[@]}"; do
    OS=$(echo "$element" | cut -d "-" -f 2)
    ARCH=$(echo "$element" | cut -d "-" -f 3)
    BINARY_NAME="reagent"

    if [ "$OS" == "windows" ]; then
        BINARY_NAME="reagent.exe"
    fi

    GCLOUD="gs://re-agent/${OS}/${ARCH}/${VERSION}/${BINARY_NAME}"
    gsutil cp "build/$element" $GCLOUD
done

gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://re-agent