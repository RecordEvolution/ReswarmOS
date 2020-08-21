
#OSR = /home/mario/reswarm-os
#export RSWMOS=$(OSR)

image-generate: image/prepare_image.sh
	cat $<

image/prepare_image.sh: image/prepare_image.py distro-config.yaml
	python3 $< --shellScript $@
	chmod u+x $@
