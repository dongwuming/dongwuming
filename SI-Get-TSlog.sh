#!/bin/bash
[ -d SI-log ] && mkdir SI-log
pwd=$PWD
[ -f SI-commit-gid.list ]
while read line
do 
ChangeID=`echo $line|awk '{ print $4 }'`
CommitID=`echo $line|awk '{ print $3 }'`
URL=`echo $line|awk '{ print $2 }'`
pushd $URL
	git log $CommitID -1 > $pwd/SI-log/${ChangeID}.log
	echo "SI-log/${ChangeID}.log" >>  $pwd/list-TS-log
popd
done <  SI-commit-gid.list

