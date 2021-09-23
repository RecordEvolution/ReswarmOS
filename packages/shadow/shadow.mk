################################################################################
#
# shadow
#
################################################################################

SHADOW_VERSION = 4.9
SHADOW_SOURCE = shadow$(subst .,,$(SHADOW_VERSION)).tgz
SHADOW_SITE = https://github.com/shadow-maint/shadow
SHADOW_LICENSE = 
SHADOW_LICENSE_FILES = 
SHADOW_DEPENDENCIES = 

define SHADOW_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		XLIBPATH=$(STAGING_DIR)/usr/lib
endef

define SHADOW_INSTALL_TARGET_CMDS
	$(TARGET_CONFIGURE_OPTS) $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		XLIBPATH=$(STAGING_DIR)/usr/lib PREFIX=$(TARGET_DIR)/usr install
endef

$(eval $(generic-package))
