#!/bin/bash

# perform build process through user 'clfs' (associated to group 'clfs')
sudo groupadd clfs
sudo useradd -s /bin/bash -g clfs -m -k /dev/null clfs

# setup password for new user
sudo passwd clfs

# grant 'clfs' user to have full access to 'CLFS' directory
sudo chown -Rv clfs ${CLFS}

# setup the environment of user 'clfs'
#...TODO

# change to user 'clfs'
#su - clfs

# finally remove building user and its group
#userdel -r clfs
#groupdel clfs
