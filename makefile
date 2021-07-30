#-----------------------------------------------------------------------------#

OUT = output-build/
CDR = $(shell pwd)
IMG = $(shell ls -t $(OUT)*.img | head -n1)
NAM = $(shell basename $(IMG))
NAS = $(shell echo $(NAM) | sed 's/.img//g')
BRD = $(shell cat setup.yaml | grep "board:" | sed 's/board://g' | tr -d '\n ')
TNM = reswarmos-builder:latest
CNM = reswarmos-builder
VLP = /home/buildroot/reswarmos-build

#-----------------------------------------------------------------------------#
# prepare container image for building

setup: Dockerfile $(OUT)
	./reswarmify/os-release.sh > rootfs/etc/os-release
	docker build ./ --tag=$(TNM)
	rm -vf $(OUT)buildroot/output/target/etc/os-release

$(OUT):
	mkdir -pv $(OUT)
	chmod -R 777 $(OUT)

#-----------------------------------------------------------------------------#
# manage build process

build:
	docker run -it --rm --name $(CNM) --volume $(CDR)/$(OUT):$(VLP) $(TNM)

build-daemon:
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
# deploy image and meta-data

image-meta:
	gsutil cp gs://reswarmos/supportedImages.json config/supportedBoards.json
	python3 config/supported-boards.py setup.yaml config/supportedBoards.json

gcloud-upload: $(OUT)$(NAM).gz image-meta
	@echo uploading image archive $<
	#gsutil cp $< gs://reswarmos/$(BRD)/
	gsutil ls gs://reswarmos/$(BRD)/
	gsutil cp config/supportedBoards.json gs://reswarmos/supportedImages.json
	gsutil ls gs://reswarmos/

#-----------------------------------------------------------------------------#

prepare-gcloud:
	cp $(IMG) ./disk.raw
	tar --format=oldgnu -Sczf $(NAS)-gcloud.tar.gz disk.raw
	rm ./disk.raw
	mv $(NAS)-gcloud.tar.gz $(OUT)

#-----------------------------------------------------------------------------#
# clean up and remove build output and container image

clean-output:
	rm -r $(OUT)

clean-docker:
	docker image rm $(TNM)

#-----------------------------------------------------------------------------#
# manage update system

update-server-build:
	docker build update/ --tag=osupdater:0.1

update-server-run:
	docker run -it --rm osupdater:0.1 /bin/bash

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
