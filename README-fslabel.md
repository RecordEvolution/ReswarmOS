
Generated command to generate ext4 filesystem:

output-build/buildroot/output/build/buildroot-fs/ext2/fakeroot

output-build/buildroot/fs/ext2/ext2.mk

# qstrip results in stripping consecutive spaces into a single one. So the
# variable is not qstrip-ed to preserve the integrity of the string value.
ROOTFS_EXT2_LABEL = $(subst ",,$(BR2_TARGET_ROOTFS_EXT2_LABEL))
#" Syntax highlighting... :-/ )

ROOTFS_EXT2_OPTS = \
	-d $(TARGET_DIR) \
	-r $(BR2_TARGET_ROOTFS_EXT2_REV) \
	-N $(BR2_TARGET_ROOTFS_EXT2_INODES) \
	-m $(BR2_TARGET_ROOTFS_EXT2_RESBLKS) \
	-L "$(ROOTFS_EXT2_LABEL)" \
	$(ROOTFS_EXT2_MKFS_OPTS)

fixed in buildroot commit 5ece6be60b8147d05c7c51fd49f64e0140399727
