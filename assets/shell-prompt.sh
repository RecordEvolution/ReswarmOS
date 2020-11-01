#!/bin/sh

# put in /etc/profile.d/ and set $ chmod 644

# overwrite configuration user shell prompt configuration (for all users)
export PS1='\e[32m\u\e[31m@\e[34m\h\e[31m:\e[33m\w\e[31m\$\e[39m '

