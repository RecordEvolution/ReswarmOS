#!/bin/bash

useScripts="04-install-packages.sh\
            05-rootfs-install.sh\
            06-manage-users.sh\
            07-customize-motd.sh\
            08-network-config.sh\
            09-reagent-reswarm.sh"
finalScript="setup-reswarm-device.sh"

echo "#!/bin/bash" > "${finalScript}"

for scrp in ${useScripts}; do
	echo -e "\n# ${scrp}\n" >> "${finalScript}"
	cat "${scrp}" | grep -v "^#\|logging\|^ *$" >> "${finalScript}"
	echo -e "\n" >> "${finalScript}"
done

