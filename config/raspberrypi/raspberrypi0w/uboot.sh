
# show board and flash info 
bdinfo
flinfo

# load device-tree and kernel
fatload mmc 0:1 ${fdt_addr_r} bcm2708-rpi-zero-w.dtb
fatload mmc 0:1 ${kernel_addr_r} uImage

# set boot arguments corresponding to cmdline.txt
setenv bootargs root=/dev/mmcblk0p2 rootfstype=ext4 rootwait rw console=tty1 console=ttyAMA0,115200 cgroup_enable=cpuset cgroup_enable=memory swapaccount=1 fsck.repair=yes dwc_otg.lpm_enable=0

# RAUC 
setenv BOOT_ORDER "rootfs0 rootfs1"
setenv BOOT_rootfs0_LEFT 3
setenv BOOT_rootfs1_LEFT 3

# save environment variables
saveenv

# boot kernel (and device-tree)
bootm ${kernel_addr_r} - ${fdt_addr_r}
