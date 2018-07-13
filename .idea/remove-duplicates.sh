#!/usr/bin/env bash

#################################################################################################################
# Find assumed duplicates and remove them if a file with the same prefix exist in its folder with the same sha1 #
#################################################################################################################

function usage()
{
    echo "usage: ${BASH_SOURCE[0]} [-y] [-h] target"
}

function help()
{
  echo
  usage
  echo
  echo "target"
  echo "  target path to inspect for removing duplicates"
  echo
  echo "-y"
  echo "  delete without confirmation"
  echo
  echo "-h"
  echo "  display this help"
  echo
}

forceDelete=0
while getopts :yh opt
do
  case "$opt" in
    y)
      forceDelete=1
      ;;
    h)
      help
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

shift $(($OPTIND - 1))

if [[ $1 == "" ]]
then
    usage
    exit 1
fi

target=$1

if [[ ! -d "$target" ]]
then
    echo "Target directory ($target) doesn't exist"
    exit 1
fi

regex="(.*)(_[0-9]| \([0-9]\))(\.[a-zA-Z0-9]+)"
if [[ "$(uname)" == "Darwin" ]] # Mac OSX
then
    findCmd=$(find -E "$target" -type f -regex "$regex")
    shasum="shasum"
else
    findCmd=$(find "$target" -type f -regextype posix-extended -regex "$regex")
    shasum="sha1sum"
fi

let removed=0
let kept=0
let found=0
while read file
do
  if [[ "$file" =~ ${regex}$ ]]
  then
    duplicate=0
    assumedOriginal="${BASH_REMATCH[1]}${BASH_REMATCH[3]}"
    if [[ -f "$assumedOriginal" ]]
    then
      shaOriginal=$("$shasum" "$assumedOriginal" | cut -d ' ' -f 1)
      shaDuplicate=$("$shasum" "$file" | cut -d ' ' -f 1)
      if [[ "$shaOriginal" == "$shaDuplicate" ]]
      then
        duplicate=1
        delete=1
        let found=$found+1
        if [[ "$forceDelete" == 0 ]]
        then
           echo "$found. $file (original $assumedOriginal): remove ? (Y/n) "
           read input </dev/tty
           if [[ "$input" != "Y" ]]
           then
             delete=0
             echo "File not removed"
           fi
        fi
        if [[ "$delete" == 1 ]]
        then
          rm "$file"
          let removed=$removed+1
          if [[ "$forceDelete" == 1 ]]
          then
            echo "$removed. $file (original $assumedOriginal) removed"
          else
            echo "$file (original $assumedOriginal) removed"
          fi
        fi
      fi
    fi
    if [[ "$duplicate" == "0" ]]
  then
    let kept=$kept+1
    echo "/!\ $file not a duplicate"
  fi
  fi
done <<< "$findCmd" # Since loop is executed in a subshell

echo "$removed duplicate(s) removed"
echo "$kept false duplicate(s) found"

exit 0