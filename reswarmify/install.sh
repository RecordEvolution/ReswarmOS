#!/bin/bash
#
# IronFlock device bootstrap — downloads the ironflock-init binary for this
# machine's CPU architecture into the current directory and verifies it.
#
#   curl -sSL https://instance-registry.ironflock.com/dl/reswarmify/install.sh | bash
#
# IRONFLOCK_DL_BASE
#   Download base to fetch from. Default: the IronFlock cloud,
#   https://instance-registry.ironflock.com/dl. An IronFlock appliance mirrors
#   the same layout for devices without internet access — point this at its
#   device-facing base (plain mode http://<appliance-host>:15002/dl, domain
#   mode https://registry.<appliance-domain>/dl):
#
#     curl -sSL http://<appliance-host>:15002/dl/reswarmify/install.sh \
#       | IRONFLOCK_DL_BASE=http://<appliance-host>:15002/dl bash
#
#   A trailing slash is ignored. Expected below the base:
#     reswarmify/version.txt
#     reswarmify/linux/<arch>/<version>/ironflock-init   (+ .sha256 sidecar)
#   The sidecar's first whitespace-separated token is the hex SHA-256 of the
#   binary; the download is verified against it whenever it exists. Older
#   cloud releases have none, which is reported as a warning.
#
# Requires wget or curl; sha256sum (coreutils) or shasum for verification.

set -e

BASE="${IRONFLOCK_DL_BASE:-https://instance-registry.ironflock.com/dl}"
BASE="${BASE%/}"

uname_result=$(uname -m)

architecture=""

case $uname_result in
    x86_64)
        architecture="amd64"
        ;;
    arm)
        architecture="armv5"
        ;;
    arm64)
        architecture="arm64"
        ;;
    armv6l)
        architecture="armv6"
        ;;
    armv7l)
        architecture="armv7"
        ;;
    aarch64)
        architecture="arm64"
        ;;
    aarch64_be)
        architecture="arm64"
        ;;
    armv8b)
        architecture="arm64"
        ;;
    armv8l)
        architecture="arm64"
        ;;
    *)
        # Default case if architecture doesn't match any of the above
        echo "Unsupported architecture: $uname_result"
        exit 1
        ;;
esac

# fetch_file URL DEST — download URL to DEST, failing on any non-2xx response
# (wget exits 8, curl -f exits 22 on an HTTP error) so an error page never
# lands on disk under the binary's name.
fetch_file() {
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$2" "$1"
    elif command -v curl >/dev/null 2>&1; then
        curl -fSL --progress-bar -o "$2" "$1"
    else
        echo "Neither wget nor curl is available" >&2
        return 1
    fi
}

# fetch_text URL — print the body of URL; same failure semantics as fetch_file.
fetch_text() {
    if command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1"
    else
        echo "Neither wget nor curl is available" >&2
        return 1
    fi
}

# fetch_code URL DEST — download URL to DEST and print the HTTP status code
# ("000" when the server could not be reached at all). Unlike fetch_file this
# never fails on an HTTP error, so the caller can tell a 404 ("not published")
# from a 5xx ("mirror or proxy broken").
fetch_code() {
    if command -v curl >/dev/null 2>&1; then
        curl -sSL -o "$2" -w '%{http_code}' "$1" 2>/dev/null || printf '000'
    elif command -v wget >/dev/null 2>&1; then
        local hdr code
        hdr=$(mktemp)
        wget -q --server-response -O "$2" "$1" 2>"$hdr" || true
        # The last status line wins (redirects print one per hop).
        code=$(awk '/^ *HTTP\/[0-9.]+ [0-9]{3}/ { c=$2 } END { print c }' "$hdr")
        rm -f "$hdr"
        printf '%s' "${code:-000}"
    else
        echo "Neither wget nor curl is available" >&2
        printf '000'
    fi
}

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        return 1
    fi
}

echo -e "Downloading IronFlock initialization binary... ($architecture)\n"
echo "Download base: $BASE"

if ! latest_version=$(fetch_text "${BASE}/reswarmify/version.txt"); then
    echo "Failed to fetch ${BASE}/reswarmify/version.txt" >&2
    exit 1
fi
latest_version=$(printf '%s' "$latest_version" | tr -d '[:space:]')
if [ -z "$latest_version" ]; then
    echo "Empty version.txt at ${BASE}/reswarmify/version.txt" >&2
    exit 1
fi
echo "Version: $latest_version"
echo

ironflock_init_download_url="${BASE}/reswarmify/linux/${architecture}/${latest_version}/ironflock-init"

if ! fetch_file "$ironflock_init_download_url" ironflock-init; then
    rm -f ironflock-init
    echo "Failed to download $ironflock_init_download_url" >&2
    exit 1
fi

echo

# Verify against the .sha256 sidecar whenever the mirror publishes one. Only
# a 404 means "not published" (older cloud releases); any other failure — a
# 5xx from the cloud proxy, the appliance mirror's 502 while its uplink is
# down, a dead connection — aborts rather than silently skipping the check.
sidecar_url="${ironflock_init_download_url}.sha256"
sidecar_file=$(mktemp)
code=$(fetch_code "$sidecar_url" "$sidecar_file")
if [ "$code" = "404" ]; then
    rm -f "$sidecar_file"
    echo "Warning: no checksum published at $sidecar_url — download not verified" >&2
elif [ "$code" != "200" ]; then
    rm -f "$sidecar_file" ironflock-init
    echo "Failed to fetch $sidecar_url (HTTP $code)" >&2
    exit 1
else
    sidecar=$(cat "$sidecar_file")
    rm -f "$sidecar_file"
    expected=$(printf '%s\n' "$sidecar" | awk 'NF { print tolower($1); exit }')
    case "$expected" in
        "" | *[!0-9a-f]*)
            rm -f ironflock-init
            echo "Malformed checksum at $sidecar_url: '$expected'" >&2
            exit 1
            ;;
    esac
    if [ "${#expected}" -ne 64 ]; then
        rm -f ironflock-init
        echo "Malformed checksum at $sidecar_url: '$expected'" >&2
        exit 1
    fi
    if ! actual=$(sha256_of ironflock-init); then
        echo "Warning: neither sha256sum nor shasum available — download not verified" >&2
    elif [ "$actual" != "$expected" ]; then
        rm -f ironflock-init
        echo "Checksum mismatch for ironflock-init: expected $expected, got $actual" >&2
        exit 1
    else
        echo "Checksum verified."
    fi
fi

chmod +x ironflock-init

binaryPath=$(realpath .)
echo "Download complete!"
echo

echo "To initialize your device use the following example command:"
echo "$binaryPath/ironflock-init -c /path/to/device-config.flock"
echo

if [ -n "${IRONFLOCK_DL_BASE:-}" ]; then
    echo "ironflock-init downloads from the base recorded in the .flock (update_url) automatically;"
    echo "to override it, pass --download-base $BASE"
    echo
fi

echo "For other usage and more information, run the following help command:"
echo "$binaryPath/ironflock-init -h"
