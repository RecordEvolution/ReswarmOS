#!/bin/bash

TC=/usr/sbin/tc
IP=/usr/sbin/iptables
PF=/usr/bin/iperf3
JQ=/usr/bin/jq

# reswarm configuration
reconfig=/opt/reagent/device-config.reswarm

# --------------------------------------------------------------------------- #

# get interface in use (mostly wlan0,eth0)
get_iface()
{
  iface=$(route | grep UG | head -n1 | awk '{print $NF}')
  echo "${iface}"
}

# get PID of active reagent process
get_reagent_pid()
{
  pid=$(ps -eo pid,command,args | grep Reagent-active | grep -v grep | head -n1 | awk '{print $1}')
  echo "${pid}"
}

# get device endpoint url
get_device_endpoint()
{
  if [ ! -L ${reconfig} ]; then
    echo "soft link to *.reswarm configuration is missing" >&2
    exit 1
  fi
  if [ ! -f ${reconfig} ]; then
    echo "*.reswarm configuration is missing" >&2
    exit 1
  fi

  devendpoint=$(cat ${reconfig} | $JQ ' . | ."device_endpoint_url"')
  devendpoint=$(echo "${devendpoint}" | tr -d '"' | awk -F '//' '{print $2}')
  echo "${devendpoint}"
}

# show tc rules
show_tc_rules()
{
  echo "---- started show_tc_rules ----"
  tc qdisc show dev $IF
  tc class show dev $IF
  tc -g class show dev $IF
  tc filter show dev $IF
  echo "---- finished show_tc_rules ----"
}

# delete tc rules on interface
clear_tc_rules()
{
  echo "---- started clear_tc_rules ----"
  tc qdisc del dev $IF root
  tc filter del dev wlan0
  echo "---- finished clear_tc_rules ----"
}

# set up cgroup
setup_cgroup()
{
  echo "---- started setup_cgroup ----"

  # create hierarchy
  mkdir -pv /sys/fs/cgroup/net_cls/reagent

  # set classid (format 0xAAAABBBB)
  echo 0xf01000a1 > /sys/fs/cgroup/net_cls/reagent/net_cls.classid

  # check result
  ls /sys/fs/cgroup/net_cls/reagent -lh
  echo "classid: $(cat /sys/fs/cgroup/net_cls/reagent/net_cls.classid)"
  echo -e "tasks: \n$(cat /sys/fs/cgroup/net_cls/reagent/tasks)"

  echo "---- finished setup_cgroup ----"
}

# set up qdisc and classes
setup_classes()
{
  echo "---- started setup_classes ----"

  $TC -Version

  echo "add root qdisc"
  $TC qdisc add dev $IF root handle f010: htb default a2

  echo "intermediate class (to throttle for testing)"
  $TC class add dev $IF parent f010: classid f010:a0 htb rate 500mbit

  #echo "add htb rate classes"
  #$TC class add dev $IF parent f010:a0 classid f010:a1 htb rate 100mbit
  #$TC class add dev $IF parent f010:a0 classid f010:a2 htb rate 4kbit

  echo "add prio classes"
  $TC class add dev $IF parent f010:a0 classid f010:a1 htb rate 400mbit prio 1
  $TC class add dev $IF parent f010:a0 classid f010:a2 htb rate 400mbit prio 2

  #echo "add prio qdisc"
  #$TC qdisc add dev $IF parent f010:a0 handle ff: prio
  # => creates three child classes by default, i.e. ff:1, ff:2, ff:3

  #echo "attach leave classes for filtering"
  #$TC class add dev $IF parent ff:1 classid f010:a1
  #$TC class add dev $IF parent ff:2 classid f010:a2

  echo "---- finished setup_classes ----"
}

# set up filters
setup_filters()
{
  echo "---- started setup_filter ----"

  devendpoint=$(get_device_endpoint)
  devendip=$(echo ${devendpoint} | awk -F ':' '{print $1}')
  devendpt=$(echo ${devendpoint} | awk -F ':' '{print $2}')

  # cgroup based filter
  #$TC filter add dev $IF parent f010: handle 7: protocol ip cgroup

  # IP/port device endpoint based filter
  $TC filter add dev $IF protocol ip parent f010: prio 1 \
	  u32 match ip dst ${devendip}/32 flowid f010:a1
#	  u32 match ip dst 192.168.178.43/32 flowid f010:a1
#	  u32 match ip dst ${devendip}/32 flowid f010:a1
#	  u32 match ip dst ${devendip} dport ${devendpt} flowid f010:a1

  echo "---- finished setup_filters ----"
}

# add task to cgroup
add_task()
{
  echo "---- started add_task ----"

  taskpid="$1"
  if [ -z ${taskpid} ]; then
    echo "missing PID argument" >&2
    exit 1
  fi

  echo "${taskpid}" > /sys/fs/cgroup/net_cls/reagent/tasks
  echo "tasks: \n$(cat /sys/fs/cgroup/net_cls/reagent/tasks)"

  echo "---- finished add_task ----"
}

# --------------------------------------------------------------------------- #

# get/select default interface
IF=$(get_iface)

# check for correctly set up interface
if [ -z $IF ]; then
  echo "no default interface detected" >&2
  exit 1
fi

# check prerequisites
echo -e "current default interface:   $IF"

devendpoint=$(get_device_endpoint)
devendip=$(echo ${devendpoint} | awk -F ':' '{print $1}')
devendpt=$(echo ${devendpoint} | awk -F ':' '{print $2}')
echo -e "device endpoint url/port:    ${devendip}:${devendpt}"

reagentpid=$(get_reagent_pid)
echo -e "PID of main reagent process: ${reagentpid}"

# reset all qdiscs, classes, filters...
clear_tc_rules

# show current tc rules
echo -e "$(show_tc_rules)"

# set up cgroup
#setup_cgroup

# set up traffic control
setup_classes
setup_filters

# when using cgroups => add reagent's PID to cgroup tasks (or use 'cgexec' anyway)
#add_task ${reagentpid}

echo -e "$(show_tc_rules)"

# --------------------------------------------------------------------------- #
