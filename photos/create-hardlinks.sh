#!/usr/bin/env bash
##################################################################################################################
## Check in a directory (or in a source and in a target directory) duplicates and affect them to the same inode ##
##################################################################################################################

if [[ "" == "$1" ]]
then
  echo "usage: ${BASH_SOURCE[0]} path1 [path2]"
  exit 1
fi

path1="$1"

if [[ "" == "$2" ]]
then
  path2="$path1"
else
  path2="$2"
fi

if [[ ! -d "$path1" ]]
then
  echo "ERROR: $path1 doesn't exist"
  exit 1
fi

if [[ ! -d "$path2" ]]
then
  echo "ERROR: $path2 doesn't exist"
  exit 1
fi

if [[ "$(uname)" == "Darwin" ]] # Mac OSX
then
    shasum="shasum"
else
    shasum="sha1sum"
fi

echo "Looking in $path2 duplicates of files from $path1"
start=$(date +%H:%M:%S)
echo "Start $start"

startTms=$(date +"%s")
find "$path1" -type f | while read f
do
  filename=$(echo "$f" | sed -E 's/.*\/([^\/]*)$/\1/')

  if [[ "." == ${filename:0:1} ]]
  then
    continue
  fi

  find "$path2" -name "$filename" | while read f2
  do
    inode1=$(ls -i "$f" | cut -d ' ' -f 1)
    inode2=$(ls -i "$f2" | cut -d ' ' -f 1)

    if [[ "$inode1" == "$inode2" ]]
    then
      continue # Same file or already an hard link
    fi

    shasum1=$("$shasum" "$f" | cut -d ' ' -f 1)
    shasum2=$("$shasum" "$f2" | cut -d ' ' -f 1)

    if [[ "$shasum1" != "$shasum2" ]]
    then
      continue # Another different file which has the same name
    fi

    echo -n "Creating hardlink from $f2 to $f ... "
    ln -f "$f2" "$f"
    echo "done"
  done
done
endTms=$(date +"%s")

end=$(date +%H:%M:%S)
echo "End $end"

exit 0