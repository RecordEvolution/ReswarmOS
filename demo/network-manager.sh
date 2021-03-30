#!/bin/sh

nmcli radio

nmcli device

nmcli device wifi rescan
nmcli device wifi list
nmcli device wifi connect SSID-Name password wireless-password
