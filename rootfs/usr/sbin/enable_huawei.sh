#!/bin/bash

echo "triggering udev rule 40-huawei-lte.rules at $(date)" > /var/log/udev-huawei.log

usb_modeswitch -J -c /etc/usb_modeswitch.conf

echo "finished udev rule 40-huawei-lte.rules at $(date)" >> /var/log/udev-huawei.log

# check device properties:
# $ udevadm info -a -n /dev/sr0
#
# monitor udev:
# $ udevadm monitor
#
# enter properties in udev rule:
# ATTRS{idVendor}=="12d1", ATTRS{manufacturer}!="Android", ATTR{bInterfaceNumber}=="00", ATTR{bInterfaceClass}=="08", RUN+="usb_modeswitch '%b/%k'"
