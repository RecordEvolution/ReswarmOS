build-agent-amd64:
	echo "linux/amd64" > ${HOME}/git/DeviceManagementAgent/targets
	make -C ${HOME}/git/DeviceManagementAgent build-all-docker
	cp ${HOME}/git/DeviceManagementAgent/build/reagent-amd64-linux project/rootfs-overlay/opt/reagent/reagent-latest
	chmod +x project/rootfs-overlay/opt/reagent/reagent-latest

build-agent-arm64:
	echo "linux/arm644" > ${HOME}/git/DeviceManagementAgent/targets
	make -C ${HOME}/git/DeviceManagementAgent build-all-docker
	cp ${HOME}/git/DeviceManagementAgent/build/reagent-arm644-linux project/rootfs-overlay/opt/reagent/reagent-latest
	chmod +x project/rootfs-overlay/opt/reagent/reagent-latest

setup-amd64:
	cubic project/amd64

setup-boot-amd64:
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/boot/grub/grub.cfg ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/boot/grub/grub.cfg
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/boot/grub/loopback.cfg ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/boot/grub/loopback.cfg
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/boot/isolinux/txt.cfg ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/isolinux/txt.cfg

setup-bios-amd64:
	mkdir -p ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/preseed/nocloud
	touch ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/preseed/nocloud/meta-data
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/autoinstall/bios.yaml ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/preseed/nocloud/user-data

setup-efi-amd64:
	mkdir -p ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/preseed/nocloud
	touch ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/preseed/nocloud/meta-data
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/autoinstall/efi.yaml ${HOME}/git/ReswarmOS/cubic/project/amd64/custom-disk/preseed/nocloud/user-data

setup-arm64:
	cubic project/arm64

setup-boot-arm64:
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/boot/grub/grub.cfg ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/boot/grub/grub.cfg
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/boot/grub/loopback.cfg ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/boot/grub/loopback.cfg
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/boot/isolinux/txt.cfg ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/isolinux/txt.cfg

setup-bios-arm64:
	mkdir -p ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/preseed/nocloud
	touch ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/preseed/nocloud/meta-data
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/autoinstall/bios.yaml ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/preseed/nocloud/user-data

setup-efi-arm64:
	mkdir -p ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/preseed/nocloud
	touch ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/preseed/nocloud/meta-data
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/autoinstall/efi.yaml ${HOME}/git/ReswarmOS/cubic/project/arm64/custom-disk/preseed/nocloud/user-data

create-img:
	qemu-img create target/reswarm.img 16G

install-bios: create-img
	qemu-system-x86_64 --name "ReswarmOS" -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=target/reswarm.img -cdrom target/ReswarmOS-0.0.1-installer-amd64.iso -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

install-efi: create-img
	qemu-system-x86_64 --name "ReswarmOS" -bios /usr/share/ovmf/OVMF.fd -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=target/reswarm.img -cdrom target/ReswarmOS-0.0.1-installer-amd64.iso -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

run-efi:
	qemu-system-x86_64 --name "ReswarmOS" -bios /usr/share/ovmf/OVMF.fd -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=target/reswarm.img -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

run-bios:
	qemu-system-x86_64 --name "ReswarmOS" -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=target/reswarm.img -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

build-agent:
	cd ${HOME}/git/DeviceManagementAgent/src && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-X 'reagent/release.BuildArch=amd64'" -v -a -o ${HOME}/git/ReswarmOS/cubic/project/rootfs-overlay/opt/reagent/reagent-latest

overlay-fs-amd64:
	sudo rsync -av --mkpath --info=progress2 project/rootfs-overlay/ project/amd64/custom-root/

overlay-fs-arm64:
	sudo rsync -av --mkpath --info=progress2 project/rootfs-overlay/ project/arm64/custom-root/


archive-project:
	sudo rm archives/installerfs-v$(shell cat $(CURDIR)/versions.json | jq -r '.target').tar.gz
	sudo tar -cpvzf archives/installerfs-v$(shell cat $(CURDIR)/versions.json | jq -r '.target').tar.gz project/custom-disk/ project/custom-root/

extract-project:
	sudo tar xzf archives/installerfs-v$(shell cat $(CURDIR)/versions.json | jq -r '.target').tar.gz -C $(CURDIR)/project

download-project:
	gsutil cp gs://reswarmos/installer-source/installerfs-v$(shell cat $(CURDIR)/versions.json | jq -r '.target').tar.gz archives/

install-project: download-project extract-project

upload-project:
	gsutil cp archives/installerfs-v$(shell cat $(CURDIR)/versions.json | jq -r '.target').tar.gz gs://reswarmos/installer-source

release-source: archive-project upload-project

compress-release:
	gzip -k target/ReswarmOS-0.0.1-installer-amd64.iso

release-bios:
	gsutil cp target/ReswarmOS-0.0.1-installer-amd64.iso.gz gs://reswarmos/ipc/ReswarmOS-installer-$(shell cat $(CURDIR)/versions.json | jq -r '.target')-bios.iso.gz

release-efi:
	gsutil cp target/ReswarmOS-0.0.1-installer-amd64.iso.gz gs://reswarmos/ipc/ReswarmOS-installer-$(shell cat $(CURDIR)/versions.json | jq -r '.target')-efi.iso.gz

download-source:
	wget http://mirror.sov.uk.goscomb.net/ubuntu-releases/20.04/ubuntu-$(shell cat $(CURDIR)/versions.json | jq -r '.source')-live-server-amd64.iso -P source/

clean-project:
	sudo rm -rf project/custom-disk/ project/custom-root

clean-archives:
	rm -rf archives/*

remove-images:
	rm *.img *.iso *.md5

release:
	python3 ../config/supported-boards.py --compressionExt .iso.gz --outputDir target --osReleasePath project/rootfs-overlay/etc/config/os-release project/rootfs-overlay/etc/config/setup.yaml ../config/supportedBoards.json
	gsutil cp ../config/supportedBoards.json gs://reswarmos/supportedBoardsImages.json
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://reswarmos/supportedBoardsImages.json
