#!/bin/bash

TC=/usr/sbin/tc
IP=/usr/sbin/iptables
PF=/usr/bin/iperf3
JQ=/usr/bin/jq

# reswarm configuration
reconfig=/opt/reagent/device-config.reswarm

# --------------------------------------------------------------------------- #

# get active/default interfaces (mostly wlan0,eth0)
get_ifaces()
{
  # ifaces=$(route | grep UG | head -n1 | awk '{print $NF}')
  ifaces=$(nmcli connection show --active | grep -v NAME | grep -v docker \
   | awk '{print $NF}' | sed 's/$/ /g' | tr -d '\n')
  echo "${ifaces}"
}

# get PID of active reagent process
get_reagent_pid()
{
  pid=$(ps -eo pid,command,args | grep Reagent-active | grep -v grep \
   | head -n1 | awk '{print $1}')
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

# get IP of endpoint by evtl. resolving domainname
resolve_endpoint()
{
  if [ -z "$1" ]; then
    echo "isip: missing IP/domainname argument" >&2
    exit 1
  fi

  # check for argument being an IP already
  theip=$(echo "$1" | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}")

  if [ -z ${theip} ]; then
    echo $(dig "$1" +short)
  else
    echo "$1"
  fi
}

# show tc rules
show_tc_rules()
{
  echo "---- started show_tc_rules ----"

  iface="$1"
  if [ -z ${iface} ]; then
    echo "missing iface argument" >&2
    exit 1
  fi

  echo "for interface: ${iface}"

  tc qdisc show dev $iface
  tc class show dev $iface
  tc -g class show dev $iface
  tc filter show dev $iface

  echo "---- finished show_tc_rules ----"
}

# delete tc rules on interface
clear_tc_rules()
{
  echo "---- started clear_tc_rules ----"

  iface="$1"
  if [ -z ${iface} ]; then
    echo "missing iface argument" >&2
    exit 1
  fi

  echo "for interface: ${iface}"

  tc qdisc del dev $iface root
  tc filter del dev $iface

  echo "---- finished clear_tc_rules ----"
}

# set up qdisc and classes
setup_classes()
{
  echo "---- started setup_classes ----"

  $TC -Version

  iface="$1"
  if [ -z ${iface} ]; then
    echo "missing iface argument" >&2
    exit 1
  fi

  echo "for interface: ${iface}"

  echo "add root qdisc"
  $TC qdisc add dev $iface root handle f010: htb default a2

  echo "intermediate class (to throttle for testing)"
  $TC class add dev $iface parent f010: classid f010:a0 htb rate 500mbit

  #echo "add htb rate classes"
  #$TC class add dev $iface parent f010:a0 classid f010:a1 htb rate 100mbit
  #$TC class add dev $iface parent f010:a0 classid f010:a2 htb rate 4kbit

  echo "add prio classes"
  $TC class add dev $iface parent f010:a0 classid f010:a1 htb rate 400mbit prio 1
  $TC class add dev $iface parent f010:a0 classid f010:a2 htb rate 400mbit prio 2

  #echo "add prio qdisc"
  #$TC qdisc add dev $iface parent f010:a0 handle ff: prio
  # => creates three child classes by default, i.e. ff:1, ff:2, ff:3

  #echo "attach leave classes for filtering"
  #$TC class add dev $iface parent ff:1 classid f010:a1
  #$TC class add dev $iface parent ff:2 classid f010:a2

  echo "---- finished setup_classes ----"
}

# set up filters
setup_filters()
{
  echo "---- started setup_filter ----"

  iface="$1"
  if [ -z ${iface} ]; then
    echo "missing iface argument" >&2
    exit 1
  fi

  echo "for interface: ${iface}"

  # include local network IPs
  localnet=$(ip add | grep ${iface} -A 50 | grep inet -m1 | awk '{print $2}' | tr -d ' ')
  echo "local ip: ${localnet}"

  # cgroup based filter
  #$TC filter add dev $IF parent f010: handle 7: protocol ip cgroup

  devendpoint=$(get_device_endpoint)
  if [ ! -z "${devendpoint}" ]; then

    devendipdm=$(echo ${devendpoint} | awk -F ':' '{print $1}')
    devendport=$(echo ${devendpoint} | awk -F ':' '{print $2}')
    devendip=$(resolve_endpoint ${devendipdm})

    # IP/port device endpoint based filter
    $TC filter add dev $iface protocol ip parent f010: prio 1 \
      u32 match ip dst ${devendip}/32 flowid f010:a1
    $TC filter add dev $iface protocol ip parent f010: prio 1 \
      u32 match ip src ${devendip}/32 flowid f010:a1
    $TC filter add dev $iface protocol ip parent f010: prio 1 \
      u32 match ip dst ${localnet} flowid f010:a1
    $TC filter add dev $iface protocol ip parent f010: prio 1 \
      u32 match ip src ${localnet} flowid f010:a1
  #	  u32 match ip dst ${devendip}/32 flowid f010:a1
  #	  u32 match ip dst ${devendip} dport ${devendpt} flowid f010:a1
  else
    echo -e "no device endpoint available"
  fi

  echo "---- finished setup_filters ----"
}

# --------------------------------------------------------------------------- #

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
IF=$(get_ifaces)

# check for correctly set up interface
if [ -z "$IF" ]; then
  echo "no (default/active) interfaces detected" >&2
  exit 1
fi

# check prerequisites
echo -e "current (default/active) interfaces: $IF"

# determine 'device_endpoint_url' pointing to Reswarm instance
devendpoint=$(get_device_endpoint)
if [ ! -z "${devendpoint}" ]; then
  devendipdm=$(echo ${devendpoint} | awk -F ':' '{print $1}')
  devendport=$(echo ${devendpoint} | awk -F ':' '{print $2}')
  echo -e "device endpoint url/port:            ${devendipdm}:${devendport}"
  devendip=$(resolve_endpoint ${devendipdm})
  echo -e "resolving endpoint:                  ${devendipdm} -> ${devendip}"
else
  echo -e "no device endpoint available"
fi

reagentpid=$(get_reagent_pid)
if [ ! -z "${reagentpid}" ]; then
  echo -e "PID of main reagent process:         ${reagentpid}"
else
  echo -e "no reagent process detected"
fi

# treat every interface separately
for if in $IF; do

    echo -e "--- configuring interface $if ---"

    # reset all qdiscs, classes, filters...
    clear_tc_rules $if

    # show current tc rules
    echo -e "$(show_tc_rules $if)"

    # set up traffic control
    setup_classes $if
    setup_filters $if

    # show current tc rules
    echo -e "$(show_tc_rules $if)"

done

# set up cgroup
#setup_cgroup

# when using cgroups => add reagent's PID to cgroup tasks (or use 'cgexec' anyway)
#add_task ${reagentpid}

# echo -e "$(show_tc_rules)"

# --------------------------------------------------------------------------- #
