#!/bin/bash

# prepare image 
# $ mkdir /etc/wpa_supplicant/
# $ ln -s /etc/wpa_supplicant.conf /etc/wpa_supplicant/

# define volume directory
pwdmng="/home/agent"

docker run -it --rm --name arm_svg_mgmt_agent \
	       --net host \
	       --restart=no \
	       --device /dev/mem:/dev/mem \
	       --privileged \
	       --label real=True \
	       -v /etc/wpa_supplicant:/etc/wpa_supplicant:rw \
	       -v /etc/network/interfaces:/etc/network/interfaces:rw \
	       -v /run/dbus:/run/dbus \
	       -v ${pwdmng}/config:/home/pirate/config \
	       -v ${pwdmng}/boot:/boot \
	       -v /var/run/docker.sock:/var/run/docker.sock \
	       registry.reswarm.io/apps/arm_svc_mgmt_agent

