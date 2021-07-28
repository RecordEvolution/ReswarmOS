#-----------------------------------------------------------------------------#

import json
import argparse
import os
import datetime

parser = argparse.ArgumentParser(description='Update list of supported boards and their latest images')
parser.add_argument(  'boardsFile',type=str,default=None,
                                   help='path to supported boards JSON file')
parser.add_argument('--timeFormat',type=str,default='%Y-%m-%dT%H:%M:%S', 
                                   help='timestamp format')
parser.add_argument('--boardSchema',type=str, default='{"latestUpdate":"","boards":[{"board":"","boardname":"","model":"","modelname":"","architecture":"","latestImage":{"file":"","sha256":"","buildtime":""}}]}',
                                    help='JSON schema of board/image list')
args = parser.parse_args()
print(args)

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

    boards = {}
    boards['latestUpdate'] = getTimeStamp(args.timeFormat)
    boards['boards'] = []

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

    # check for existing file
    fileExst = os.path.exists(args.boardsFile)

    if fileExst :
        with open(args.boardsFile,'r') as fin:
            raw = fin.read()
            boards = json.loads(raw)

        print(json.dumps(boards,indent=2,sort_keys=False))
        #print(boards['boards'][1])
        #print(boards['boards'][1]['latestImage'])

        try :
            schema = json.loads(args.boardSchema)
            valid = validateObject(schema,boards)
        except Exception as e :
            raise RuntimeError('failed to valideObject:'+str(e))

        print("object is valid: "+str(valid))

    else :

        boards = initializeObject()
        print(boards)


#-----------------------------------------------------------------------------#

