#!/bin/bash

IFS=
echo $(sed -E 's@directory = .*/git@directory = '"$HOME"'/git@g' project/cubic.conf) > project/cubic.conf