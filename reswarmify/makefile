release:
	rm rootfs.tar.gz || true
	tar -zcvf rootfs.tar.gz rootfs
	gsutil cp gs://reswarmos/reswarmify/rootfs.tar.gz rootfs.tar.gz
	gsutil cp gs://reswarmos/reswarmify/setup-reswarm.sh setup-reswarm.sh
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/reswarmify