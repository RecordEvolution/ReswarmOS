#!/bin/bash

set -e


MDL=$(cat setup.yaml | grep "model:" | sed 's/model://g' | tr -d '\n ')
OUT="builds/$MDL"
VRT=$(cat setup.yaml | grep "osvariant:" | sed 's/osvariant://g' | tr -d '\n ')
VSN=$(cat setup.yaml | grep "version:" | sed 's/version://g' | tr -d '\n ')
IMG="$OUT/$(ls -t $OUT | grep -v 'img.gz' | grep '.img' | head -n1)"
BLT=$(cat rootfs/etc/os-release | grep "^VERSION=" | sed 's/VERSION=v[^-]*-[^-]*-//g')
NAM=$(basename $IMG)

rm -vf $OUT/ReswarmOS-*.raucb
mkdir -pv $OUT/rauc-bundle/

cp -v $IMG ./
gzip $NAM
mv -v $NAM.gz $OUT

cat update/manifest.raucm | grep "." | grep -v "^#" | sed "s/^\[/\\n\[/g" \
| sed "s/^compatible=ReswarmOS/compatible=ReswarmOS-$VRT-$MDL/g" \
| sed "s/^version=/version=$VSN/g" | sed "s/^build=/build=$BLT/g" > $OUT/rauc-bundle/manifest.raucm

cp -v $OUT/buildroot/output/images/rootfs.ext2 $OUT/rauc-bundle/rootfs.ext4

rauc bundle --cert=$OUT/cert.pem --key=$OUT/key.pem $OUT/rauc-bundle/ $OUT/ReswarmOS-$VRT-$VSN-$MDL.raucb
rauc info --no-verify $OUT/ReswarmOS-$VRT-$VSN-$MDL.raucb

gsutil cp gs://reswarmos/supportedBoardsImages.json supportedBoards.json
python3 supported-boards.py --outputDir $OUT setup.yaml supportedBoards.json
gsutil cp $OUT/$NAM.gz gs://reswarmos/$BRD/
gsutil cp $OUT/ReswarmOS-$VRT-$VSN-$MDL.raucb gs://reswarmos/$BRD/
gsutil ls -lh gs://reswarmos/$BRD/
gsutil cp supportedBoards.json gs://reswarmos/supportedBoardsImages.json
gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos