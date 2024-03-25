ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

rollout-dev-rootfs:
	tar -czvf rootfs-dev.tar.gz rootfs/
	gsutil cp "rootfs-dev.tar.gz" gs://reswarmos/reswarmify
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/reswarmify/rootfs-dev.tar.gz

rollout-rootfs:
	tar -czvf rootfs.tar.gz rootfs/
	gsutil cp "rootfs.tar.gz" gs://reswarmos/reswarmify
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/reswarmify/rootfs.tar.gz

build-all:
	scripts/build-all.sh

clean:
	docker rm -f reswarmify-builder
	rm -f build/*

build-all-docker: clean ## Builds all binaries for all targets in targets files
	docker build --platform linux/amd64 . -t reswarmify-builder
	echo ${ROOT_DIR}
	docker run --name reswarmify-builder -v ${ROOT_DIR}/build:/app/reswarmify/build reswarmify-builder

rollout: build-all-docker publish publish-version publish-latestVersions ## Do everything in one step

publish-all: publish publish-version publish-latestVersions ## publish the metadata and binaries from the build folder

publish:
	scripts/publish.sh

publish-version:
	gsutil cp "cli/release/version.txt" gs://reswarmos/reswarmify
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/reswarmify/version.txt

publish-latestVersions:
	gsutil cp "availableVersions.json" gs://reswarmos/reswarmify
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/reswarmify/availableVersions.json