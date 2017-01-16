#!/bin/bash

#############################################
## Manage frontend ips for a given website ##
#############################################

function usage()
{
  echo "usage ${BASH_SOURCE[0]} [[-a ip | -r ip | -l] [-u site_url] | -h] site_name"
}

function help()
{
  echo
  usage
  echo
  echo "-a ip"
  echo "  add an ip to the website"
  echo
  echo "-r ip"
  echo "  remove an ip from the website"
  echo
  echo "-u site_url"
  echo "  associate the external url to the website"
  echo
  echo "-l"
  echo "  display the ips list of the website"
  echo
  echo "-h"
  echo "  display this help"
  echo
}


function redis_cli()
{
    # Use tr because redis-cli output non printable characters at the end of the line
    ret=$(docker exec -t redis redis-cli --raw $1)

    if [[ "$2" == "" ]]
    then
      echo "$ret" | tr -dc "[[:print:]]"
    else
      echo "$ret"
    fi

}

function list_ip()
{
    if [[ "$(uname)" == "Darwin" ]] # Mac OSX
    then
      ips=$(redis_cli "LRANGE frontend:$1 1 -1" 1 | tr -cs "[[:print:]]" "^M")
      IFS="^M" read -r -a aips <<< "$ips"
    else
      aips=$(redis_cli "LRANGE frontend:$1 1 -1" 1)
    fi
}

declare -a aips
url=""
action="l"
while getopts :a:r:u:lh opt
do
  case "$opt" in
    h)
      help
      exit 0
      ;;
    u)
      url="$OPTARG"
      ;;
    a)
      action="a"
      ip="$OPTARG"
      ;;
    r)
      action="r"
      ip="$OPTARG"
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

shift $(($OPTIND - 1))

sitename="$1"
if [[ "$sitename" == "" ]]
then
  usage
  exit 1
fi

# Check whether site url has been set
if [[ $(redis_cli "EXISTS frontend:site:$sitename") == 0 ]]
then
    # Interactively set site url
    if [[ "$url" == "" ]]
    then
      echo "No url found for site name $sitename"
      echo "Please enter an url for this site:"
      read url
    fi

    # Remove http before url if present
    if [[ "$url" =~ ^http://(.*)$ ]]
    then
      url="${BASH_REMATCH[1]}"
    fi

    # Add site url in database
    redis_cli "SET frontend:site:$sitename $url" >/dev/null
    redis_cli "RPUSH frontend:$url $sitename" >/dev/null
else
    url=$(redis_cli "GET frontend:site:$sitename")
fi

# Add or remove action
if [[ "$action" == "a" ]] || [[ "$action" == "r" ]]
then
  # Check ip validity
  if ! [[ "$ip" =~ ^(https?://)?([0-9.]{7,15})$ ]]
  then
    echo "Incorrect ip address $ip for option -$action"
    exit 1
  fi

  if [[ "${BASH_REMATCH[1]}" == "" ]]
  then
    cleanIP="http://${BASH_REMATCH[2]}"
  else
    cleanIP="$ip"
  fi

  if [[ "$action" == "a" ]]
  then
    list_ip $url
    for wip in "${aips[@]}"
    do
      if [[ "$wip" == "$cleanIP" ]]
      then
        exit 0 # Ip already registered
      fi
    done
    # Add ip in database
    redis_cli "RPUSH frontend:$url $cleanIP" >/dev/null
  else
    # Remove ip from database
    redis_cli "LREM frontend:$url 0 $cleanIP" >/dev/null
  fi
elif [[ "$action" == "l" ]] # List ips for a site
then
  list_ip $url
  for wip in "${aips[@]}"
  do
    if [[ $(echo "$wip" | tr -dc '[[:print:]]') != "" ]]
    then
      echo "$wip"
    fi
  done
fi

exit 0