#!/bin/sh

Q=$1
shift
/usr/bin/reprepro -b /home/deb/repo-$Q/ $*
