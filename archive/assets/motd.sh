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

# acquire subnet ip including its mask
subnetip()
{
  iface=$(route | grep default | awk -F ' ' '{print $NF}')
  #ipsub=$(ip address | grep "${iface}" -A30 | grep "^[0-9]:" -m2 -B30 | grep "inet " | awk -F ' ' '{print $2}')
  ipsub=$(echo "${iface}" | while read f; do echo $f | ip address | grep $f -A30 | grep "^[0-9]:" -m2 -B30 | grep "inet " | awk -F  ' ' '{print $2}'; done;)
  echo ${ipsub}
}

# get value of JSON key
getkey()
{
  echo "$1" | grep -o "\"$2\": \"[^\"]*\"" | awk -F ':' '{print $2}' | tr -d '"' | sed 's/^ *//g' | sed 's/ *$//g'
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
   $(uptime | sed 's/^ *//g')
   $(uname -a)

   os:        $(cat /etc/reswarmos.txt | tr -d '\n ')
   user:      $(whoami)
   host:      $(hostname)
   date:      $(date)
   shell:     $(echo $SHELL)
   cpu:       $(cat /proc/cpuinfo | grep "model name" -i -m1 | awk -F ':' '{print $2}' | sed 's/^ *//g')
   memory:    $(cat /proc/meminfo | grep "memtotal" -i -m1 | awk -F ':' '{print $2}' | sed 's/^ *//g')
   subnet ip: $(subnetip)
   public ip: $(wget -qO- http://ipinfo.io/ip)
   location:  $(geolocation)
EOF
)

echo ""
echo "${bannerA}"
echo ""
echo "${ossysteminfo}"
echo ""

