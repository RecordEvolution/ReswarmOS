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
parser.add_argument('--outputDir',type=str,default='output-build',help='output directory of built images')
parser.add_argument('--compressionExt',type=str,default='.img.gz',help='file extension of compressed image')
parser.add_argument('--timeFormat',type=str,default='%Y-%m-%dT%H:%M:%S',help='timestamp format')
parser.add_argument('--boardSchema',type=str,default='{"latestUpdate":"","boards":[{"board":"","boardname":"","model":"","modelname":"","architecture":"","cpu":"","latestImages":[{"osname":"","osvariant":"","version":"","file":"","size":0,"sha256":"","buildtime":""}]}]}',help='JSON schema of board/image release file')
parser.add_argument('--baseURL',type=str,default='https://storage.googleapis.com/reswarmos/',help='public base URL of images')
parser.add_argument('--osReleasePath',type=str,default='rootfs/etc/os-release',help='path to os-release file')
parser.add_argument('--newFile',type=str,default=None,help='different output file')

args = parser.parse_args()
print('CLI arguments:\n'+json.dumps(vars(args),indent=4)+'\n')

#-----------------------------------------------------------------------------#

# parse ReswarmOS's setup.yaml
with open(args.setupFile,'r') as fin :
    try :
        setupConfig = yaml.safe_load(fin)
    except yaml.YAMLError as err :
        raise RuntimeError('failed to read setup.yaml: '+str(err))
print('ReswarmOS setup:\n'+json.dumps(setupConfig,indent=4)+'\n')

if setupConfig['osvariant'] != 'installer':
# read buildroot configuration (consider default vs. custom configuration)
    if 'config' in list(setupConfig.keys()) and setupConfig['config'] :
        buildConfigPath = setupConfig['config']
    else :
        buildConfigPath = os.path.join('config',setupConfig['board'],setupConfig['model'],'config')

    with open(buildConfigPath) as fin :
        buildConfig = fin.read()
        bldCfg = buildConfig.split('\n')
    print('Buildroot configuration: (' + buildConfigPath + ')\n'+'\n'.join(bldCfg[:20])+'\n')

# generate (compressed) image's filename
imgName = setupConfig['osname']
if setupConfig['osvariant'] :
    imgName += '-' + setupConfig['osvariant']
imgName += '-' + setupConfig['version'] + '-' + setupConfig['model'] + args.compressionExt

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
        boardSchema [object]
        boardObject [object]
    Return:
        [boolean]
    """

    for key in boardSchema:
        if isinstance(boardSchema[key],str) or isinstance(boardSchema[key],int) :
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

    if not valid :
        raise RuntimeError('board/image file schema is invalid')

    # compose currently built board/model/image object
    boardRelease = initializeObject()["boards"][0]#["latestImages"][0]
    print('single templated board object\n',boardRelease,'\n')

    # board/model information
    boardRelease['board'] = setupConfig['board']
    boardRelease['boardname'] = setupConfig['boardname']
    boardRelease['model'] = setupConfig['model']
    boardRelease['modelname'] = setupConfig['modelname']

    # add CPU/architecture information
    if setupConfig['osvariant'] == 'installer':
        cpuarch = {'cpu': setupConfig['cpu'], 'architecture': setupConfig['architecture']}
    else:
        cpuarch = extractBuildrootInfo(bldCfg)

    boardRelease['cpu'] = cpuarch['cpu']
    boardRelease['architecture'] = cpuarch['architecture']

    # single system image release information
    imageFullPath = os.path.join(args.outputDir,imgName)
    imageRelease = boardRelease['latestImages'][0]
    imageRelease['osname'] = setupConfig['osname']
    imageRelease['osvariant'] = setupConfig['osvariant']
    imageRelease['file'] = imgName
    imageRelease['size'] = os.path.getsize(imageFullPath)

    # ...check sum
    sha256_hash = hashlib.sha256()
    with open(imageFullPath,'rb') as fin:
        for byte_block in iter(lambda: fin.read(4096),b""):
            sha256_hash.update(byte_block)
    imageRelease['sha256'] = sha256_hash.hexdigest()

    # ...build time
    with open(args.osReleasePath,'r') as fin :
        osrelease = fin.read()
        osrls = osrelease.split('\n')
    reg = re.compile('VERSION=')
    bldtm = list(filter(reg.match,osrls))
    bldtm = bldtm[0].split('-')[-1].replace('\"','') if len(bldtm) == 1 else ''
    imageRelease['buildtime'] = bldtm

    # ...public download link, RAUC bundle download and OS version
    imageRelease['download'] = args.baseURL + setupConfig['board'] + '/' + imgName
    imageRelease['update'] = args.baseURL + setupConfig['board'] + '/' + imgName.replace(args.compressionExt,'.raucb')
    imageRelease['version'] = setupConfig['version']
    
    print('new image release object:\n'+json.dumps(imageRelease,indent=4)+'\n')

    # check for existing board/model object with matching cpu/architecture in list of boards
    exstidx = -1
    for (idx,brdmdl) in enumerate(boards['boards']) :
        if ( brdmdl['board'] == boardRelease['board'] and
             brdmdl['model'] == boardRelease['model'] and
             brdmdl['architecture'] == boardRelease['architecture'] and
             brdmdl['cpu'] == boardRelease['cpu'] ) :
            exstidx = idx
    print('existing board/model object at index: '+str(exstidx) + '\n')

    if exstidx != -1 :
        exstBoardModel = boards['boards'][exstidx]

        # look for existing osname + osvariant combination
        imgidx = -1
        for (idx,img) in enumerate(exstBoardModel['latestImages']) :
            if ( img['osname'] == imageRelease['osname'] and
                 img['osvariant'] == imageRelease['osvariant'] ) :
                imgidx = idx

        if imgidx != -1 :
            print('existing OS name/variant object\n'
                  + json.dumps(exstBoardModel['latestImages'][imgidx],indent=4,sort_keys=True)+'\n')
            exstBoardModel['latestImages'][imgidx] = imageRelease
        else :
            print('OS name/variant object is not listed yet\n')
            exstBoardModel['latestImages'].append(imageRelease)

        # update exisiting board/model object
        boards['boards'][exstidx] = exstBoardModel

    else :
        print('adding board/image object\n')
        boardRelease['latestImages'] = [imageRelease]
        boards['boards'].append(boardRelease)

    # update update-timestamp
    boards["latestUpdate"] = getTimeStamp()

    print('resulting board/image object:\n'+json.dumps(boards,indent=4,sort_keys=True)+'\n')
    
    # write resulting schema to file
    outFile = args.newFile if args.newFile else args.boardsFile
    print('writing object to file: '+str(outFile)+'\n')
    with open(outFile,'w') as fou :
        fou.write(json.dumps(boards,indent=4,sort_keys=True) + "\n")

#-----------------------------------------------------------------------------#

