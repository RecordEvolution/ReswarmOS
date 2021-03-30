#!/bin/sh

tc qdisc add dev eth0 root tbf rate 1200kbit latency 50ms burst 1400
