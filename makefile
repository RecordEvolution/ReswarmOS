
OUT = output-build/
CDR = $(shell pwd)
IMG = $(shell ls $(OUT)*.img | head -n1)
NAM = $(shell basename $(IMG))

setup: Dockerfile $(OUT)
	docker build ./ --tag=reswarmos-builder:latest

$(OUT):
	mkdir -pv $(OUT)

build:
	docker run -it --rm --name reswarmos-builder --volume $(CDR)/$(OUT):/home/reswarmos-build reswarmos-builder:latest

compress:
	mv $(IMG) ./
	tar --xz -cf $(NAM).xz $(NAM) --checkpoint=5000
	mv $(NAM) $(OUT)
	mv $(NAM).xz $(OUT)

uncompress:
	tar -xJf $(OUT)$(NAM).xz

clean-output:
	rm -r $(OUT)

clean-docker:
	docker image rm reswarmos-builder:latest

