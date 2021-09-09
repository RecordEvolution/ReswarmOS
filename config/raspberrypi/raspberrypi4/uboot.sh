
# show board and flash info 
bdinfo
flinfo

# check for RAUC variables and evtl. initialize
test -n "${BOOT_ORDER}" || setenv BOOT_ORDER "rootfsA rootfsB"
test -n "${BOOT_rootfsA_LEFT}" || setenv BOOT_rootfsA_LEFT 3
test -n "${BOOT_rootfsB_LEFT}" || setenv BOOT_rootfsB_LEFT 3

# load device-tree and kernel
fatload mmc 0:1 ${fdt_addr_r} bcm2711-rpi-4-b.dtb
fatload mmc 0:1 ${kernel_addr_r} uImage

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

