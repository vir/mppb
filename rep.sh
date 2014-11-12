#!/bin/bash -x

H=/home/deb
PREFIX=${3-}
DIST=$2
REPO=$1
PKG=$H/repo-$REPO/incoming
REP=$H/repo-$REPO/

if [ -z "$DIST" ]
then
	echo "Usage: $0 nightly|releases|vir stable|unstable|testing [pkg_name_prefix]"
	exit 1
fi

# --outdir outdir

reprepro -b $REP createsymlinks

cd $PKG
for f in $PREFIX*.changes; do
	echo " * Including $f"
	reprepro -V -b $REP -C main include $DIST $f && rm `awk '(/.(deb|dsc|tar.gz)$/ && $5) { print $5 }' $f` $f
done
#for f in *.deb; do
##	b=${f%%_*}
##	reprepro -b $REP -C main remove lenny $f
#	reprepro -b $REP -C main includedeb stable $f
#done


