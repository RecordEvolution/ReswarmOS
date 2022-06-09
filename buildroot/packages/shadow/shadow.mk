################################################################################
#
# shadow
#
################################################################################

SHADOW_VERSION = 4.9
SHADOW_SOURCE = shadow-$(SHADOW_VERSION).tar.gz
SHADOW_SITE = https://github.com/shadow-maint/shadow/releases/download/v$(SHADOW_VERSION)
SHADOW_LICENSE = 
SHADOW_LICENSE_FILES = 
SHADOW_CONF_OPTS = 
SHADOW_DEPENDENCIES = 

$(eval $(autotools-package))
