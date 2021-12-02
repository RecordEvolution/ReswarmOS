#-----------------------------------------------------------------------------#
#
# U-boot script for RasberryPi4
#
# (default) memory layout:
#
#   - kernel_add_r = 0x 0008 0000
#   - fdt_addr_r   = 0x 0260 0000
#
#   - boot_params  = 0x 0000 0100
#   - DRAM start   = 0x 0000 0000
#          size    = 0x 039c 0000
#          start   = 0x 4000 0000
#          size    = 0x bc00 0000
#   - fdt_blob     = 0x 3975 b4c0
#   - fdt_size     = 0x 0000 c9c0
#
# use "$ md 0x yyyy zzzz" to inspect memory
#
# References:
# - https://u-boot.readthedocs.io/en/latest/index.html
# - https://u-boot.readthedocs.io/en/latest/usage/fdt_overlays.html#manually-loading-and-applying-overlays
# - https://rauc.readthedocs.io/en/latest/integration.html#set-up-u-boot-boot-script-for-rauc
# - https://u-boot.readthedocs.io/en/latest/usage/fdt_overlays.html
# - https://dius.com.au/2015/08/19/raspberry-pi-u-boot/
# - https://irq5.io/2018/07/24/boot-time-device-tree-overlays-with-u-boot/
#
#-----------------------------------------------------------------------------#

# show board and FAT partition info
bdinfo
fatinfo mmc 0:1

# list files in FAT partition
ls mmc 0:1 /

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

# manage ftd address and size for overlays
fdt addr ${fdt_addr_r}
fdt resize 16384       # make sure all overlays to be loaded are covered!!

# load overlay device-tree(s)
echo "load device-tree overlay"
setexpr fdtovaddr ${fdt_addr_r} + C0000
# setenv fdtovaddr 0x87fc0000
echo "fdtovaddr:" ${fdtovaddr}

fatload mmc 0:1 ${fdtovaddr} overlays/w1-gpio.dtbo    # 1036 bytes
fdt apply ${fdtovaddr}
fatload mmc 0:1 ${fdtovaddr} overlays/rpi-sense.dtbo  # 893 bytes
fdt apply ${fdtovaddr}
fatload mmc 0:1 ${fdtovaddr} overlays/mcp2515-can0.dtbo # 1793 bytes
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

