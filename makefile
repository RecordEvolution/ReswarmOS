
OUT = output-build/
CDR = $(shell pwd)

setup: Dockerfile $(OUT)
	docker build ./ --tag=reswarmos-builder:latest

$(OUT):
	mkdir -pv $(OUT)

build:
	#docker run -it --rm --name reswarmos-builder reswarmos-builder:latest
	docker run -it --rm --name reswarmos-builder --volume $(CDR)/$(OUT):/home/reswarmos-build reswarmos-builder:latest

clean-output:
	rm -r $(OUT)

clean-docker:
	docker image rm reswarmos-builder:latest

