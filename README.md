# Scripts

This repository contains the following scripts:

## hipache-ips.sh

This script allows update of an hipache docker container with a redis backend.
The name of the redis container must be "redis" (or change it in the redis_cli function).
(See https://github.com/hipache/hipache)


hipache-ips.sh script require an alias for each website for making frontend manipulations easier.

### Usage
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