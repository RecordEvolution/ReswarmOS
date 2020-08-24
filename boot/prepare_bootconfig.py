# --------------------------------------------------------------------------- #

import argparse
import yaml
import os
import re
import math

parser = argparse.ArgumentParser(description='Produce shell script for building the boot partition')
parser.add_argument('--configFile',type=str,help='name and path of configuration file',
                    default='./distro-config.yaml')
parser.add_argument('--firmwareRepo',type=str,help='url of firmware repository',
                    default='https://github.com/raspberrypi/firmware.git')
parser.add_argument('--shellScript',type=str,help='name and path of shell script to be written',
                    default='boot/build_boot.sh')
parser.add_argument('--shellType',type=str,help='name and path of shell to be used',
                    default='/bin/bash')
args = parser.parse_args()

# --------------------------------------------------------------------------- #


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


    # dump all shell code into script
    with open(args.shellScript,'w') as fout :
        fout.write(shellcode)

# --------------------------------------------------------------------------- #
