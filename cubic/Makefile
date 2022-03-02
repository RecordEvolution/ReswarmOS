setup:
	cubic project/

create-img:
	qemu-img create reswarm.img 16G

install-bios: create-img
	qemu-system-x86_64 --name "ReswarmOS" -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=reswarm.img -cdrom ReswarmOS-0.0.1-Installer-amd64.iso -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

install-efi: create-img
	qemu-system-x86_64 --name "ReswarmOS" -bios /usr/share/ovmf/OVMF.fd -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=reswarm.img -cdrom ReswarmOS-0.0.1-Installer-amd64.iso -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

run-efi:
	qemu-system-x86_64 --name "ReswarmOS" -bios /usr/share/ovmf/OVMF.fd -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=reswarm.img -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

run-bios:
	qemu-system-x86_64 --name "ReswarmOS" -M pc -enable-kvm -cpu host -m 16G -display gtk,zoom-to-fit=on -device intel-hda -device hda-duplex -drive format=raw,file=reswarm.img -net nic,model=virtio -net user,hostfwd=tcp::2222-:22

archive-project:
	sudo rm reswarmos-installer-archives/installerfs-v$(shell cat $(CURDIR)/version.txt).tar.gz
	sudo tar -cpvzf reswarmos-installer-archives/installerfs-v$(shell cat $(CURDIR)/version.txt).tar.gz custom-disk/ custom-root/

extract-project:
	sudo tar xzf $(CURDIR)/reswarmos-installer-archives/installerfs-v$(shell cat $(CURDIR)/version.txt).tar.gz -C $(CURDIR)/project

clean-project:
	sudo rm -rf project/custom-disk/ project/custom-root
remove-images:
	rm *.img *.iso *.md5