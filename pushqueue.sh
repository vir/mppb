#!/bin/sh

H=/home/deb

if [ -e "$H/tasks/ACTIVE" ]
then
	echo "Build task is already running"
	exit 1
fi

cd $H/buildqueue

F=`ls | sort | head -1`

if [ "$F" ]
then
	./$F && rm $F
fi


