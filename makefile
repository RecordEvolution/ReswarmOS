#-----------------------------------------------------------------------------#

OUT = output-build/
CDR = $(shell pwd)
IMG = $(OUT)$(shell ls -t $(OUT) | grep '.img')
NAM = $(shell basename $(IMG))
NAS = $(shell echo $(NAM) | sed 's/.img//g')
BRD = $(shell cat setup.yaml | grep "board:" | sed 's/board://g' | tr -d '\n ')
MDL = $(shell cat setup.yaml | grep "model:" | sed 's/model://g' | tr -d '\n ')
VSN = $(shell cat setup.yaml | grep "version:" | sed 's/version://g' | tr -d '\n ')
TNM = reswarmos-builder:latest
CNM = reswarmos-builder
VLP = /home/buildroot/reswarmos-build

#-----------------------------------------------------------------------------#
# container image hosting build process

setup: Dockerfile $(OUT) $(OUT)key.pem $(OUT)cert.pem
	./reswarmify/os-release.sh > rootfs/etc/os-release
	cp -v setup.yaml rootfs/etc/setup.yaml
	docker build ./ --tag=$(TNM)
	rm -vf $(OUT)buildroot/output/target/etc/os-release
	# add certificate for verification of RAUC bundle
	cp -v $(word 4,$^) rootfs/etc/rauc/cert.pem

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

#-----------------------------------------------------------------------------#
# deploy ReswarmOS image/update and meta-data

release: $(OUT)$(NAM).gz $(OUT)ReswarmOS-$(VSN)-$(MDL).raucb
	gsutil cp gs://reswarmos/supportedImages.json config/supportedBoards.json
	python3 config/supported-boards.py setup.yaml config/supportedBoards.json
	gsutil cp $< gs://reswarmos/$(BRD)/
	gsutil cp $(word 2,$^) gs://reswarmos/$(BRD)/
	gsutil ls -lh gs://reswarmos/$(BRD)/
	gsutil cp config/supportedBoards.json gs://reswarmos/supportedImages.json
	gsutil ls -lh gs://reswarmos/

#-----------------------------------------------------------------------------#

prepare-gcloud:
	cp $(IMG) ./disk.raw
	tar --format=oldgnu -Sczf $(NAS)-gcloud.tar.gz disk.raw
	rm ./disk.raw
	mv $(NAS)-gcloud.tar.gz $(OUT)

#-----------------------------------------------------------------------------#
# clean up and remove build output and container image

clean: clean-output clean-docker clean-rauc

clean-output:
	rm -rf $(OUT)buildroot/

clean-docker:
	docker image rm $(TNM)

#-----------------------------------------------------------------------------#
# manage update system
#
# RAUC:
# - https://rauc.readthedocs.io/en/v1.5.1/advanced.html#single-key
# - https://rauc.readthedocs.io/en/latest/examples.html#pki-setup

$(OUT)key.pem $(OUT)cert.pem:
	openssl req -new -x509 -newkey rsa:4096 -nodes \
	-keyout $(OUT)/key.pem -out $(OUT)/cert.pem \
	-subj "/C=DE/ST=Hesse/L=Frankfurt am Main/O=RecordEvolutionGmbH/CN=www.record-evolution.com"

# add certificate to rootfs for verification of RAUC bundle
rootfs/etc/cert.pem: $(OUT)cert.pem
	cp -v $< $@

$(OUT)rauc-bundle/:
	mkdir -pv $@

$(OUT)rauc-bundle/manifest.raucm: update/manifest.raucm
	#upvertag = $(shell cat rootfs/etc/os-release | grep ^VERSION= | awk -F '=' '{print $2}')
	#upbldtag = $(shell cat rootfs/etc/os-release | grep ^VERSION_ID= | awk -F '=' '{print $2}')
	#cat $< | grep -v "^#" | sed "s/UPDATEVERSIONTAG/$(upvertag)/g" | sed "s/UPDATEBUILDTAG/$(upbldtag)/g" > $@
	cat $< | grep -v "^#" > $@

$(OUT)rauc-bundle/rootfs.ext4:
	cp -v $(OUT)buildroot/output/images/rootfs.ext2 $@
	#e2label $@ rootfsB

$(OUT)ReswarmOS-$(VSN)-$(MDL).raucb: $(OUT)rauc-bundle/ $(OUT)rauc-bundle/rootfs.ext4 $(OUT)cert.pem $(OUT)key.pem $(OUT)rauc-bundle/manifest.raucm
	rm -vf $@
	rauc bundle --cert=$(word 3,$^) --key=$(word 4,$^) $< $@
	rauc info --no-verify $@

clean-rauc:
	#rm -vf $(OUT)cert.pem $(OUT)key.pem
	rm -vf $(OUT)ReswarmOS-update-bundle.raucb
	rm -rvf $(OUT)rauc-bundle
	rm -vf rootfs/etc/rauc/cert.pem

#-----------------------------------------------------------------------------#
# analyse objects contributing to final root filesystem size

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
