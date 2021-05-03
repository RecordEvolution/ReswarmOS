#!/bin/bash

pwd

ls
echo ""
ls gcc-build

echo "create file with some arbitrary content" > gcc-build/test-file.log

ls
echo ""
ls gcc-build

echo ""

cat gcc-build/test-file.log

echo ""

sleep 1
