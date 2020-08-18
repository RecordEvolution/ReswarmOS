#!/bin/bash

# create /etc/motd to append stuff to "Message Of The Day"
# adjust /etc/update-motd.d to modify actual welcome message and system info, etc.
#
# e.g. add entire script to /etc/update-motd.d
#
# cat << "EOF" > /etc/updatem-motd.d/01-custom-message
# #!/bin/sh
# echo "GENERAL SYSTEM INFORMATION"
# /usr/bin/screenfetch
# echo
# echo "SYSTEM DISK USAGE"
# export TERM=xterm; inxi -D
# echo
# echo "CURRENT WEATHER AT THE LOCATION"
# # Show weather information. Change the city name to fit your location
# ansiweather -l bratislava
# EOF

# add static message
#
# cat << "EOF" > /etc/motd
# Welcome to mf-os!
# EOF

# put out ascii art of current hostname
cat << "EOF" > /etc/update-motd.d/99-hostname-ascii
#!/bin/bash
EOF

chmod +x /etc/update-motd.d/99-hostname-ascii
