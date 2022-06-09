#!/bin/bash

# assuming an 32GB internal emmc
blockSize=16777216
countBlocks=1864

dd if=/dev/mmcblk0 of=/dev/mmcblk1 bs=${blockSize} count=${countBlocks} status=progress

