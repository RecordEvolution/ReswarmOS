#!/bin/bash

# place it in /etc/profile.d/

# acquire subnet ip including its mask
subnetip()
{
  iface=$(route | grep default | awk -F ' ' '{print $NF}')
  ipsub=$(ip address | grep $iface -A30 | grep "^[0-9]:" -m2 -B30 | grep "inet " | awk -F ' ' '{print $2}')
  echo ${ipsub}
}

# define login banner
bannerA=$(cat << EOF
   Welcome to
 ____  _____ ______        ___    ____  __  __  ___  ____  
|  _ \| ____/ ___\ \      / / \  |  _ \|  \/  |/ _ \/ ___| 
| |_) |  _| \___ \\\ \ /\ / / _ \ | |_) | |\/| | | | \___ \ 
|  _ <| |___ ___) |\ V  V / ___ \|  _ <| |  | | |_| |___) |
|_| \_\_____|____/  \_/\_/_/   \_\_| \_\_|  |_|\___/|____/ 
                                                         
   $(uptime | sed 's/^ *//g')
   $(uname -a)

   user:      $(whoami)
   host:      $(hostname)
   date:      $(date)
   shell:     $(echo $SHELL)
   cpu:       $(cat /proc/cpuinfo | grep "model name" -i -m1 | awk -F ':' '{print $2}' | sed 's/^ *//g')
   memory:    $(cat /proc/meminfo | grep "memtotal" -i -m1 | awk -F ':' '{print $2}' | sed 's/^ *//g')
   subnet ip: $(subnetip)
   public ip: $(dig +short myip.opendns.com @resolver1.opendns.com)
EOF
)


echo ""
echo "${bannerA}"
echo ""

