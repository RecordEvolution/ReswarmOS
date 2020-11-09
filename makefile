
OUT = output-build/
CDR = $(shell pwd)
IMG = $(shell ls $(OUT)*.img | head -n1)
NAM = $(shell basename $(IMG))
NAS = $(shell echo $(NAM) | sed 's/.img//g')
TNM = reswarmos-builder:latest
CNM = reswarmos-builder
VLP = /home/buildroot/reswarmos-build

setup: Dockerfile $(OUT)
	docker build ./ --tag=$(TNM)

$(OUT):
	mkdir -pv $(OUT)
	chmod -R 777 $(OUT)

build:
	docker run -it --rm --name $(CNM) --volume $(CDR)/$(OUT):$(VLP) $(TNM)

build-daemon:
	docker run -it -d --name $(CNM) --volume $(CDR)/$(OUT):$(VLP) $(TNM)

build-logs:
	docker logs $(CNM)

compress-zip:
	mv $(IMG) ./
	zip $(NAM).zip $(NAM)
	mv $(NAM) $(OUT)
	mv $(NAM).zip $(OUT)

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

prepare-gcloud:
	cp $(IMG) ./disk.raw
	tar --format=oldgnu -Sczf $(NAS)-gcloud.tar.gz disk.raw
	rm ./disk.raw
	mv $(NAS)-gcloud.tar.gz $(OUT)

clean-output:
	rm -r $(OUT)

clean-docker:
	docker image rm $(TNM)

