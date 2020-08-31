
# Network setup

## Wifi

### Check network devices

To get the WIFI module running and configured with _ReswarmOS_ with the
_Raspberry PI_ we can perform the following steps:

1. First of all, check available WIFI modules (and vendors) in device:
  ```
  ifconfig
  # or
  iwconfig
  ```
  If no entry related to `wlan0` shows up, the WIFI module has to be configured.

#### References

- https://wiki.ubuntuusers.de/WLAN/wpa_supplicant/

### rfkill

The _rfkill_ is a kernel subsystem to enable/disable any wireless devices.
To list all available devices

```
rfkill list <subclass>
```

where subclass maybe, for instance, `wifi`. In order to disable/enable a
specific subclass of devices use

```
rfkill (un)block wifi
```

#### References

- https://linux.die.net/man/1/rfkill
- https://wiki.ubuntuusers.de/rfkill/

### List available WIFI networks

To list the locally available WIFI networks the tool _nmcli_ of the package
`network-manager`

```
nmcli dev wifi
```

or simply

```
(sudo) iwlist wlp3s0 scan
```

where `wlp3s0` is the WIFI device inteface name retrieved via `ifconfig`
and to avoid `No scan results` return value, for instance, on Raspberry Pi OS,
we have to prepend a `sudo` to acquire the necessary permissions.

### Configure WIFI module

There are basically three possiblities to configure the WIFI module:

1. configuring the file `/etc/network/interfaces`
  To enable the wirless network adapter via this configuration file append
  the following lines to the file:
  ```
  # WLAN
  allow-hotplug wlan0
  iface wlan0 inet manual
  wpa-ssid "WLAN-NAME"
  wpa-psk "WLAN-PASSWORT"
  ```
  After saving the file we have to restart the corresponding service:
  ```
  ifdown wlan0
  ifup wlan0
  ```
1. using the package `wpa_supplicant`
1. configuration via `systemd`
