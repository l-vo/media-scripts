#!/usr/bin/env bash

#########################################################################################################
# This script retrieve randoms photos in a collection (for instance for select photo for a photo frame) #
#########################################################################################################

# Defaults
defaultExportCount=200 # Photo count to export, we will pick them from packets of (arbitrary choice) $exportCount photos
defaultRatio=40        # More the ratio is low, more the photos will be chosen in the latest of them
packetSize=50          # Size of the packets on which the draw will be done

function usage()
{
    echo "usage: ${BASH_SOURCE[0]} [-c count] [-r ratio] [-a] [-h] source target"
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
  echo "  target path where randomly selected photos will be stored"
  echo
  echo "-c count"
  echo "  photos count that will be retrieved (default $defaultExportCount)"
  echo
  echo "-r ratio"
  echo "  ratio, decrease it for retrieve later photos (default $defaultRatio)"
  echo
  echo "-a"
  echo "  autorotate photos based on exif informations"
  echo
  echo "-h"
  echo "  display this help"
  echo
}

# Remove index $1 of array $packet
function array_shift
{
    local i
    local wpacket

    wpacket=()
    for (( i=0; i<"${#packet[@]}"; i++ ))
    do
        if [[ "$i" != "$1" ]]
        then
            wpacket+=("${packet[$i]}")
        fi
    done

    packet=("${wpacket[@]}")
}

# Chose photos randomly
function random_photos
{
    local toRetrieve=$1
    local photo

    while [[ "$toRetrieve" > 0 ]]
    do
        if [[ "$noRandom" == "1" ]]
        then
            let "floor = 0"
        else
             # Random number between 0 and  currentPacketSize - 1
            let randMult=$RANDOM*${#packet[@]}
            randCount=32768     # $RANDOM produce a number between 0 and 32767
            let "floor = ($randMult - (${randMult} % ${randCount})) / ${randCount}"
        fi

        let "i = $i + 1"

        photo=${packet[${floor}]}
        echo "$i $photo"
        cp "$photo" "$target"

        array_shift "$floor"

        let toRetrieve=$toRetrieve-1
    done
}

# Compute photo count to retrieve randomly in the packet
function compute_retrieve
{
    local remaining=$1      # Photos remaining to add to the selection, allow to compute
                            # the photo proportion to take in the packet
    local packetSize=$2     # Packet size
    local toRetrieve
    local proportion

    # Compute the proportion on a packet of $exportCount depending on the remaining photos to add
    # So transpose the proportion to a packet of $packetSize elements
    perl -w -e "use POSIX; print ceil(($remaining*$packetSize)/($ratio*$exportCount/10)), qq{\n}" # /10 since ratio is *10 for not passing a float as an argument of the script
}

function check_path()
{
    if [[ $(ls -ld "$1" &>/dev/null; echo $?) == 1 ]]
    then
        echo "$1 must be a valid path"
        exit 1
    fi
}

exportCount="$defaultExportCount"
ratio="$defaultRatio"
rotate="0"

while getopts :c:r:ah opt
do
  case "$opt" in
    c)
      exportCount="$OPTARG"
      ;;
    r)
      ratio="$OPTARG"
      ;;
    a)
      rotate="1"
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

if [[ "$rotate" == "1" ]]
then
    if [[ $(which jhead) == "" ]]
    then
        echo "jhead must be installed"
        exit 1
    elif [[ $(which jpegtran) == "" ]]
    then
        echo "jpegtran must be installed"
        exit 1
    fi
    echo "Autorotate is activated"
fi

shift $(($OPTIND - 1))

if [[ $2 == "" ]]
then
    usage
    exit 1
fi

source=$1
check_path "$source"

target=$2
check_path "$target"

echo "Searching photos in $source ..."
allPhotos=$(find "$source" -iname *.jpg 2>/dev/null | sort -r)
declare -i totalPhotos # Explicit integer type; osx add a space behind the result of wc -l
totalPhotos=$(echo "$allPhotos" | wc -l)
echo "$totalPhotos found"

if (( "$packetSize" > "$totalPhotos" ))
then
    packetSize="$totalPhotos"
fi

noRandom="0"
if (( "$exportCount" >= "$totalPhotos" ))
then
    echo "WARNING: photos count to extract ($exportCount) is greater than photo count in source directory ($totalPhotos)"
    exportCount="$packetSize"
    noRandom="1"
fi

echo "Retrieving $exportCount photos on $totalPhotos"
# Packets of $exportCount photos creation
currentPacketSize=0
packet=()
declare -i floor
declare -i remaining
declare -i toRetrieve
let "remaining = ${exportCount}"
i=0
echo "$allPhotos" | while read photo
do
    let currentPacketSize=currentPacketSize+1
    packet+=("$photo")
    if [[ "$currentPacketSize" == "$packetSize" ]]
    then
        if [[ "$noRandom" == "1" ]]
        then
            toRetrieve="$packetSize"
        else
            toRetrieve=$(compute_retrieve "$remaining" "$packetSize")
        fi

        let "remaining = $remaining - $toRetrieve"

        random_photos "$toRetrieve" "$noRandom"

        if [[ "$remaining" > 0 ]]
        then
            currentPacketSize=0
            packet=()
        fi
    fi
done

# Last iteration not finished if there is not enough photos
if [[ "$remaining" > 0 ]]
then
    count="${#packet[@]}"
    toRetrieve=$(compute_retrieve "$remaining" "$count")
    random_photos "$toRetrieve"
fi

if [[ "$rotate" == "1" ]]
then
    # Apply auto rotate on all images
    echo "Applying autorotate on $exportCount photos"
    jhead -autorot "$target"/*
fi

exit 0