#!/bin/sh

# put in /etc/profile.d/ and set $ chmod 644

# configuration bash shell prompt (for all users)

# References:
# https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html
# https://wiki.archlinux.org/index.php/Bash/Prompt_customizationw
# http://www.linuxfromscratch.org/blfs/view/svn/postlfs/profile.html
# https://man.archlinux.org/man/bash.1#PROMPTING
# https://stackoverflow.com/questions/14220848/break-line-in-terminal-ps1-fix

#export PS2="continue-> "
export PS1='\[\e[32m\]\u\[\e[31m\]@\[\e[34m\]\h\[\e[31m\]:\[\e[33m\]\w\[\e[31m\]\$\[\e[39m \]'
