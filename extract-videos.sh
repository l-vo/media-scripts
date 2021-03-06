#!/usr/bin/env bash

################################################################################################
# Pick videos in a source path and export them into date folders in the given target directory #
################################################################################################

function usage()
{
    echo "usage: ${BASH_SOURCE[0]} source target [-h]"
}

function help()
{
  echo
  usage
  echo
  echo "source"
  echo "  source path where videos are stored"
  echo
  echo "target"
  echo "  target path where videos will be copied"
  echo
  echo "-h"
  echo "  display this help"
  echo
}

if [[ $(which exiftool) == "" ]]
then
    echo "exiftool must be installed"
    exit 1
fi

if [[ "$2" == "" ]]
then
    usage
    exit 1
fi

source="$1"
target="$2"

function extract_video
{
  file="$0"
  date=$(exiftool "$file" | grep "Date/Time Original" | awk '{print $4}')

  if [[ "$date" == "" ]]
  then
    echo "ERROR: can't find date for $file"
    continue
  fi

  dateFormated=${date//:/-}
  year=${dateFormated:0:4}

  yearDir="$target/$year"
  if [[ ! -d  "$yearDir" ]]
  then
    echo "Creating $yearDir"
    mkdir "$yearDir"
  fi

  dayDir="$yearDir/$dateFormated"
  if [[ ! -d  "$dayDir" ]]
  then
    echo "Creating $dayDir"
    mkdir "$dayDir"
  fi

  echo "Copying $file to $dayDir"
  cp "$file" "$dayDir"
}

export target && export -f extract_video
find "$source" \( -iname *.mp4 -o -iname *.mts -o -iname *.m2ts \) -exec bash -c extract_video {} \;

exit 0