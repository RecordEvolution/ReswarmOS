#!/bin/sh

set -u
set -e

# check for *.reswarm file in /boot directory
reswmexst=$(ls /boot/ | grep -E ".reswarm")

if [ -z ${reswmexst} ]; then
  echo "no reswarm file found => going to set up device according to device-config.ini"
else
  echo "found reswarm file: ${reswmexst}"

  # preliminary solution! => mount directory and config files according to weird 
  # requirements of wamp_management.py
  pwdmng="/home/agent"
  mkdir -pv ${pwdmng}/config
  mkdir -pv ${pwdmng}/boot

  # apparently the management-agent expects boot/config.txt and boot/cmdline.txt as well
  cp -v /boot/config.txt ${pwdmng}/boot/
  cp -v /boot/cmdline.txt ${pwdmng}/boot/

  # find and parse *.reswarm configuration and write separate configuration files to appropriate locations
  python3 parse-config.py /boot/${reswmexst} ${pwdmng}/config/device-config.yaml \
	                                     ${pwdmng}/boot/client.key.pem \
					     ${pwdmng}/boot/client.cert.pem \
					     /boot/device-config.ini
  
  # login to reswarm registry and pull the management agent
  docker login -u RecordEvolution -p hgwo5f3xd2hf02f3s9fhldj3 registry.reswarm.io
  docker pull registry.reswarm.io/apps/arm_svc_mgmt_agent:latest
  docker pull registry.reswarm.io/apps/arm_svc_app_logs:latest

  # start management-agent container with required volumes and options
  docker run -it --rm --name arm_svg_mgmt_agent \
	     -v ${pwdmng}/config:/home/pirate/config \
	     -v ${pwdmng}/boot:/boot \
	     -v /var/run/docker.sock:/var/run/docker.sock \
	     registry.reswarm.io/apps/arm_svc_mgmt_agent


fi

