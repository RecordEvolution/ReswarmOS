
OUT = output-build/
CDR = $(shell pwd)
IMG = $(shell ls $(OUT)*.img | head -n1)
NAM = $(shell basename $(IMG))
TNM = reswarmos-builder:latest
CNM = reswarmos-builder

setup: Dockerfile $(OUT)
	docker build ./ --tag=$(TNM)

$(OUT):
	mkdir -pv $(OUT)

build:
	docker run -it --rm --name $(CNM) --volume $(CDR)/$(OUT):/home/reswarmos-build $(TNM)

build-daemon:
	docker run -it -d --name $(CNM) --volume $(CDR)/$(OUT):/home/reswarmos-build $(TNM)

build-logs:
	docker logs $(CNM)

compress-zip:
	mv $(IMG) ./
	zip $(NAM).zip $(NAM)
	mv $(NAM) $(OUT)
	mv $(NAM).zip $(OUT)

compress-xz:
	mv $(IMG) ./
	tar --xz -cf $(NAM).xz $(NAM) --checkpoint=5000
	mv $(NAM) $(OUT)
	mv $(NAM).xz $(OUT)

uncompress-xz:
	tar -xJf $(OUT)$(NAM).xz

clean-output:
	rm -r $(OUT)

clean-docker:
	docker image rm $(TNM)

