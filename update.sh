#!/bin/sh -x

echo `date +"%Y-%m-%d %H:%M:%S"`' Updating pbuilder'
for DIST in squeeze wheezy jessie sid
do
	OPTS="--http-proxy http://192.168.2.57:3128/ --configfile /home/deb/.pbuilderrc --override-config"
	sudo ARCH=i386  DIST=$DIST pbuilder --update $OPTS
	sudo ARCH=amd64 DIST=$DIST pbuilder --update $OPTS
done

# sudo ARCH=i386  DIST=$DIST pbuilder --create --http-proxy http://192.168.1.57:3128/ --configfile /home/deb/.pbuilderrc --override-config

