
setup: Dockerfile
	docker build . --tag=reswarmos-builder:latest

build:
	docker run -it --rm reswarmos-builder:latest

