
auth:
	cat ~/.git-credentials  | grep github > gitcreds

setup-docker: Dockerfile
	docker build . --tag=reagent-nvidia-builder

setup-build:
	mkdir -pv build/
	git clone https://github.com/RecordEvolution/DeviceManagementAgent.git --single-branch --depth=1 build/
	cp build-agent.sh build/src/

run:
	docker run -it --rm --volume $(shell pwd)/build/:/home/reagent reagent-nvidia-builder /bin/bash

