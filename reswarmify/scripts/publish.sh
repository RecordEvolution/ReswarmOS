#!/bin/bash

set -e

array=($(ls build))
VERSION=`cat cli/release/version.txt`

# Portable SHA-256 (CI has sha256sum, macOS has shasum) — same helper as
# DeviceManagementAgent/scripts/publish.sh.
sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

for element in "${array[@]}"; do
    case "$element" in *.sha256) continue ;; esac

    OS=$(echo "$element" | cut -d "-" -f 2)
    ARCH=$(echo "$element" | cut -d "-" -f 3)
    BINARY_NAME="ironflock-init"

    GCLOUD="gs://reswarmos/reswarmify/${OS}/${ARCH}/${VERSION}/${BINARY_NAME}"
    gsutil cp "build/$element" $GCLOUD

    # SHA-256 sidecar next to each binary: install.sh verifies the download
    # against it, on the cloud and on an appliance (which mirrors this bucket
    # under <DL>/reswarmify/). Older releases have none, so clients treat a
    # missing sidecar as "unverified", never as an error.
    sha256_of "build/$element" > "build/$element.sha256"
    gsutil cp "build/$element.sha256" "${GCLOUD}.sha256"
    rm -f "build/$element.sha256"
done

gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/reswarmify
