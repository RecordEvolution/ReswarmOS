# --------------------------------------------------------------------------- #

import argparse
import yaml
import os
import re
import math
# import convert_ddl as convddl
# with function dox() defined in convert_ddl.py use convddl.dox()

parser = argparse.ArgumentParser(description='Produce shell script for image generation')
parser.add_argument('--configFile',type=str,help='name and path of configuration file',
                    default='./distro-config.yaml')
parser.add_argument('--shellScript',type=str,help='name and path of shell script to be written',
                    default='image/produce-image.sh')
parser.add_argument('--shellType',type=str,help='name and path of shell to be used',
                    default='/bin/bash')
args = parser.parse_args()

# --------------------------------------------------------------------------- #

def convertSizeByte(dataSize, decbin = True) :
    """
    Converts a string representing a data size in any data unit to bytes
    or vice versa a number of bytes to the simplest representation with prefix
    Args:
        dataSize: string representing any amount of data in human-readable format
        decbin: if converting to human-readable format: use decimal/binary representation
    Return:
        dataByte: data amount in units of bytes
    """

    # define decimal/binary prefixes
    decPrfx = ['','k','M','G','T','P','E','Z','Y']
    binPrfx = ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi','Yi']

    # ensure argument type to be string
    dataSize = str(dataSize)

    # eliminate all digits (and any left-over floating point dots) to obtain prefix
    dataSizePref = re.sub('[0-9]','',dataSize).replace('.','')

    # define error message
    mess = 'please provide a proper binary prefix instead of ' + str(dataSizePref)
    messA = 'data size is larger than any common prefix'

    # print("convertSizeByte: " + str(dataSize) + " " + str(decbin) + " " + str(dataSizePref))

    # choose  basis and prefix list
    basis = 1000. if decbin else 1024.
    prfx = decPrfx if decbin else binPrfx

    # do you want to convert from ...
    #...human-readable to bytes representation...
    if dataSizePref != '' :
        # check for Byte in prefix
        if dataSizePref.find('B') == - 1 :
            raise ValueError(mess)
        else :
            # check for proper predefined prefix
            prefx = dataSizePref.replace('B','')
            if prefx in decPrfx :
                expnum = decPrfx.index(prefx)
                return float(dataSize.replace(dataSizePref,''))*1000.**expnum
            elif prefx in binPrfx :
                expnum = binPrfx.index(prefx)
                return float(dataSize.replace(dataSizePref,''))*1024.**expnum
            else :
                raise ValueError(mess)
    # ...or vice versa ?
    else :
        # convert string argument to float
        numData = float(dataSize)
        # get prefix exponent
        expnum = math.floor(math.log(numData,basis))
        # actual data size in human-readable representation
        sizeRep = numData/(basis**expnum)
        # print(str(basis) + " " + str(expnum) + " " + str(numData) + " " + str(sizeRep))
        # format output
        if expnum > 0 :
            if expnum < len(prfx) :
                return str(sizeRep) + prfx[expnum] + 'B'
            else :
                raise ValueError(messA)
        else :
            return numData
            # return str(numData ) + 'B'

# --------------------------------------------------------------------------- #

if __name__ == "__main__" :

    # show list of arguments
    print("\n" + __file__ + "\n" + str(args) + "\n")

    # open and read configuration
    with open(args.configFile) as fin:
        config = yaml.load(fin, Loader=yaml.FullLoader)

    # check for absolute build path
    try :
        print('environment variable "RESWARMOS" = ' + os.environ['RESWARMOS'] + '\n')
        buildir = os.environ['RESWARMOS']
    except KeyError as err :
        print(str(err)
            + " please define RESWARMOS environment variable providing"
            + " the absolute path for build directory")
        raise

    # initialize shellcode as string and include logging
    shellcode = ( '#!' + args.shellType + "\n"
                + "# generated by '" + str(__file__) + "'\n\n"
                + "source log/logging.sh\n\n" )

    # get alignment offset of first partition (1MiB/4MiB are recommended)
    offset = convertSizeByte(config['alignment-offset'])

    # get total size of image ( = sum of all partitions defined in config)
    print(config['partitions'])
    print("number of partitions: " + str(len(config['partitions'])) + '\n')
    # ...initialize with alignment offset of first partition
    totalsize = offset
    # ...add size of every single partition
    for part in config['partitions'] :
        print("size of partition: " + str(part['size']) + " "
                  + str(convertSizeByte(part['size'],True)) )
        totalsize = totalsize + convertSizeByte(part['size'])
    print("totalsize in Bytes: " + str(totalsize))

    # convert to MiB representation
    totalsizeMiB = int(float(totalsize)/(1024.**2))

    # check overall image size
    if totalsizeMiB > 5000.0 :
        raise ValueError("pretty sure you do not want an image that large -> "
                         + str(totalsizeMiB) + "MiB !!")

    # add logging
    shellcode = shellcode + "logging_message \"creating image file\"\n\n"

    # create image file
    # ...construct full/absolute path
    imgfile = config['os-name'] + "_" + str(config['version']) + ".img"
    imgname = os.path.join(buildir,imgfile)
    # ...write image using 'dd' (accepts both 'MB' = 1000*1000 and 'M' = 1024*1024)
    shellcode = ( shellcode + "# create image file of appropriate total size\n"
                            + "dd if=/dev/zero of=" + imgname + " bs=1M"
                            + " count=" + str(totalsizeMiB) + "\n\n" )
    # ...check image and its size
    shellcode = ( shellcode + "# check image path and size\n"
                            + "ls -lh " + str(imgname) + "\n\n" )

    # prepare loopback device
    shellcode = shellcode + "logging_message \"prepare loopback device\"\n\n"
    # ... find next unused loopback device
    shellcode = ( shellcode + "# find next unused loopback device\n"
                            + "devName=$(losetup -f) \n\n" )
    # ... set it up
    shellcode = ( shellcode + "# set up loopback device with image file\n"
                            + "losetup -fP " + str(imgname) + "\n\n" )
    # ...check it
    shellcode = ( shellcode + "# check new loopback device\n"
                            + "losetup -a \n"
                            + "losetup -l ${devName}\n\n" )

    # create disk label
    shellcode = shellcode + "logging_message \"set disk label\"\n\n"
    shellcode = ( shellcode + "# create disk label\n"
                            + "parted ${devName} --script mklabel msdos \n\n" )

    # find supported fileystem by
    # $ ls /usr/sbin/ | grep mkfs | grep '\.' | awk -F '.' '{print $2}'

    # create and format partitions
    shellcode = shellcode + "logging_message \"create partitions and filesystems\"\n\n"
    shellcode = shellcode + "# create partitions and employ required filesystems\n"

    # for all required partitions
    # ...check if any partition is defined at all
    if len(config['partitions']) :

        # count partitions
        pcount = 0

        for part in config['partitions'] :

            # get partition size in Byte
            partSize = convertSizeByte(part['size'])

            # create partition (provide fstype and start/end of partition in Bytes)
            shellcode = ( shellcode + "logging_message \"create partition "
                                    + str(pcount+1) + " : " + str(part['name'])
                                    + "\"\n\n" )
            shellcode = ( shellcode + "parted ${devName} --script mkpart primary "
                                    + str(part['fstype']) + " "
                                    + str(int(offset)) + "B" + " "
                                    + str(int(offset+partSize-1)) + "B\n\n" )

            # keep track of absolute offset
            offset = offset + partSize

            # count partitions
            pcount = pcount + 1

            # set name of partition (only works for gpt disklabels)
            # sudo parted /dev/loop7 name 2 RESWARMOS
            # format partition with required filesystem

            # check for FATX filesystem and evtl. set fat-size
            fstype = 'fat' if 'fat' in part['fstype'] else part['fstype']
            fsopt = ' -F ' + part['fstype'].replace('fat','') if fstype == 'fat' else ''

            # make filesystem and format partition
            shellcode = shellcode + "logging_message \"format partition\"\n\n"
            shellcode = ( shellcode + "mkfs." + fstype + fsopt
                                    + " ${devName}p" + str(pcount) + "\n\n" )

            # for both /boot and /root partitions
            if part['label'] == "boot" or part['label'] == "root" :

                # mount partition
                shellcode = shellcode + "logging_message \"mount partition\"\n\n"
                # ...define mountpoint
                mntpnt = "/mnt/" + str(part['name'])
                # ...perform mount
                shellcode = ( shellcode + "# mount partition\n"
                                        + "mkdir -v " + mntpnt + "\n"
                                        + "mount -o loop ${devName}p" + str(pcount)
                                        + " " + mntpnt + "\n\n" )

                # ...populate partition with files
                shellcode = shellcode + "logging_message \"populate partition\"\n\n"
                # ...path of readily built boot/, root/ partition
                bldpath = os.path.join(buildir,part['name'])
                # ...copy files recursively
                shellcode = ( shellcode + "# copy files\n"
                                        + "cp -rv " + bldpath
                                        + " " + mntpnt + "\n\n" )

                # ...unmount partition
                shellcode = shellcode + "logging_message \"unmount partition\"\n\n"
                shellcode = ( shellcode + "# unmount partition\n"
                                        + "umount ${devName}p" + str(pcount) + "\n\n" )

        shellcode = shellcode + "\n"
    else :
        raise ValueError("configuration does not define any partitions")

    # check resulting partitions (table)
    shellcode = shellcode + "logging_message \"check partitions\"\n\n"
    shellcode = ( shellcode + "# check partitions\n"
                            + "parted ${devName} print\n\n" )
    # check further into
    # sudo file /dev/loop7 -s

    # detach loopback device
    shellcode = shellcode + "logging_message \"detach loopback device\"\n\n"
    shellcode = ( shellcode + "# detach loopback device\n"
                            + "losetup -d ${devName}\n\n" )

    # dump all shell code into script
    with open(args.shellScript,'w') as fout :
        fout.write(shellcode)

# --------------------------------------------------------------------------- #
