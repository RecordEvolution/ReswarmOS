
# U-boot utils
uboot-utils:
	apt-get install u-boot-tools

# generate u-boot boadloader script
# naming convention allows for both "boot.scr" and "boot.scr.uimg"
mkimage-arm64: boot.txt
	#mkimage -A arm64 -O linux -T script -C none -d $< boot.scr.uimg
	mkimage -A arm64 -O linux -T script -C none -d $< boot.scr

mkimage-arm: boot.txt
	#mkimage -A arm -O linux -T script -C none -d $< boot.scr.uimg
	mkimage -A arm -O linux -T script -C none -d $< boot.scr

# convert kernel
mkimage-kernel:
	mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux kernel" -d zImage uImage

