
boot-generate: boot/build_boot.sh
	cat $<

boot/build_boot.sh : boot/prepare_bootconfig.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

image-generate: image/prepare_image.sh
	cat $<

image/prepare_image.sh: image/prepare_image.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@
