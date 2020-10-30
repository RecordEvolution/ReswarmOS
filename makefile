
OUT = output-build/
CDR = $(shell pwd)
IMG = $(shell ls $(OUT)*.img | head -n1)

setup: Dockerfile $(OUT)
	docker build ./ --tag=reswarmos-builder:latest

$(OUT):
	mkdir -pv $(OUT)

build:
	docker run -it --rm --name reswarmos-builder --volume $(CDR)/$(OUT):/home/reswarmos-build reswarmos-builder:latest
	ls -lhd $(OUT)
	ls -lh $(OUT)ReswarmOS*

compress:
	tar --xz -cf $(IMG).xz $(IMG) --checkpoint=5000
	
clean-output:
	rm -r $(OUT)

clean-docker:
	docker image rm reswarmos-builder:latest

