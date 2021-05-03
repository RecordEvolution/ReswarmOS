# --------------------------------------------------------------------------- #

import yaml
import argparse
import os
from os import path

parser = argparse.ArgumentParser(description='Prepare ReswarmOS configuration')
parser.add_argument('distro_setup_dir',type=str,help='distribution setup/configuration directory')
parser.add_argument('buildroot_config_dir',type=str,help='base directory of available buildroot configurations')
parser.add_argument('buildroot_dir',type=str,help='buildroot base directory')
args = parser.parse_args()

print('\nargs: ' + str(args))

# read the ReswarmOS distribution configuration file
distrocfg = os.path.join(args.distro_setup_dir,'distro-config.yaml')
with open(distrocfg,'r') as cfgfile :
    distcfg = yaml.load(cfgfile, Loader=yaml.FullLoader)
print('\ndistribution configuration\n' + str(yaml.dump(distcfg)))

# find path of required buildroot configuration file
bldcfg = os.path.join(args.buildroot_config_dir,distcfg['model'],distcfg['config'])
print('\nbuildroot configuration\n' + str(bldcfg))
if not os.path.isfile(bldcfg) :
    raise RuntimeError("required buildroot configuration file '" + str(bldcfg) 
                       + "' does not exist! please check your distro-config.yaml")

# read buildroot configuration file and convert to list 
with open(bldcfg,'r') as cfgfl :
    bldcfgraw = cfgfl.read()
bldcfglist = bldcfgraw.split('\n')

# perform configuration
#
#

keycfg = 'BR2_TARGET_GENERIC_HOSTNAME'
keycfgsub = keycfg + str('="') + distcfg['hostname'] + str('"')
bldcfglist = [keycfgsub if keycfg in el else el for el in bldcfglist]
print('\n' + keycfgsub + '\n')

#idx = 0
#fidx = 0
#for el in bldcfglist :
#    if keycfg in el :
#        fidx = idx
#    idx = idx + 1
#print(bldcfglist[fidx])

keycfg = 'BR2_TARGET_GENERIC_ISSUE'
keycfgsub = ( keycfg + str('="Welcome to ') + str(distcfg['os-name']) 
                     + str(' v') + str(distcfg['version']) + str('"') )
bldcfglist = [keycfgsub if keycfg in el else el for el in bldcfglist]
print('\n' + keycfgsub + '\n')

keycfg = 'BR2_ROOTFS_USERS_TABLES'
usertable = "/home/distro-setup/root-user"
keycfgsub = keycfg + str('="') + usertable + str('"')
bldcfglist = [keycfgsub if keycfg in el else el for el in bldcfglist]
print('\n' + keycfgsub + '\n')

# reassemble buildroot configuration file form list
bldcfgreraw = ('\n').join(bldcfglist)
#print(bldcfgreraw)

# generate makeuser file for required root user
usrname = distcfg['root-user']['username']
passwrd = distcfg['root-user']['password']
#         username    uid     group     gid       password              
makeusr = ( usrname + ' -1 ' + usrname + ' -1 ' + '=' + passwrd 
#                  home            shell       groups  comment
         + ' /home/' + usrname + ' /bin/sh' + ' sudo' + ' ' )
print("makeuser entry\n" + str(makeusr))
with open(usertable,'w') as fuser :
    fuser.write(makeusr)


# write buildroot configuration to buildroot base directory
bldcfgfile = os.path.join(args.buildroot_dir,".config")
print('\nwriting buildroot configuration in\n' + bldcfgfile)
with open(bldcfgfile,'w') as fcfg :
    fcfg.write(bldcfgreraw)

## retrieve path of post-build script for buildroot
#postbuildscript = "BR2_ROOTFS_POST_BUILD_SCRIPT"
#with open(args.buildrootcfg,'r') as bldrtfile :
#    buildrootcfg = bldrtfile.read()
#try :
#    pstbld = [el.split('=')[1].replace('"','') for el in buildrootcfg.split('\n') if postbuildscript in el]
#except RuntimeError as err :
#    raise RunTimeError("failed to extract post-build script path from buildroot configuration: " + str(err))
#pstbld = os.path.join(args.buildrootdir,pstbld[0])
#
#print("path of post-build script\n" + str(pstbld) + "\n"
#                   + str(os.path.abspath(pstbld)) + "\n")
#
#diststp = os.path.abspath(args.distrodir)
#print("absolute path of dist-setup\n" + str(diststp) + "\n")
#print("relative path of dist-setup w.r.t. post-build script\n" + str(os.path.relpath(args.distrodir,start=pstbld)) + "\n")
#
## open post-build script and add required stuff
#with open (pstbld,'a') as scrfile :
#    scrfile.write('\n\n\n\nsome new command\n')

# --------------------------------------------------------------------------- #
