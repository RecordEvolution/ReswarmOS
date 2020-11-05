# --------------------------------------------------------------------------- #

import yaml
import json
import argparse

parser = argparse.ArgumentParser(description='Parse *.reswarm and prepare configuration files for management agent')
parser.add_argument('reswarmfile',type=str,help='path/file of *.reswarm file')
parser.add_argument('devicecfg',type=str,help='output path/file for device-config.yaml')
parser.add_argument('clientkey',type=str,help='output path/file of client.key.pem')
parser.add_argument('clientcert',type=str,help='output path/file of client.cert.pem')
parser.add_argument('devicesetup',type=str,help='output path/file of device-config.ini')
args = parser.parse_args()

if __name__ == "__main__" :

    # parse .reswarm file
    print('reading *.reswarm configuration file ' + str(args.reswarmfile))
    
    with open(args.reswarmfile, "r") as cfgfile:
        data = json.load(cfgfile)

    # filter all elements but authentication dict and write to .yaml file
    devicecfg = { key:value for (key,value) in data.items() if ( key != "authentication" and key != "config_passphrase" )}

    print('writing device configuration to ' + str(args.devicecfg))
    with open(args.devicecfg,"w") as devfile:
        devfile.write(yaml.dump(devicecfg,sort_keys=True,indent=4,
                                explicit_start=True,explicit_end=True,
                                default_flow_style=False))

    # extract authentication dict and write key and cert to separate files
    authenticationcfg = data["authentication"]

    print('writing private key to ' + str(args.clientkey))
    with open(args.clientkey,"w") as keyfile:
        keyfile.write(authenticationcfg['key'])
    
    print('writing certificate to ' + str(args.clientcert))
    with open(args.clientcert,"w") as certfile:
        certfile.write(authenticationcfg['certificate'])

    print('generating and writing device-config.ini to ' + str(args.devicesetup))
    devicesetupcnt = ""
    devicesetupcnt = ( devicesetupcnt + "\n[device]\n"
                                      + "HOSTNAME = \"" + str(devicecfg['name']) + "\"\n\n" 
                                      + "[user]\n"  
                                      + "USER     = \"" + str(devicecfg['swarm_owner_name']) + "\"\n"
                                      + "PASSWD   = \"" + str(devicecfg['secret']) + "\"\n"
                                      + "HOME     = \"" + "/home/" + str(devicecfg['swarm_owner_name']) + "\"\n\n"
                                      + "[wifi]\n"
                                      + "SSID     = \"" + str(devicecfg['wlanssid']) + "\"\n"
                                      + "PASSWD   = \"" + str(devicecfg['password']) + "\"\n\n" )

    with open(args.devicesetup,"w") as stpfile:
        stpfile.write(devicesetupcnt)

# --------------------------------------------------------------------------- #

