
# main target to build OS-image
image : $(RESWARMOS) image-generate

# make build directory
$(RESWARMOS) :
	mkdir -pv $@

image-generate: image/prepare_image.sh boot-generate
	sudo ./$<

image/prepare_image.sh: image/prepare_image.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

boot-generate: boot/build_boot.sh
	sudo ./$<

boot/build_boot.sh : boot/prepare_bootconfig.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@

clean :
	rm -f image/prepare_image.sh
	rm -f boot/build_boot.sh

clean-build :
	sudo rm -r $(RESWARMOS)
