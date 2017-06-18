#!/usr/bin/env bash

################################################################################################
# Pick photos in a source path and export them into date folders in the given target directory #
################################################################################################

function usage()
{
    echo "usage: ${BASH_SOURCE[0]} [-d startdate] [-h] source target"
}

function help()
{
  echo
  usage
  echo
  echo "source"
  echo "  source path where photos are stored"
  echo
  echo "target"
  echo "  target path where photos will be copied"
  echo
  echo "-d startdate"
  echo "  only photos with date greater or equal than startdate are retrieved (format YYYY-MM-DD)"
  echo
  echo "-h"
  echo "  display this help"
  echo
}

lastDate=""
while getopts :d:h opt
do
  case "$opt" in
    d)
      lastDate="$OPTARG"
      ;;
    h)
      help
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

if [[ $(which exiftool) == "" ]]
then
    echo "exiftool must be installed"
    exit 1
fi

shift $(($OPTIND - 1))

if [[ $2 == "" ]]
then
    usage
    exit 1
fi

source="$1"
target="$2"

if [[ ! -d "$source" ]]
then
    echo "Source directory ($source) doesn't exist"
    exit 1
fi

if [[ ! -d "$target" ]]
then
    echo "Target directory ($target) doesn't exist"
    exit 1
fi

dateFilter=""
if [ "$lastDate" != "" ]; then
    echo "Pick files with date >= $lastDate"
    dateFilter="\$CreateDate ge \"${lastDate//-/:}\""
    dateFilter=" -if '$dateFilter'"
fi

exts="-ext jpg -ext mts -ext mp4 -ext m2ts -ext jpeg"
tmpdir="/tmp/extract-photos-exiftool"

echo "Creating temp folder ($tmpdir)"
if [[ -d "$tmpdir" ]]
then
  rm -rf "$tmpdir"/*
else
  mkdir "$tmpdir"
fi

echo "Copying medias in temp folder"
cmd="exiftool$dateFilter "$exts" \"$source\" -o \"$tmpdir/\" -r"
eval ${cmd}
initialFolder=$(pwd)
cd "$tmpdir"
echo "Renaming medias"
exiftool '-directory<CreateDate' -d %Y/%Y-%m-%d "$exts" .
cd "$initialFolder"
echo "Copy medias in target folder ($target)"
cp -r "$tmpdir"/* "$target"

echo "Removing temp folder"
rm -rf "$tmpdir"

exit 0
