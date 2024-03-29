#-----------------------------------------------------------------------------#

SHELL = /bin/bash

OUT = output-build/
CDR = $(shell pwd)
IMG = $(OUT)$(shell ls -t $(OUT) | grep -v 'img.gz' | grep '.img' | head -n1)
NAM = $(shell basename $(IMG))
NAS = $(shell echo $(NAM) | sed 's/.img//g')
BRD = $(shell cat setup.yaml | grep "board:" | sed 's/board://g' | tr -d '\n ')
MDL = $(shell cat setup.yaml | grep "model:" | sed 's/model://g' | tr -d '\n ')
VRT = $(shell cat setup.yaml | grep "osvariant:" | sed 's/osvariant://g' | tr -d '\n ')
VSN = $(shell cat setup.yaml | grep "version:" | sed 's/version://g' | tr -d '\n ')
BLT = $(shell cat rootfs/etc/os-release | grep "^VERSION=" | sed 's/VERSION=v[^-]*-[^-]*-//g')
TNM = reswarmos-builder:latest
CNM = reswarmos-builder
VLP = /home/buildroot/reswarmos-build

#-----------------------------------------------------------------------------#
# container image hosting build process

setup: Dockerfile $(OUT) $(OUT)key.pem $(OUT)cert.pem rootfs/etc/rauc/cert.pem
	./os-release.sh > rootfs/etc/os-release
	cp -v setup.yaml rootfs/etc/setup.yaml
	docker build ./ --tag=$(TNM)
	rm -vf $(OUT)buildroot/output/target/etc/os-release

$(OUT):
	mkdir -pv $(OUT)
	chmod -R 777 $(OUT)

#-----------------------------------------------------------------------------#
# manage build process

build: rootfs/etc/rauc/cert.pem
	docker run -it --rm --name $(CNM) --volume $(CDR)/$(OUT):$(VLP) $(TNM)

build-daemon: rootfs/etc/rauc/cert.pem
	docker run -it -d --name $(CNM) --volume $(CDR)/$(OUT):$(VLP) $(TNM)

build-logs:
	docker logs $(CNM)

#-----------------------------------------------------------------------------#
# compress final OS image

compress-zip:
	mv $(IMG) ./
	zip $(NAM).zip $(NAM)
	mv $(NAM) $(OUT)
	mv $(NAM).zip $(OUT)

compress-gzip:
	cp -v $(IMG) ./
	gzip $(NAM)
	mv -v $(NAM).gz $(OUT)
	@echo $(CDR)/$(OUT)$(NAM).gz

compress-targz:
	mv $(IMG) ./
	tar --create --gzip --format=oldgnu --file=$(NAM).tar.gz $(NAM)
	mv $(NAM) $(OUT)
	mv $(NAM).tar.gz $(OUT)

compress-xz:
	mv $(IMG) ./
	tar --xz -cf $(NAM).xz $(NAM) --checkpoint=5000
	mv $(NAM) $(OUT)
	mv $(NAM).xz $(OUT)

uncompress-xz:
	tar -xJf $(OUT)$(NAM).xz

$(OUT)$(NAM).gz: $(OUT)$(NAM)
	cp -v $(IMG) ./
	gzip $(NAM)
	mv -v $(NAM).gz $(OUT)
	@echo $(CDR)/$(OUT)$(NAM).gz

#-----------------------------------------------------------------------------#
# deploy ReswarmOS image/update and meta-data/release-file

release: $(OUT)$(NAM).gz $(OUT)ReswarmOS-$(VRT)-$(VSN)-$(MDL).raucb
	gsutil cp gs://reswarmos/supportedBoardsImages.json supportedBoards.json
	python3 supported-boards.py setup.yaml supportedBoards.json
	gsutil cp $< gs://reswarmos/$(BRD)/
	gsutil cp $(word 2,$^) gs://reswarmos/$(BRD)/
	gsutil ls -lh gs://reswarmos/$(BRD)/
	gsutil cp supportedBoards.json gs://reswarmos/supportedBoardsImages.json
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos

#-----------------------------------------------------------------------------#

prepare-gcloud:
	cp $(IMG) ./disk.raw
	tar --format=oldgnu -Sczf $(NAS)-gcloud.tar.gz disk.raw
	rm ./disk.raw
	mv $(NAS)-gcloud.tar.gz $(OUT)

#-----------------------------------------------------------------------------#
# clean up and remove build output and container image

clean: clean-output clean-docker clean-rauc clean-analyze

clean-output:
	rm -rf $(OUT)buildroot/
	rm -vf $(OUT)$(NAM) $(OUT)$(NAM).gz $(OUT)ReswarmOS-$(VSN)-$(MDL).raucb

clean-docker:
	docker image rm --force $(TNM)

#-----------------------------------------------------------------------------#
# manage update system
#
# RAUC:
# - https://rauc.readthedocs.io/en/v1.5.1/advanced.html#single-key
# - https://rauc.readthedocs.io/en/latest/examples.html#pki-setup

$(OUT)key.pem $(OUT)cert.pem:
	openssl req -new -x509 -newkey rsa:4096 -nodes \
	-keyout $(OUT)key.pem -out $(OUT)cert.pem -days 365 \
	-subj "/C=DE/ST=Hesse/L=Frankfurt am Main/O=RecordEvolutionGmbH/CN=www.record-evolution.com"
	chmod +rx $(OUT)key.pem $(OUT)cert.pem
	# checks on PKI
	openssl x509 -in $(OUT)cert.pem -dates -noout
	#openssl x509 -in $(OUT)cert.pem -text -noout
	openssl x509 -noout -modulus -in $(OUT)cert.pem | openssl md5
	openssl rsa -noout -modulus -in $(OUT)key.pem | openssl md5
	#openssl x509 -in $(OUT)cert.pem -noout -pubkey
	#openssl rsa -in $(OUT)key.pem -pubout

# add certificate to rootfs for verification of RAUC bundle
rootfs/etc/rauc/cert.pem: $(OUT)cert.pem
	cp -v $< $@

$(OUT)rauc-bundle/:
	mkdir -pv $@

$(OUT)rauc-bundle/manifest.raucm: update/manifest.raucm rootfs/etc/os-release
	cat $< | grep "." | grep -v "^#" | sed "s/^\[/\\n\[/g" \
	       | sed "s/^compatible=ReswarmOS/compatible=ReswarmOS-$(VRT)-$(MDL)/g" \
	       | sed "s/^version=/version=$(VSN)/g" | sed "s/^build=/build=$(BLT)/g" > $@

$(OUT)rauc-bundle/rootfs.ext4: $(OUT)buildroot/output/images/rootfs.ext2
	cp -v $< $@

$(OUT)ReswarmOS-$(VRT)-$(VSN)-$(MDL).raucb: $(OUT)rauc-bundle/ $(OUT)rauc-bundle/rootfs.ext4 $(OUT)cert.pem $(OUT)key.pem $(OUT)rauc-bundle/manifest.raucm
	rm -vf $(OUT)ReswarmOS-*.raucb
	rauc bundle --cert=$(word 3,$^) --key=$(word 4,$^) $< $@
	rauc info --no-verify $@

clean-rauc:
	rm -vf $(OUT)ReswarmOS-*.raucb
	rm -rvf $(OUT)rauc-bundle
	rm -vf rootfs/etc/rauc/cert.pem

#-----------------------------------------------------------------------------#
# analyse objects/packages/directories contributing to final root filesystem

analyze-depends:
	cd $(OUT)buildroot/ && make graph-depends && cd -
	cp -v $(OUT)buildroot/output/graphs/graph-depends.pdf $(OUT)

analyze-build:
	cd $(OUT)buildroot/ && make graph-build && cd -
	cp -v $(OUT)buildroot/output/graphs/build.*.pdf $(OUT)

analyze-size:
	cd $(OUT)buildroot/ && make graph-size && cd -
	cp -v $(OUT)buildroot/output/graphs/graph-size.pdf $(OUT)
	cp -v $(OUT)buildroot/output/graphs/package-size-stats.csv $(OUT)

analyze-zip: analyze-depends analyze-build analyze-size
	zip $(OUT)analyze-build.zip $(OUT)*.pdf $(OUT)*.csv
	echo $(CDR)/$(OUT)analyze-build.zip

clean-analyze:
	rm -vf $(OUT)graph-depends.pdf
	rm -vf $(OUT)build.*.pdf
	rm -vf $(OUT)graph-size.pdf
	rm -vf $(OUT)package-size-stats.csv
	rm -vf $(OUT)analyze-build.zip

OUTCL:=$(shell echo $(OUT) | sed 's/\///g')
analyse:
	du -sh $(OUT)buildroot/output/target/* | sort -rh | head -n6 | sed 's/$(OUTCL)\/buildroot\/output\/target//g'
	# /usr
	du -sh $(OUT)buildroot/output/target/usr/* | sort -rh | head -n6 | sed 's/$(OUTCL)\/buildroot\/output\/target//g'
	du -sh $(OUT)buildroot/output/target/usr/bin/* | sort -rh | head -n12 | sed 's/$(OUTCL)\/buildroot\/output\/target//g'
	du -sh $(OUT)buildroot/output/target/usr/lib/* | sort -rh | head -n12 | sed 's/$(OUTCL)\/buildroot\/output\/target//g'
	du -sh $(OUT)buildroot/output/target/usr/share/* | sort -rh | head -n12 | sed 's/$(OUTCL)\/buildroot\/output\/target//g'
	# /lib
	du -sh $(OUT)buildroot/output/target/lib/* | sort -rh | head -n6 | sed 's/$(OUTCL)\/buildroot\/output\/target//g'
	du -sh $(OUT)buildroot/output/target/lib/modules/* | sort -rh | head -n6 | sed 's/$(OUTCL)\/buildroot\/output\/target//g'

#-----------------------------------------------------------------------------#
