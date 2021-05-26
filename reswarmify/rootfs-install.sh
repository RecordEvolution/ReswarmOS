#!/bin/bash

source logging.sh

# 1st argument: root filesystem mount point
rootfsmntpnt="$1" # = "/" when installing rootfs overlay on a running system

if [ -z "${rootfsmntpnt}" ]; then
  logging_error "rootfs_install.sh: missing argument 'rootfsmntpnt'"
  exit 1
fi

if [ ! -d ./rootfs/ ]; then
  logging_error "rootfs_install.sh: ./rootfs directory not found"
  exit 1
fi

#-----------------------------------------------------------------------------#

logging_header "install root filesystem overlay"

logging_message "rootfs mount point: ${rootfsmntpnt}"

# list rootfs overlay files
rootfsfiles=$(find rootfs/ -name "*" -type f)

logging_message "list of files in ./rootfs"
echo "${rootfsfiles}"

# install every single file
logging_message "employing ./rootfs overlay"
for fl in ${rootfsfiles}; do

  # strip base path in repository and compose full path in mount point of rootfs
  rootfsfl=$(echo ${fl} | sed 's/^rootfs//g')
  rootfsflpath=$(echo "${rootfsmntpnt}${rootfsfl}" | sed 's/\/\//\//g')
  
  echo "${fl} -> ${rootfsflpath}"
  
  # check for existing files
  if [ -f ${rootfsflpath} ]; then

    logging_error "file ${rootfsfl} is already present in ${rootfsflpath}, ignoring it"
  
  else

    # check directory name first
    rootfsfldir=$(dirname ${rootfsflpath})
    if [ ! -d ${rootfsfldir} ]; then
      echo "required directory ${rootfsfldir} does not exist, creating it"
      mkdir -pv ${rootfsfldir}
    fi

    # add file to root filesystem
    cp -v ${fl} ${rootfsflpath}
    
    # deal with systemd units
    if [ ! -z "$(echo ${fl} | grep "\.service$")" ] || [ ! -z "$(echo ${fl} | grep "\.socket$")" ] \
       || [ ! -z "$(echo ${fl} | grep "\.path$")" ] || [ ! -z "$(echo ${fl} | grep "\.timer$")" ]; then

      # basefile name
      unitfl=$(basename ${fl})
      echo "${fl} = ${unitfl} is systemd unit"
    
      # extract target
      unittarget=$(cat ${fl} | grep "[Install]" -A 400 | grep "^WantedBy=\|^RequiredBy=" \
        | sed 's/WantedBy=//g' | sed 's/RequiredBy=//g' | sed 's/^ *//g' | sed 's/ *$//g')
      if [ -z "${unittarget}" ]; then

        echo "no install target given, not going to enable it"

      else

        # compose clean absolute install path of systemd unit file
        unitpath=$(echo ${rootfsmntpnt}/etc/systemd/system/${unittarget}.wants/${unitfl} | sed 's/\/\//\//g')

        echo "enabling for target ${unittarget}"
	if [ "${rootfsmntpnt}" == "/" ]; then

	  # enable service and check status
	  systemctl enable ${unitfl}
	  systemctl status ${unitfl} | cat
	
        else

	  # create symlink and check it
          ln -s ${rootfsfl} ${unitpath}
          ls -lh ${unitpath}

	fi

      fi
    fi
  fi 
done

sleep 2

#-----------------------------------------------------------------------------#
