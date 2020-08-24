# --------------------------------------------------------------------------- #

import argparse
import yaml
import os
import re
import math
import platform

parser = argparse.ArgumentParser(description='Produce shell script for building a cross compiler')
parser.add_argument('--configFile',type=str,help='name and path of configuration file',
                    default='./distro-config.yaml')
parser.add_argument('--shellScript',type=str,help='name and path of shell script to be written',
                    default='boot/prepare_root_filesystem.sh')
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
        raise KeyError( str(err)
                    + " please define RESWARMOS environment variable providing"
                    + " the absolute path for build directory" )

    # initialize shellcode as string and include logging
    shellcode = ( '#!' + args.shellType + "\n"
                + "# generated by '" + str(__file__) + "'\n\n"
                + "source log/logging.sh\n\n" )

    # check if cross compiler is required by comparing
    # ... required architecture
    reqarch = config['architecture']
    # ...actual architecture
    curarch = platform.machine()

    print('\nrequired machine architecture: ' + str(reqarch) + '\n'
          + 'current machine architecture:  ' + str(curarch) + '\n')

    # compare required and current architecture
    if reqarch != curarch :

        shellcode = shellcode + "logging_message \"building cross-compiler\"\n\n"
        shellcode = ( shellcode + '# building cross-compiler\n' + '\n\n' )

    else :

        print('\nno need for any cross-compiler\n')
        shellcode = shellcode + "logging_message \"no need for cross-compiler\"\n\n"

    # dump all shell code into script
    with open(args.shellScript,'w') as fout :
        fout.write(shellcode)

# --------------------------------------------------------------------------- #
