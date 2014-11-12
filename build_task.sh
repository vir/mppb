#!/bin/bash

H=/home/deb

if [ -z "$1" ]
then
	echo "Usage: $0 task_id"
	exit 1
fi

cd $H/tasks/$1 || exit 2

LOGDIR=$H/logs/`date +"%Y-%m-%d"`/$1
OPTS="--http-proxy http://192.168.2.57:3128 --configfile $H/.pbuilderrc --allow-untrusted"
DSC=`ls *.dsc`
BASE=${DSC%.dsc}
DIST=`awk '/^Distribution:/{ print $2 }' *.changes`
ARCH=`awk '/^Architecture:/{ print $2 }' *.dsc`
QUEUE=`cat queue`

ln -s $1 $H/tasks/ACTIVE

echo "$QUEUE $DIST $1 $BASE" > $LOGDIR/job.txt

if [ -z "$DIST" ]
then
	echo "Can not guess distribution"
	exit 1
fi

if [ -z "$QUEUE" ]
then
	echo "No queue file"
	exit 1
fi

mkdir -p /home/deb/pbuilder/result/$DIST
echo `date +"%Y-%m-%d %H:%M:%S "`"Building $BASE ($DIST) [$QUEUE]"

BUILTCOUNT=0

if [ "${ARCH}" = "all" ]
then
	LOGFILE=$LOGDIR/$DIST-$ARCH.log
	sudo DIST=$DIST ARCH=i386 QUEUE=$QUEUE linux32 /usr/sbin/pbuilder build --debbuildopts '-b' $OPTS $DSC > $LOGFILE 2>&1
	if [ $? -eq 0 ]
	then
		echo "$ARCH: OK"
		mv -- $LOGFILE ${LOGFILE%.log}-OK.log
		BUILTCOUNT=$[BUILTCOUNT + 1]
	else
		echo "$ARCH: FAILED"
		mv -- $LOGFILE ${LOGFILE%.log}-ERROR.log
	fi
else
	LOGFILE=$LOGDIR/$DIST-i386.log
	sudo DIST=$DIST ARCH=i386 QUEUE=$QUEUE linux32 /usr/sbin/pbuilder build --debbuildopts '-b' $OPTS $DSC > $LOGFILE 2>&1
	if [ $? -eq 0 ]
	then
		echo "i386: OK"
		mv -- $LOGFILE ${LOGFILE%.log}-OK.log
		BUILTCOUNT=$[BUILTCOUNT + 1]
	else
		echo "i386: FAILED"
		mv -- $LOGFILE ${LOGFILE%.log}-ERROR.log
	fi

	LOGFILE=$LOGDIR/$DIST-amd64.log
	sudo DIST=$DIST ARCH=amd64 QUEUE=$QUEUE        /usr/sbin/pbuilder build --binary-arch $OPTS $DSC > $LOGFILE 2>&1
	if [ $? -eq 0 ]
	then
		echo "amd64: OK"
		mv -- $LOGFILE ${LOGFILE%.log}-OK.log
		BUILTCOUNT=$[BUILTCOUNT + 1]
	else
		echo "amd64: FAILED"
		mv -- $LOGFILE ${LOGFILE%.log}-ERROR.log
	fi
fi


if [ $BUILTCOUNT -gt 0 ]
then
	mv $H/pbuilder/result/$DIST/* $H/repo-$QUEUE/incoming/
	mv * $H/repo-$QUEUE/incoming/
	$H/rep.sh $QUEUE $DIST $BASE
	rm -f $H/repo-$QUEUE/incoming/$BASE*
fi

cd $H
rm -rf $H/tasks/$1
echo `date +"%Y-%m-%d %H:%M:%S "`"Finished building $BASE ($DIST) [$QUEUE]"

rm -f $H/tasks/ACTIVE
$H/pushqueue.sh

