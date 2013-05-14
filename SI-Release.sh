#!/bin/bash

for line in `cat Release.list`
do
commitID=`echo $line|cut -d '|' -f 1`
url=`echo $line |cut -d '|' -f 2`
SIVersion=$1
if [ ${#SIVersion} = 0  ];then
	echo "please input the SI version"
	exit
fi
pushd $url
	Config_JP=`git config --get remote.origin.url`
        HBK=`git config --get remote.origin.url|cut -d ':' -f 2 |cut -d '/' -f 1`
	JPCPU=`git config --get remote.origin.url|cut -d ':' -f 2 |cut -d '/' -f 2`
	#AD-MASTER_13-1st
	echo "	ghbk-fbu-release $HBK $JPCPU  $SIVersion FBU-TS-ALL $commitID"
	/usr/bin/expect -c '
	spawn ghbk-fbu-release $HBK $JPCPU  $SIVersion FBU-TS-ALL $commitID
	expect "Is it okay to release the above patch? [y|n]:";send "y\r"
	expect eof
	'
popd
	echo "$SIVersion $commitID $url"  >> release_history
done 

