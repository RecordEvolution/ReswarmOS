#-----------------------------------------------------------------------------#

import json
import argparse
import os
import datetime
import yaml
import re
import hashlib

parser = argparse.ArgumentParser(description='Update list of supported boards and their latest images')
parser.add_argument('setupFile',type=str,help='ReswarmOS setup.yaml file')
parser.add_argument('boardsFile',type=str,help='path to supported boards JSON file')
parser.add_argument('--timeFormat',type=str,default='%Y-%m-%dT%H:%M:%S',help='timestamp format')
parser.add_argument('--boardSchema',type=str,default='{"latestUpdate":"","boards":[{"board":"","boardname":"","model":"","modelname":"","architecture":"","cpu":"","latestImage":{"file":"","sha256":"","buildtime":""}}]}',help='JSON schema of board/image list')
parser.add_argument('--baseURL',type=str,default='https://storage.googleapis.com/reswarmos/',help='public base URL of images')
parser.add_argument('--newFile',type=str,default=None,help='different output file')

args = parser.parse_args()
print('CLI arguments:\n'+json.dumps(vars(args),indent=4)+'\n')

# parse ReswarmOS's setup.yaml
with open(args.setupFile,'r') as fin :
    try :
        setupConfig = yaml.safe_load(fin)
    except yaml.YAMLError as err :
        raise RuntimeError('failed to read setup.yaml: '+str(err))
print('ReswarmOS setup:\n'+json.dumps(setupConfig,indent=4)+'\n')

# read buildroot configuration
with open(os.path.join('config',setupConfig['board'],setupConfig['model'],'config')) as fin :
    buildConfig = fin.read()
    bldCfg = buildConfig.split('\n')
print('Buildroot configuration:\n'+'\n'.join(bldCfg[:20])+'\n')

# generate (compressed) image's filename
imgName = setupConfig['os-name'] + '-' + setupConfig['version'] + '-' + setupConfig['model'] + '.img.gz'

#-----------------------------------------------------------------------------#

def extractBuildrootInfo(buildrootConfig) :
    """
    Extract CPU/architecture information from Buildroot configuration
    """

    # CPU
    reg = re.compile('BR2_GCC_TARGET_CPU=')
    cpu = list(filter(reg.match,bldCfg))
    cpu = cpu[0].split('=')[1].replace('\"','') if len(cpu) == 1 else ''

    # architecture
    reg = re.compile('BR2_ARCH=')
    arch = list(filter(reg.match,bldCfg))
    arch = arch[0].split('=')[1].replace('\"','') if len(arch) == 1 else ''

    return {"cpu":cpu,"architecture":arch}

#-----------------------------------------------------------------------------#

def getTimeStamp(timeFormat = args.timeFormat) :
    """
    Define a standard timestamp format
    Args:
        timeFormat [str]
    Return:
        tmpstmpfmt [str]
    """

    tmstmp = datetime.datetime.now()
    tmpstmpfmt = tmstmp.strftime(timeFormat)

    return tmpstmpfmt

#-----------------------------------------------------------------------------#

def initializeObject() :
    """
    Initialize empty board object with essential keys
    Args:
        None
    Return:
        boards [object]
    """

    boards = json.loads(args.boardSchema)
    boards['latestUpdate'] = getTimeStamp(args.timeFormat)

    return boards

#-----------------------------------------------------------------------------#

def validateObject(boardSchema, boardObject) :
    """
    (Recursively) validate board object with respect to essential keys
    Args:
        boardList [object]
        boardSchema [object]
    Return:
        [boolean]
    """

    for key in boardSchema:
        if isinstance(boardSchema[key],str) :
            if key not in list(boardObject.keys()) :
                return False
        elif isinstance(boardSchema[key],list) :
            if isinstance(boardObject[key],list) :
                try :
                    for el in boardObject[key] :
                        if not validateObject(boardSchema[key][0],el) :
                            return False
                except KeyError as err:
                    return False
            else :
                return False
        elif isinstance(boardSchema[key],object) :
            if not validateObject(boardSchema[key],boardObject[key]) :
                return False
        else :
            return False

    return True

#-----------------------------------------------------------------------------#

if __name__ == '__main__' :

    # check for existing board/image JSON file
    fileExst = os.path.exists(args.boardsFile)

    # load existing schema or generate/initialize one
    if fileExst :
        with open(args.boardsFile,'r') as fin :
            raw = fin.read()
            boards = json.loads(raw)
    else :
        print('board/image file does not exist => generating it')
        boards = initializeObject()
        # make sure board list is empty
        boards['boards'] = []
    print('existing/generated board/image object:\n'+json.dumps(boards,indent=4)+'\n')

    # validate object
    try :
        schema = json.loads(args.boardSchema)
        valid = validateObject(schema,boards)
    except Exception as err :
        raise RuntimeError('failed to validate board/image object: '+str(err))

    # throw exception for invalid board/image schema
    if not valid :
        raise RuntimeError('board/image file schema is invalid')

    # compose currently built board/image object
    builtBoardImage = initializeObject()["boards"][0]

    # board/model information
    builtBoardImage['board'] = setupConfig['board']
    builtBoardImage['boardname'] = setupConfig['boardname']
    builtBoardImage['model'] = setupConfig['model']
    builtBoardImage['modelname'] = setupConfig['modelname']

    # add CPU/architecture information
    cpuarch = extractBuildrootInfo(bldCfg)
    builtBoardImage['cpu'] = cpuarch['cpu']
    builtBoardImage['architecture'] = cpuarch['architecture']

    # add image file information
    builtBoardImage['latestImage']['file'] = imgName
    
    sha256_hash = hashlib.sha256()
    with open(os.path.join('output-build',imgName),'rb') as fin:
        for byte_block in iter(lambda: fin.read(4096),b""):
            sha256_hash.update(byte_block)
    builtBoardImage['latestImage']['sha256'] = sha256_hash.hexdigest()

    with open('rootfs/etc/os-release','r') as fin :
        osrelease = fin.read()
        osrls = osrelease.split('\n')
    reg = re.compile('VERSION=')
    bldtm = list(filter(reg.match,osrls))
    bldtm = bldtm[0].split('-')[-1].replace('\"','') if len(bldtm) == 1 else ''
    builtBoardImage['latestImage']['buildtime'] = bldtm
    builtBoardImage['latestImage']['download'] = args.baseURL + setupConfig['board'] + '/' + imgName
    builtBoardImage['latestImage']['update'] = args.baseURL + setupConfig['board'] + '/' + imgName.replace('.img.gz','.raucb')
    builtBoardImage['latestImage']['version'] = setupConfig['version']
    
    print('updated/new board/image object:\n'+json.dumps(builtBoardImage,indent=4)+'\n')

    # check for existing object in list of boards that exactly matches board/model/architecture
    exstidx = -1
    for (idx,brdimg) in enumerate(boards['boards']) :
        if ( brdimg['board'] == builtBoardImage['board'] and
             brdimg['model'] == builtBoardImage['model'] and 
             brdimg['architecture'] == builtBoardImage['architecture'] and
             brdimg['cpu'] == builtBoardImage['cpu'] ) :
            exstidx = idx
    print('existing board/image object at index: '+str(exstidx))

    if exstidx != -1 :
        print('replacing/updating existing board/image object\n')
        boards['boards'][exstidx] = builtBoardImage
    else :
        print(' => adding board/image object\n')
        boards['boards'].append(builtBoardImage)

    # update update-timestamp
    boards["latestUpdate"] = getTimeStamp()

    print('resulting board/image object:\n'+json.dumps(boards,indent=4,sort_keys=True)+'\n')
    
    # write resulting schema to file
    outFile = args.newFile if args.newFile else args.boardsFile
    print('writing object to file: '+str(outFile)+'\n')
    with open(outFile,'w') as fou :
        fou.write(json.dumps(boards,indent=4,sort_keys=True) + "\n")

#-----------------------------------------------------------------------------#

