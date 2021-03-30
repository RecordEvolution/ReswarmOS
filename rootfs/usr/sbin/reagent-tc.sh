#!/bin/sh

# check required kernel modules
modex=$(lsmod | grep cls_cgroup)
if [ -z ${modex} ]; then
  modprobe cls_cgroup
fi

# check (mount of) cgroup net_cls controller
ls /sys/fs/cgroup/net_cls
mount | grep /sys/fs/cgroup/net_cls

# choose interface to be configured
ifc="wlan0"

# References:
# - https://www.kernel.org/doc/Documentation/cgroup-v1/net_cls.txt
# - https://linux.die.net/man/8/tc
# - https://linux.die.net/man/8/tc-prio
# - https://www.netfilter.org/documentation/HOWTO/networking-concepts-HOWTO-2.html
# - https://tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.qdisc.classful.html
# - https://www.netfilter.org/documentation/HOWTO/packet-filtering-HOWTO.html
# - https://stackoverflow.com/questions/9904016/how-to-priotize-packets-using-tc-and-cgroups

# show current qdisc rules
tc -s qdisc show dev ${ifc}

# delete and restore default
tc qdisc del dev ${ifc} root

# set up new cgroup
mkdir -pv /sys/fs/cgroup/net_cls/reagent

# choose classid (format 0xAAAABBBB)
echo 0x00100001 >  /sys/fs/cgroup/net_cls/reagent/net_cls.classid
cat /sys/fs/cgroup/net_cls/reagent/net_cls.classid

# configure traffic shaping based on new cgroup
tc qdisc add dev ${ifc} root handle 10: htb
tc filter add dev ${ifc} parent 10: protocol ip prio 10 handle 1: cgroup

# show final qdisc rules
tc qdisc show dev ${ifc}

# add (exclusively!) reagent process to cgroup
reagentpid=$(ps -eo pid,command,args | grep reagent | grep -v grep | awk '{print $1}' | tr -d ' ')
echo "using PID ${reagentpid} of reagent service"
echo "${reagentpid}" > /sys/fs/cgroup/net_cls/reagent/tasks
echo "/sys/fs/cgroup/net_cls/reagent/tasks"
cat /sys/fs/cgroup/net_cls/reagent/tasks
