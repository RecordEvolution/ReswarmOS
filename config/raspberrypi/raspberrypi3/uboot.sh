#
# for reference:
# https://rauc.readthedocs.io/en/latest/integration.html#set-up-u-boot-boot-script-for-rauc
#

# show board and flash info 
bdinfo
#flinfo

# check for RAUC variables and evtl. initialize
test -n "${BOOT_ORDER}" || setenv BOOT_ORDER "rootfsA rootfsB"
test -n "${BOOT_rootfsA_LEFT}" || setenv BOOT_rootfsA_LEFT 3
test -n "${BOOT_rootfsB_LEFT}" || setenv BOOT_rootfsB_LEFT 3

# load kernel
echo "load kernel"
echo "kernel_addr_r:" ${kernel_addr_r}
fatload mmc 0:1 ${kernel_addr_r} uImage

# load base device-tree
echo "load base device-tree"
#setenv fdt_addr_r 0x87f00000
echo "fdt_addr_r:" ${fdt_addr_r}
echo "fdt_file:" ${fdt_file}
fatload mmc 0:1 ${fdt_addr_r} bcm2710-rpi-3-b.dtb

# load overlay device-tree
echo "load device-tree overlay"
setexpr fdtovaddr ${fdt_addr_r} + C0000
#setenv fdtovaddr 0x87fc0000
echo "fdtovaddr:" ${fdtovaddr}
fatload mmc 0:1 ${fdtovaddr} overlays/w1-gpio.dtbo

# manage ftd address and size
fdt addr ${fdt_addr_r}
fdt resize 8192
#setexpr fdtovaddr ${fdt_addr_r} + F000
fdt apply ${fdtovaddr}

#setenv OVLDTB "w1-gpio" 
#echo "OVLDTB:" ${OVLDTB}
#for ov in ${OVLDTB}; do
#  echo overlaying ${ov} ...
#  fatload mmc 0:1 ${fdtovaddr} overlays/${ov}.dtbo && fdt apply ${fdtovaddr}
#done

# reset/empty bootargs variable and check all slots
setenv bootargs
for BOOT_SLOT in "${BOOT_ORDER}"; do
  # as soon as bootargs is defined => skip remaining slots
  if test "x${bootargs}" != "x"; then
    # just skip the remaining slots...
  elif test "x${BOOT_SLOT}" = "xrootfsA"; then
    if test ${BOOT_rootfsA_LEFT} -gt 0; then
      echo "found valid slot rootfsA, ${BOOT_rootfsA_LEFT} attempts remaining"
      # decrease number of remaining attempts by one
      setexpr BOOT_rootfsA_LEFT ${BOOT_rootfsA_LEFT} - 1
      # adjust kernel arguments according to cmdline.txt and required boot partition
      setenv bootargs root=/dev/mmcblk0p2 rootfstype=ext4 rauc.slot=rootfsA rootwait rw console=tty1 console=ttyAMA0,115200 cgroup_enable=cpuset cgroup_enable=memory swapaccount=1 fsck.repair=yes dwc_otg.lpm_enable=0
      #setenv bootargs "${default_bootargs} root=/dev/mmcblk0p1 rauc.slot=A"
    fi
  elif test "x${BOOT_SLOT}" = "xrootfsB"; then
    if test ${BOOT_rootfsB_LEFT} -gt 0; then
      echo "found valid slot rootfsB, ${BOOT_rootfsB_LEFT} attempts remaining"
      setexpr BOOT_rootfsB_LEFT ${BOOT_rootfsB_LEFT} - 1
      setenv bootargs root=/dev/mmcblk0p3 rootfstype=ext4 rauc.slot=rootfsB rootwait rw console=tty1 console=ttyAMA0,115200 cgroup_enable=cpuset cgroup_enable=memory swapaccount=1 fsck.repair=yes dwc_otg.lpm_enable=0
    fi
  fi
done

# save environment variables
if test -n "${bootargs}"; then
  saveenv
else
  echo "no valid slot found, resetting attempts to 3 for both slots"
  setenv BOOT_rootfsA_LEFT 3
  setenv BOOT_rootfsB_LEFT 3
  saveenv
  reset
fi

# boot kernel (and device-tree)
echo "starting kernel"
bootm ${kernel_addr_r} - ${fdt_addr_r}

