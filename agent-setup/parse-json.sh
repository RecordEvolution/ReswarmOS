#!/bin/sh

# https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html

parsejsonclean()
{
  cfg="$1"
  redarg="$2"

  if [ -z ${cfg} ]; then
    echo "parsejsonclean -> missing argument: please provide a .reswarm file" >&2
    echo 1
    return 1
  fi
  
  if [ ! -z ${redarg} ]; then
    echo "parsejsonclean -> takes only 1 argument" >&2
    echo 1
    return 1
  fi

  # remove any redundant spaces and linebreaks from object
  cfgcl=$(cat ${cfg} | tr -d "\n" | grep -v "^ *$" | sed 's/^ *{/{/g' | sed 's/} *$/}/g' \
                                                   | sed 's/, *\"/,\"/g' | sed 's/\" *,/\",/g' \
                                                   | sed 's/\" *: */\":/g' \
                                                   | sed 's/\" *: *{ *\"/\":{\"/g' \
                                                   | sed 's/\" *}/\"}/g' | sed 's/} *,/},/g')
  echo "${cfgcl}"
}

parsejsonvalid()
{
  cfg="$1"
  redarg="$2"

  if [ -z ${cfg} ]; then
    echo "parsejsonvalid -> missing argument: please provide a .reswarm file" >&2
    echo 1
    return 1
  fi
  
  if [ ! -z ${redarg} ]; then
    echo "parsejsonvalid -> takes only 1 argument" >&2
    echo 1
    return 1
  fi

  # check invalid key character sequences
  #-------------------------------------------------------#

  invalseq=$(cat "${cfg}" | tr -d "\n" | grep "{ *,\|, *{\|, *{\|, *:\|: *,\|{ *:\|} *:\|: *}\|{ *{\|} *}")
  if [ ! -z "${invalseq}" ]; then
    echo "parsejsonvalid -> invalid json: invalid character sequence of set [{},:]" >&2
    echo 1
    return 1
  fi

  # check bracket syntax
  #-------------------------------------------------------#

  # check opening and closing brackets
  frstchar=$(cat "${cfg}" | grep -v "^ *$" | head -n 1 | sed 's/^ *//g' | tr -d "\n" | head -c 1)
  lastchar=$(cat "${cfg}" | grep -v "^ *$" | tail -n 1 | sed 's/ *$//g' | tr -d "\n" | tail -c 1)
  if [ "${frstchar}" != "{" ]; then
    echo "parsejsonvalid -> invalid json: missing opening bracket '{'" >&2
    echo 1
    return 1
  fi
  if [ "${lastchar}" != "}" ]; then
    echo "parsejsonvalid -> invalid json: missing closing bracket '{'" >&2
    echo 1
    return 1
  fi

  # check for same number of opening/closing brackets
  numopen=$(cat "${cfg}" | grep -o "{" | wc -l)
  numclos=$(cat "${cfg}" | grep -o "}" | wc -l)
  if [ "${numopen}" != "${numclos}" ]; then
    echo "parsejsonvalid -> invalid json: inconsistent number of opening/closing brackets '{...}'" >&2
    echo 1
    return 1
  fi

  # check for consistent order of opening/closing brackets
  allbrack=$(cat "${cfg}" | grep -o "{\|}") # | sed ':a;N;$!ba;s/\n/ /g')
  numbr="0"
  totalnumbr=$(echo "${allbrack}" | wc -l)
  counter="0"
  while read br; do
    # open bracket
    if [ "${br}" == "{" ]; then
      #numbr=`expr $numbr + 1`
      numbr=$((numbr + 1))
    fi
    # closed bracket
    if [ "${br}" == "}" ]; then
      numbr=$((numbr - 1))
    fi
    # increment counter
    counter=$((counter + 1))
    # no intermediate closing of all open brackets
    if [ ${counter} -lt ${totalnumbr} ]; then
      if [ "${numbr}" -lt "1" ]; then
        echo "parsejsonvalid -> invalid json: intermediate closing of all brackets" >&2
        echo 1
        return 1
      fi
    else
      # final check (equivalent to check for same number of opening/closing brackets)
      if [ "${numbr}" != "0" ]; then
        echo "parsejsonvalid -> invalid json: inconsistent brackets" >&2
        echo 1
        return 1
      fi
    fi
  done < <(echo "${allbrack}")

  # check for key-value syntax
  #-------------------------------------------------------#

  # remove any redundant spaces and linebreaks from object
  cfgcl=$(parsejsonclean "${cfg}")
#  cfgcl=$(cat ${cfg} | tr -d "\n" | grep -v "^ *$" | sed 's/^ *{/{/g' | sed 's/} *$/}/g' \
#                                                   | sed 's/, *\"/,\"/g' | sed 's/\" *,/\",/g' \
#                                                   | sed 's/\" *: */\":/g' \
#                                                   | sed 's/\" *: *{ *\"/\":{\"/g' \
#                                                   | sed 's/\" *}/\"}/g' | sed 's/} *,/},/g')

  # extract all regex patterns of key-value match
  elements=$(echo "${cfgcl}" | grep -Po "\"[^,:{}]*\" *: *[\"]?[^,\"{}]*[\"]?")

  # count all characters contained in list of matches
  matchcount=$(echo "${elements}" | tr -d "\n" | wc -c)

  # after removing all key-value pairs the only remaining characters are supposed to be [,{}]
  remchars=$(echo "${cfgcl}" | grep -P "[,{}]" -o | tr -d "\n" | wc -c)

  # compare to total number of characters in object
  totchars=$(echo "${cfgcl}" | wc -c)

  # sum up remaining and matching characters (consider final linebreak of entire object)
  remmatchsum=$((matchcount + remchars + 1))

#  echo "${cfgcl}"
#  echo "${elements}"
#
#  echo "matchcount: ${matchcount}"
#  echo "remchars:   ${remchars}"
#  echo "totchars:   ${totchars}"
#  echo "sum:        ${remmatchsum}"

  if [ "${totchars}" != "${remmatchsum}" ]; then
    echo "parsejsonvalid -> invalid json: inconsistent key-value syntax" >&2
    echo 1
    return 1
  fi

}

parsejsonlistkeys()
{
  cfg="$1"
  redarg="$2"

  if [ -z ${cfg} ]; then
    echo "parsejsonlistkeys -> missing argument: please provide a .reswarm file" >&2
    return 1
  fi

  if [ ! -z ${redarg} ]; then
    echo "parsejsonlistkeys -> takes only 1 argument" >&2
    return 1
  fi

  # check validity of json file
  valret=$(parsejsonvalid ${cfg})
  if [ ! -z ${valret} ]; then
    echo "invalid file"
    return 1
  fi

  # find list of keys (keys may not contain the set of characters [,:{}] )
  keylist=$(cat ${cfg} | grep -oP "\"[^,:{}]*\" *:" | tr -d '":')

  echo ${keylist}
}

parsejsongetkey()
{
  cfg="$1"
  key="$2"
  redarg="$3"

  if [ -z ${cfg} ]; then
    echo "parejsongetkey -> missing argument: please provide a .reswarm file" >&2
    return 1
  fi
  
  if [ -z ${key} ]; then
    echo "parejsongetkey -> missing argument: please provide a key to be extracted" >&2
    return 1
  fi

  if [ ! -z ${redarg} ]; then
    echo "parsejsongetkey -> takes only 2 arguments" >&2
    return 1
  fi

  # check validity of json file
  valret=$(parsejsonvalid ${cfg})
  if [ ! -z ${valret} ]; then
    echo "invalid file"
    return 1
  fi

  # check existence of key
  keylist=$(parsejsonlistkeys ${cfg})
  keyfind=$(echo ${keylist} | grep "${key}")
  if [ -z "${keyfind}" ]; then
    echo "parsejsonkey -> key '${key}' does not exist" >&2
    return 1
  fi

  # clean the object
  cfgcl=$(parsejsonclean "${cfg}")
  
  # extract value of key
  keyful=$(echo "${cfgcl}" | grep -oP "\" *${key} *\"")
  keyval=$(echo "${cfgcl}" | grep -oP "\" *${key} *\" *: *(\"[^\"]*\"|[0-9]*)" | awk -F "${keyful}:" '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
 
  # consider nested object values
  if [ -z "${keyval}" ]; then
    keyval=$(echo "${cfgcl}" | grep -oP "\" *${key} *\" *: *{[^{}]*}" | awk -F "${keyful}:" '{print $2}' | sed 's/^ *//g' | sed 's/ *$//g')
    if [ -z "${keyval}" ]; then
      echo "parsejsonkey -> parsing of json object featuring more then two levels of nesting are not supported" >&2
      return 1
    fi
  fi

  echo "${keyval}"

}

