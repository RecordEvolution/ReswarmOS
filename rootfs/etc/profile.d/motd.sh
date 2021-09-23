#!/bin/bash

# place it in /etc/profile.d/ and set $ chmod 644

# define login banner
bannerA=$(cat << 'EOF'
        Welcome to
  ____  _____ ______        ___    ____  __  __  ___  ____
 |  _ \| ____/ ___\ \      / / \  |  _ \|  \/  |/ _ \/ ___|
 | |_) |  _| \___ \\ \ /\ / / _ \ | |_) | |\/| | | | \___ \ 
 |  _ <| |___ ___) |\ V  V / ___ \|  _ <| |  | | |_| |___) |
 |_| \_\_____|____/  \_/\_/_/   \_\_| \_\_|  |_|\___/|____/

EOF
)

# get operating system info and version tag
ostags()
{
  osname=$(cat /etc/os-release | grep "^NAME=" | awk -F '=' '{print $2}' | tr -d '\n "')
  osversion=$(cat /etc/os-release  | grep "^VERSION=" | awk -F '=' '{print $2}' | tr -d '\n "')
  if [ -f /etc/os-release-base ]; then
    basename=$(cat /etc/os-release-base | grep "^NAME=" | awk -F '=' '{print $2}' | tr -d '" ')
    basevrsn=$(cat /etc/os-release-base | grep "^VERSION=" | awk -F '=' '{print $2}' | tr -d '" ')
    basetag=" (based on ${basename} ${basevrsn})"
  else
    basetag=""
  fi
  echo "${osname} ${osversion} ${basetag}"
}

# ReswarmOS updates
osupdates()
{
  updatestate=/etc/reswarmos-update
  osupdate="system is up-to-date"
  if [ -f ${updatestate} ]; then
    osupdateversion=$(cat ${updatestate} | awk -F ',' '{print $1}')
    osupdatebldtime=$(cat ${updatestate} | awk -F ',' '{print $2}')
    if [ ! -z "${osupdateversion}" ]; then
      osupdate="update available: v${osupdateversion} (${osupdatebldtime})"
    fi
  fi
  echo "${osupdate}"
}

# Reswarm vs. standalone mode
reswarmmode()
{
  if [ -f /opt/reagent/reswarm-mode ]; then
	  devEndpoint=$(cat /opt/reagent/device-config.reswarm |  jq '.|."device_endpoint_url"' | tr -d '"')
	  reagentState=$(systemctl show reagent | grep ActiveState | awk -F '=' '{print $2}')
	  echo "Reswarm (device-endpoint: ${devEndpoint} , Reagent: ${reagentState})"
  else
    echo "standalone"
  fi
}

# shell and its version
theshell()
{
  whichOne=$SHELL
  shellVersion=$(${whichOne} --version | grep version | grep bash | grep -oP "version [0-9]+.[0-9]+.[0-9]+(\([0-9]\))?")
  echo "${whichOne} ${shellVersion}"
}

# acquire subnet ip including its mask
subnetip()
{
  #iface=$(route | grep default | sort | head -n1 | awk '{print $NF}')
  #ipsub=$(ip address | grep ${iface} -A30 | grep "^[0-9]:" -m2 -B30 | grep "inet " | awk '{print $2}')
  #echo "${ipsub} (${iface})"

  ifaces=$(route | grep default | sort | awk '{print $NF}')
  ipsubs=$(echo "${ifaces}" | while read if; do echo "$(ip address | grep ${if} -A30 | grep "^[0-9]: " -B 30 -m2 | grep "inet " | awk '{print $2}') ($if)"; done | sed 's/$/ /g' | tr -d '\n')
  echo "${ipsubs}"

}

# get value of JSON key
getkey()
{
  echo "$1" | grep -o "\"$2\": \"[^\"]*\"" | awk -F ':' '{print $2}' | tr -d '"' | sed 's/^ *//g' | sed 's/ *$//g'
}

# board/model/hardware
boardhardware()
{
  cpumodel=$(lscpu | grep "Model name" | awk -F ':' '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
  boardmod=$(cat /proc/cpuinfo | grep "Model" | awk -F ':' '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
  hardware=$(cat /proc/cpuinfo | grep "Hardware" | awk -F ':' '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
  echo "${boardmod} ${cpumodel} ${hardware}" | sed 's/^ //g' | sed 's/  / /g' | sed 's/ $//g'
}

# CPU
cpuinfo()
{
  cpuinfoA=$(cat /proc/cpuinfo | grep "model name" -i -m1 | awk -F ':' '{print $2}' | sed 's/^ *//g')
  cpuinfoB=$(cat /proc/cpuinfo | grep "Hardware" -i -m1 | awk -F ':' '{print $2}' | sed 's/^ *//g')
  if [ ! -z "${cpuinfoA}" ]; then
    cpuinfo="${cpuinfoA}"
  elif [ ! -z "${cpuinfoB}" ]; then
    cpuinfo="${cpuinfoB}"
  fi
  echo "${cpuinfo}" | sed 's/^ //g' | sed 's/  / /g' | sed 's/ $//g'
}

# filesystem free/used
rootfs()
{
  totalsize=$(df -h | grep " /$" | awk '{print $2}' | tr -d  ' ')
  usedsize=$(df -h | grep " /$" | awk '{print $3}' | tr -d  ' ')
  echo "${usedsize} / ${totalsize} used"
}
appfs()
{
  totalsize=$(df -h | grep " /apps$" | awk '{print $2}' | tr -d  ' ')
  usedsize=$(df -h | grep " /apps$" | awk '{print $3}' | tr -d  ' ')
  echo "${usedsize} / ${totalsize} used"
}

# geo location
geolocation()
{
  pubip=$(wget -qO- http://ipinfo.io/ip)
  locat=$(wget -qO- "ipinfo.io/${pubip}")
  echo "$(getkey "${locat}" city) $(getkey "${locat}" region) $(getkey "${locat}" country) $(getkey "${locat}" loc)"
  #echo "${locat}" | grep -Po "\"city\": \"[^\"]*\"" | awk -F ':' '{print $2}' | tr -d '"' | sed 's/^ *//g' | sed 's/ *$//g'
}

# add system information
ossysteminfo=$(cat << EOF
   $(date)

   $(uptime | sed 's/^ *//g')
   $(uname -a)

   os:         $(ostags)
   update:     $(osupdates)
   mode:       $(reswarmmode)

   user:       $(whoami)
   host:       $(hostname)
   shell:      $(theshell)

   board:      $(boardhardware)
   cpu:        $(cpuinfo)
   memory:     $(cat /proc/meminfo | grep "memtotal" -i -m1 | awk -F ':' '{print $2}' | sed 's/^ *//g')
   rootfs:     $(rootfs)
   appfs:      $(appfs)

   subnet ip:  $(subnetip)
   public ip:  $(wget -qO- http://ipinfo.io/ip)
   location:   $(geolocation)

   containers: $(docker ps | grep -v '^CONTAINER' | wc -l) running, $(docker ps -a | grep -v '^CONTAINER' | wc -l) stopped
EOF
)

echo ""
echo "${bannerA}"
#if [ -f /opt/reagent/reswarm-mode ]; then
#  echo -e "\033[0;32m${bannerA}\033[0m"
#else
#  echo -e "\033[0;31m${bannerA}\033[0m"
#fi
echo ""
echo "${ossysteminfo}"
echo ""

