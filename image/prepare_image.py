# --------------------------------------------------------------------------- #

import argparse
import yaml
import os
import re
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
    Converts a string representing a data size in any unit to bytes
    Args:
        dataSize: string representing any amount of data in human-readable format
        decbin: if converting to human-readable format: use decimal/binary representation
    Return:
        dataByte: data amount in units of bytes
    """

    # define decimal/binary prefixes
    decPrfx = ['','k','M','G','T','P','E','Z','Y']
    binPrfx = ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi','Yi']

    # ensure argument to be string
    dataSize = str(dataSize)

    # eliminate all digits (and floating point dots)
    dataSizePref = re.sub('[0-9]','',dataSize).replace('.','')

    # define error message
    mess = 'please provide a proper binary prefix instead of ' + str(dataSizePref)
    messA = 'data size is larger than any common prefix'

    print("convertSizeByte: " + str(dataSize))

    # do you want to convert from ...
    #...human-readable to bytes representation...
    if dataSizePref != '' :
        # check for Byte in prefix
        if dataSizePref.find('B') == - 1 :
            raise ValueError(mess)
        else :
            # check for proper predefined prefix
            prefx = dataSizePref.replace('B','')
            # ...decimal prefix
            if prefx in decPrfx :
                expnum = decPrfx.index(prefx)
                # convert to number of Bytes
                return int(dataSize.replace(dataSizePref,''))*1000**expnum
            # ...binary prefix
            elif prefx in binPrfx :
                expnum = binPrfx.index(prefx)
                # convert to number of Bytes
                return int(dataSize.replace(dataSizePref,''))*1024**expnum
            else :
                raise ValueError(mess)
    # ...or vice versa ?
    else :
        # convert string argument to float
        numData = float(dataSize)
        # choose  basis and prefix list
        if decbin :
            basis = 1000.
            prfx = decPrfx
        else :
            basis = 1024.
            prfx = binPrfx
        # get prefix exponent
        expnum = 1
        sizeRep = 9999.9
        while sizeRep > basis :
            sizeRep = numData/(basis**expnum)
            expnum = expnum + 1
            #print(str(basis) + " " + str(expnum) + " " + str(numData) + " " + str(sizeRep))
        # format output
        if expnum > 0 :
            if expnum < len(prfx) :
                return str(sizeRep) + prfx[expnum] + 'B'
            else :
                raise ValueError(messA)
        else :
            return str(numData)

# --------------------------------------------------------------------------- #

if __name__ == "__main__" :

    # show list of arguments
    print("\n" + __file__ + "\n" + str(args) + "\n")

    # open and read configuration
    with open(args.configFile) as fin:
        config = yaml.load(fin, Loader=yaml.FullLoader)

    # check for absolute build path
    try :
        print(os.environ['RESWARMOS'])
    except KeyError as err :
        print(str(err)
            + " please define RESWARMOS environment variable providing"
            + " the absolute path for build directory")
        raise

    # initialize shellcode as string
    shellcode = '#!' + args.shellType + "\n\n"

    # get total size of image ( = sum of boot/ and root/ partition)
    print(config['partitions'])
    print("number of partitions: " + str(len(config['partitions'])))
    totalsize = 0
    for part in config['partitions'] :
        print("size of partition: " + str(part['size']) + " "
                  + str(convertSizeByte(part['size'])) + " "
                  + str(convertSizeByte(str(convertSizeByte(part['size'])),True)) )
        totalsize = totalsize + convertSizeByte(part['size'])
    print("totalsize in Bytes: " + str(totalsize))

    # dump all shell code into script
    with open(args.shellScript,'w') as fout :
        fout.write(shellcode)

# --------------------------------------------------------------------------- #
