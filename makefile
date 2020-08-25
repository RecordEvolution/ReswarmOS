
# main target to build OS-image
image : $(RESWARMOS) image-generate

# make build directory
$(RESWARMOS) :
	mkdir -pv $@

image-generate: image/prepare_image.sh boot-generate root-generate
	sudo ./$<

image/prepare_image.sh: image/prepare_image.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

boot-generate: boot/build_boot.sh
	sudo ./$<

boot/build_boot.sh : boot/prepare_bootconfig.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

root-generate: root/prepare_root.sh
	sudo ./$<

root/prepare_root.sh: root/prepare_root.py distro-config.yaml root/root_filesystem.yaml
	python3 $< --shellScript $@
	chmod u+x $@

cross-generate: cross/prepare_cross.sh
	sudo ./$<

cross/prepare_cross.sh: cross/prepare_cross.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

clean :
	rm -f image/prepare_image.sh
	rm -f boot/build_boot.sh
	rm -f root/prepare_root.sh
	rm -f cross/prepare_cross.sh

clean-build :
	sudo rm -r $(RESWARMOS)
