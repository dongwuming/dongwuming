#!/bin/bash

while read line
do
commitID=`echo $line|awk '{ print $1}'`
url=`echo $line | awk '{ print $2}'`
SIVersion=$1
if [ ${#SIVersion} = 0  ];then
	echo "please input the SI version"
	exit
fi
pushd $url
	#AD-MASTER_13-1st
	#ghbk-fbu-release AD-MASTER_13-1st LEF_ACPU $SIVersion FBU-TS-ALL $commitID
popd
	echo "$SIVersion $commitID $url"  >> release_history
done < Release.list

