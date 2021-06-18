
# U-boot utils
uboot-utils:
	apt-get install u-boot-tools

# generate u-boot boadloader script
mkimage: boot.txt
	mkimage -A arm64 -O linux -T script -C none -d $< boot.scr.uimg
