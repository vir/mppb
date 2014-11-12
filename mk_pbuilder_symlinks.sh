#!/bin/sh

cd $HOME/pbuilder
CMDS=`ls -l $HOME/repo-vir/dists/ | grep '^l' | awk '{
	print "ln -sf " $11 "-i386-base.tgz " $9 "-i386-base.tgz;"
	print "ln -sf " $11 "-amd64-base.tgz " $9 "-amd64-base.tgz;"
}'`

echo "Executing $CMDS"

eval $CMDS


