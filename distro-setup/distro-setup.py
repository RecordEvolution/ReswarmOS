# --------------------------------------------------------------------------- #

import yaml

with open('distro-config.yaml','r') as cfgfile :

    distcfg = yaml.load(cfgfile, Loader=yaml.FullLoader)

print(distcfg)


# --------------------------------------------------------------------------- #
