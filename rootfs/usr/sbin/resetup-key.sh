#!/bin/sh

reswarmFile="$1"

if [ -z "${reswarmFile}" ]; then
  echo "missing reswarm file argument" >&2
  exit 1
fi
if [ ! -f "${reswarmFile}" ]; then
  echo "provided reswarm file does not exist" >&2
  exit 1
fi

# extract private key from reswarm file
echo -e $(cat ${reswarmFile}  | jq ' .authentication.key' | tr -d '"') > /root/key.pem

# generate corresponding public key
chmod 600 /root/key.pem
ssh-keygen -y -f /root/key.pem > /root/id.pub

