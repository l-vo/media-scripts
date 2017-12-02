# Scripts

This repository contains the following scripts:

## Docker directory

### hipache-ips.sh

This script allows update of an hipache docker container with a redis backend.
The name of the redis container must be "redis" (or change it in the redis_cli function).
(See https://github.com/hipache/hipache)


hipache-ips.sh script require an alias for each website for making frontend manipulations easier.

#### Usage
* Create a website record and affect it a frontend ip
```
$ ./hipache-ips.sh -a 157.14.12.27 -u http://www.mysite.fr myalias
```
* Add an extra ip to an already registered website
```
$ ./hipache-ips.sh -a 157.14.15.56 myalias
```
* Remove an ip
```
$ ./hipache-ips.sh -r 157.14.15.56 myalias
```
* List all ips of a website
```
$ ./hipache-ips.sh -l myalias
```

## Photos directory

### random-photos.sh

This script allows to retrieve random photos from a library. It gives a priority to later photos.

#### Requirements

These requirement are only needed if you use autorotate option (-a, see below).

* jhead (http://www.sentex.net/~mwandel/jhead/)
* jpegtran (http://jpegclub.org/jpegtran/)

#### Usage

* Retrieve 200 photos (default value) from a library
```
$ ./random-photos.sh /path/to/my/library /path/where/photos/will/be/copied
```

* Retrieve 300 photos
```
$ ./random-photos.sh -c 300 /path/to/my/library /path/where/photos/will/be/copied
```

* Pick later photos (default value for the -r option is 40)
```
$ ./random-photos.sh -r 10 /path/to/my/library /path/where/photos/will/be/copied
```

* Pick older photos
```
$ ./random-photos.sh -r 90 /path/to/my/library /path/where/photos/will/be/copied
```

* Activate autorotate feature (needs jhead and jpegtran)
```
$ ./random-photos.sh -a /path/to/my/library /path/where/photos/will/be/copied
```

### extract-photos.sh

This script allows to retrieve photos and videos from a library and organize them in folders date.

#### Requirements

* exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/index.html)

#### Usage

* Organize medias by date into a target folder
```
$ ./extract-photos.sh /path/to/my/library /path/where/photos/will/be/copied
```

* Organize all medias where date greater or equal than 12th May 2016
```
$ ./extract-photos.sh -d 2016-05-12 /path/to/my/library /path/where/photos/will/be/copied
```

### extract-videos.sh

This script allows to retrieve videos from a library and organize them in folders date.

#### Requirements

* exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/index.html)

#### Usage

* Organize videos by date into a target folder
```
$ ./extract-videos.sh /path/to/my/library /path/where/videos/will/be/copied
```

### remove-duplicates.sh

This script allows to remove duplicate files. A duplicate file is localized by a specific pattern before extension. These patterns are " ([0-9])" and "_[0-9]".  
A supposed duplicate is deleted only if an assumed original is found in the same directory with the same prefix and the same checksum.

#### Usage

* Remove duplicates, a confirmation is required for each file
```
$ ./remove-duplicates.sh /path/to/my/library
```

* Remove duplicates, files are removed without confirmation
```
$ ./remove-duplicates.sh -y /path/to/my/library
```