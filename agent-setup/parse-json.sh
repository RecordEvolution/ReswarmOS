#!/bin/sh

parsejsonvalid()
{
  cfg="$1"
  redarg="$2"

  if [ -z ${cfg} ]; then
    echo "parsejsonvalid -> missing argument: please provide a .reswarm file" >&2
    return 1
  fi
  
  if [ ! -z ${redarg} ]; then
    echo "parsejsonvalid -> takes only 1 argument" >&2
    return 1
  fi

  # check opening and closing brackets
  frstchar=$(cat "${cfg}" | grep -v "^ *$" | head -n 1 | sed 's/^ *//g' | tr -d "\n" | head -c 1)
  lastchar=$(cat "${cfg}" | grep -v "^ *$" | tail -n 1 | sed 's/ *$//g' | tr -d "\n" | tail -c 1)
  if [ "${frstchar}" != "{" ]; then
    echo "parsejsonvalid -> invalid json: missing opening bracket '{'" >&2
    return 1
  fi
  if [ "${lastchar}" != "}" ]; then
    echo "parsejsonvalid -> invalid json: missing closing bracket '{'" >&2
    return 1
  fi

  # check for same number of opening/closing brackets
  numopen=$(cat "${cfg}" | grep -o "{" | wc -l)
  numclos=$(cat "${cfg}" | grep -o "}" | wc -l)
  if [ "${numopen}" != "${numclos}" ]; then
    echo "parsejsonvalid -> invalid json: inconsistent number of opening/closing brackets '{...}'" >&2
    return 1
  fi

  # check for same number of opening/closing brackets and their consistent order!
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
        return 1
      fi
    else
      # final check (equivalent to check for same number of opening/closing brackets)
      if [ "${numbr}" != "0" ]; then
        echo "parsejsonvalid -> invalid json: inconsistent brackets" >&2
        return 1
      fi
    fi
  done < <(echo "${allbrack}")
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

  # find list of keys
  keylist=$(cat ${cfg} | grep -oP "\"[^,:;]*\":" | tr -d '":')

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

  # check existence of key
  keylist=$(parsejsonlistkeys ${cfg})
  keyfind=$(echo ${keylist} | grep "${key}")
  if [ -z "${keyfind}" ]; then
    echo "parsejsonkey -> key '${key}' does not exist" >&2
    return 1
  fi
  
  # extract value of key
  keyval=$(cat ${cfg} | grep -oP "\"${key}\":[^,]*" | awk -F "\"${key}\":" '{print $2}' | tr -d '"' )

  echo ${keyval}
}

