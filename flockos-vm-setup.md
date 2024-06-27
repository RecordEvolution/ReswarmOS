# FlockOS Development VM

## General

1. Download the [Ubuntu 22.04.4 ISO](https://releases.ubuntu.com/jammy/ubuntu-22.04.4-desktop-amd64.iso).

2. Install using VMware Workstation (needed due to [Compute Engine](https://cloud.google.com/compute/docs/import/import-ovf-files#source_vm_requirements) requirements).

3. Mount a `$HOME/Desktop/VM` folder from host to guest.

4. Update packages to the latest versions using `sudo apt update && sudo apt upgrade`.

5. [Install Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository).

6. Perform [Linux post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/) for Docker.

7. Generate SSH keys using `ssh-keygen`.

8. Add `$HOME/.ssh/id_rsa.pub` to [GitHub](https://github.com/settings/keys) to clone GitHub repositories.

9. Create the `$HOME/git` folder using `mkdir -p $HOME/git`.

10. Clone the FlockOS repository using `git clone git@github.com:RecordEvolution/ReswarmOS.git`.

11. Set the Git username and email:

```bash
git config --global user.name "username"
git config --global user.email "email"
```

## Cubic

1. Install [Cubic](https://github.com/PJ-Singh-001/Cubic):

```bash
sudo apt-add-repository universe
sudo apt-add-repository ppa:cubic-wizard/release
sudo apt update
sudo apt install --no-install-recommends cubic
```

2. [Install Golang](https://go.dev/doc/install).

3. Install Make and VS Code: `sudo apt install make && sudo snap install code --classic`.

4. Navigate to the Cubic folder and download the source ISO:

```bash
cd $HOME/git/ReswarmOS/cubic && make download-source
```

5. Remove the `cubic.conf` file:

```bash
rm $HOME/git/ReswarmOS/cubic/project/amd64/cubic.conf
```

6. Launch Cubic using `make setup-amd64`.

7. 

- Select the source image and target folder (`$HOME/git/ReswarmOS/cubic/source` and `$HOME/git/ReswarmOS/cubic/target`).
- Set the target ISO name as `ReswarmOS-0.0.1-installer-amd64.iso`.
- Set the volume ID and disk name.
- Click "Next".

8. Overlay the root filesystem using `make overlay-fs-amd64`.

9. Run the `$HOME/git/ReswarmOS/cubic/scripts/setup-rootfs.sh` file in the virtual environment. This can be done by copying and pasting the contents into the virtual environment.

```bash
chmod +x $HOME/git/ReswarmOS/cubic/scripts/setup-rootfs.sh
./setup-rootfs.sh
```

This will set up Docker and all required binaries for the installer ISO. When finished, click "Next".

10. Copy over preseed and boot configs using `make setup-efi-amd64 && make setup-boot-amd64` and click "Next".

11. Generate the final ISO image using default compression.

## Buildroot

1. Navigate to `$HOME/git/ReswarmOS/buildroot`.

2. Run `make setup && make build`.

## Google Cloud

1. Install the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install#installation_instructions)

2. Initialize Gcloud:

`gcloud init`

3. Import the [VMWare OVF using Gcloud](https://cloud.google.com/compute/docs/import/import-ovf-files#import_ovf_file)

## Linux VMware Setup

- Load the kernel modules:

```bash
sudo modprobe -a vmw_vmci vmmon
```

- Start the network:

```bash
sudo modprobe vmnet && sudo vmware-networks --start
sudo systemctl enable --now vmware-networks.service
```

- Install VMware tools on Ubuntu:

```bash
sudo apt install open-vm-tools open-vm-tools-desktop
```