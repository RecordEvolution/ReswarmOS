#!/bin/bash

ls package/ | grep docker | while read f; do cat package/$f/Config.in | grep "config BR2_PACKAGE" -m1 | awk '{print $2"=y"}'; done;
