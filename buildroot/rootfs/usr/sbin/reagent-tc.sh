#!/bin/sh

# TODO: 1. only on first boot up
#       2. let evtl. systemd handle it
#       3. don't check cgroup mount

# choose interface(s) to be configured
# TODO dynamic configuration by using actually used interface, i.e. `route`
ifc="wlan0 eth0"

# check required kernel modules
check_kernel()
{
  modex=$(lsmod | grep cls_cgroup | head -n1)
  if [ -z "${modex}" ]; then
    modprobe cls_cgroup
  fi
}

# check (mount of) cgroup net_cls controller
check_mount()
{
  ls /sys/fs/cgroup/net_cls
  mount | grep /sys/fs/cgroup/net_cls
}

# show current qdisc rules
show_qdisc()
{
  tc -s qdisc show dev ${ifc}
}

# make sure to restore default (will evtl. return 'RTNETLINK answers: No such file or directory')
clean_qdisc()
{
  tc qdisc del dev ${ifc} root
}

# set up new cgroup
setup_cgroup()
{
  mkdir -pv /sys/fs/cgroup/net_cls/reagent

  # choose classid (format 0xAAAABBBB)
  echo 0x00100001 >  /sys/fs/cgroup/net_cls/reagent/net_cls.classid
  cat /sys/fs/cgroup/net_cls/reagent/net_cls.classid

  # configure traffic shaping based on new cgroup
  tc qdisc add dev ${ifc} root handle 10: htb
  tc filter add dev ${ifc} parent 10: protocol ip prio 10 handle 1: cgroup

  # show final qdisc rules
  tc qdisc show dev ${ifc}
}

# add (exclusively!) reagent process to cgroup
add_reagent()
{
  reagentpid=$(ps -eo pid,command,args | grep Reagent | grep -v grep | head -n1 | awk '{print $1}' | tr -d ' ')

  if [ -z ${reagentpid} ]; then
    echo "no PID for reagent found: reagent apparently failed to start"
  else
    echo "using PID ${reagentpid} of reagent service"
    echo "${reagentpid}" > /sys/fs/cgroup/net_cls/reagent/tasks
    echo "/sys/fs/cgroup/net_cls/reagent/tasks"
    cat /sys/fs/cgroup/net_cls/reagent/tasks
  fi
}

# References:
# - https://www.kernel.org/doc/Documentation/cgroup-v1/net_cls.txt
# - https://linux.die.net/man/8/tc
# - https://linux.die.net/man/8/tc-prio
# - https://www.netfilter.org/documentation/HOWTO/networking-concepts-HOWTO-2.html
# - https://tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.qdisc.classful.html
# - https://www.netfilter.org/documentation/HOWTO/packet-filtering-HOWTO.html
# - https://stackoverflow.com/questions/9904016/how-to-priotize-packets-using-tc-and-cgroups
# - https://wiki.debian.org/TrafficControl
#
# -http://manpages.ubuntu.com/manpages/xenial/man8/tc-cgroup.8.html
#
# - https://www.linux.com/training-tutorials/qos-linux-tc-and-filters/
# - https://tldp.org/HOWTO/html_single/Traffic-Control-HOWTO/
# - https://unix.stackexchange.com/questions/328308/how-can-i-limit-download-bandwidth-of-an-existing-process-iptables-tc
# - https://lartc.org
# - https://lartc.org/howto/lartc.qdisc.filters.html
#
# - http://borg.uu3.net/traffic_shaping/monitoring.html
