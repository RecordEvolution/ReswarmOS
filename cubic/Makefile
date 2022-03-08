setup:
	cubic project/

setup-bios:
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/autoinstall/bios.yaml ${HOME}/git/ReswarmOS/cubic/project/custom-disk/preseed/nocloud/user-data

setup-efi:
	sudo cp ${HOME}/git/ReswarmOS/cubic/config/autoinstall/efi.yaml ${HOME}/git/ReswarmOS/cubic/project/custom-disk/preseed/nocloud/user-data

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
	ARCH="amd64"
	BUILD_ARCH="amd64"
	cd ${HOME}/git/DeviceManagementAgent/src && CGO_ENABLED=1 GOOS=linux GOARCH=${ARCH} go build -ldflags "-X 'reagent/release.BuildArch=${BUILD_ARCH}'" -v -a -o ${HOME}/git/ReswarmOS/cubic/project/rootfs-overlay/opt/reagent/reagent-latest

overlay-fs:
	sudo rsync -avp project/rootfs-overlay/ project/custom-root/

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

release: archive-project upload-project

download-source:
	wget http://mirror.sov.uk.goscomb.net/ubuntu-releases/20.04/ubuntu-$(shell cat $(CURDIR)/versions.json | jq -r '.source')-live-server-amd64.iso -P source/

update-config:
	./update-config.sh

clean-project:
	sudo rm -rf project/custom-disk/ project/custom-root

clean-archives:
	rm -rf archives/*

remove-images:
	rm *.img *.iso *.md5