# Reswarmify CLI

## Download
Connect to your device via SSH and download the following device setup binary `reswarmify-cli`
Do not forget to replace $ARCH in the URL below with the architecture of your choice.

### Possible architecture values:

- arm64
- amd64
- armv7
- armv6
- armv5
  
### The download URL:
`wget https://storage.googleapis.com/reswarmos/reswarmify/linux/$ARCH/1.0.1/reswarmify-cli`

## Usage

```
CLI tool to help reswarmify your device

Usage:
  reswarmify-cli [flags]

Flags:
  -c, --config string   Path to .reswarm config file
  -h, --help            help for reswarmify-cli
```

- Make sure the script is executable: `chmod +x reswarmify-cli`.
- On the local computer/laptop that you used to create the device in the Record Evolution platform you have the downloaded device configuration `.reswarm` file `(<your device config file>)`.
- This file needs to be copied to your device with `scp <local path to your device config file> <username on your device>@<ip-address-of-your-device:/home/<username on your device>`

On the device execute the reswarmify-cli to register the device with the Record Evolution platform
As soon as the script finishes, your device should be connected
