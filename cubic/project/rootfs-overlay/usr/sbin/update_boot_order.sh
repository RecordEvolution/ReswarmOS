#!/bin/bash

current_boot_order=$(efibootmgr | sed -n 3p | cut -d ' ' -f 2)
installed_os_boot_order=$(efibootmgr -v | grep ubuntu | grep -oP 'Boot(00..)' | sed 's/Boot//g')

new_boot_order="$installed_os_boot_order"
for entry in $(echo $current_boot_order | sed "s/,/ /g")
do
    if [ "$entry" != "$installed_os_boot_order" ]; then
       new_boot_order="$new_boot_order,$entry"
    fi
done

efibootmgr -o $new_boot_order