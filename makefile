
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

root-generate: root/prepare_rootfilesystem.sh
	sudo ./$<

root/prepare_rootfilesystem.sh: root/prepare_rootfilesystem.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

cross-generate: cross/prepare_crosscompiler.sh
	sudo ./$<

cross/prepare_crosscompiler.sh: cross/prepare_crosscompiler.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

clean :
	rm -f image/prepare_image.sh
	rm -f boot/build_boot.sh
	rm -f root/prepare_rootfilesystem.sh
	rm -f cross/prepare_crosscompiler.sh

clean-build :
	sudo rm -r $(RESWARMOS)
