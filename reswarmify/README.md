# Reswarmify CLI
Make use of the Reswarmify CLI in order to connect a device with Unix based operating system to the Record Evolution platform.
If your device cannot be setup with the SD card installation or USB stick installer, you can perform a manual installation by executing a setup.sh script.
We assume that you have follwed the instructions of your device and already installed an operating system or the device has already a pre-installed system on it.

## 1. Download the CLI tool
Your device needs to have an internet connection to proceed.
Connect to your device via SSH and download the following device setup binary `reswarmify-cli`
Do not forget to replace $ARCH in the URL below with the architecture of your choice.

### Possible architecture values:

- arm64
- amd64
- armv7
- armv6
- armv5
  
### The download URL:
`wget https://storage.googleapis.com/reswarmos/reswarmify/linux/$ARCH/1.0.2/reswarmify-cli`

## 2. Usage of the CLI tool

Make sure the script is executable: `chmod +x reswarmify-cli`. <br>

On the local computer/laptop that you used to create the device in the Record Evolution platform you have the downloaded device configuration `.reswarm` file `(<your device config file>)`.<br>

This file needs to be copied to your device with `scp <local path to your device config file> <username on your device>@<ip-address-of-your-device:/home/<username on your device>`

On the device execute the `reswarmify-cli` to register the device with the Record Evolution platform:<br>
`sudo ./reswarmify-cli -c <your device config file>`.<br>
As soon as the script finishes, your device should be connected.

### Interface

```
CLI tool to help reswarmify your device

Usage:
  reswarmify-cli [flags]

Flags:
  -c, --config string   Path to .reswarm config file
  -h, --help            help for reswarmify-cli
```
