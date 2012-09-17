#!/bin/bash

#it need run in repo forall and give two options,
#the first is the PROJECTPATH,
#the second is the PWD in which you run the script
#repo forall -c '/home/ncmc-t3/bin/create-bugid-ghibikiid.sh $REPO_PATH /home/scm/build-spaces/ncmc-t3/LINUX/android'

NEXT="CMID"
PROJECTPATH=$1
LISTFILE=commit-bugid-gid-${PROJECTPATH//\//_}.list

rm -f $LISTFILE

TAG=`git tag |grep ORG-$3 |awk END'{print $0}'`
if [ "x${TAG}x" = "xx" ]; then
	DATESTR=`date '+%Y-%m-%d'`
	echo "TAG start with ORG-$3 can not be found in $PROJECTPATH!" >> /tmp/error-log-of-create-bugid-$DATESTR.log
	exit 1
fi
git log ${TAG}..HEAD > gitlog.list

commitnum=0

while read line
do
	case $NEXT in
	CMID)
		echo $line|grep "^commit" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			CMID=`echo $line| awk '{print $2}'`
			NEXT="BUGID"
			continue
		fi
		;;
	BUGID)
		echo $line|grep "Bug ID:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			BUGID=`echo $line| awk -F: '{print $2}'`
			NEXT="GID"
			continue
		else
			echo $line|grep "Change-Id:" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				GID=`echo $line| awk -F: '{print $2}' | cut -c1-10`
				NEXT="CMID"
				echo "$PROJECTPATH $CMID NOBUGID $GID" >> $LISTFILE
				((commitnum++))
			fi
		fi
		;;
	GID)
		echo $line|grep "Change-Id:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			GID=`echo $line| awk -F: '{print $2}' | cut -c1-10`
			NEXT="CMID"
			echo "$PROJECTPATH $CMID $BUGID $GID" >> $LISTFILE
			((commitnum++))
		fi
	esac
	echo $line|grep "^commit" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Error: Commit $CMID does not have enough BugID and GID!" >> $2/commit-bugid-gid.error
		CMID=`echo $line| awk '{print $2}'`
		NEXT="BUGID"
		continue
	fi
done < gitlog.list

rm -f gitlog.list
#merge the project's list to the whole list together
for ((i=1;i<=commitnum;i++))
do
	line=`eval "sed -n '${i}p' $LISTFILE"`
	linenum=$((commitnum-i+1))
	echo "$linenum $line" >> $2/commit-bugid-gid.list
done

rm -f $LISTFILE

if [ $NEXT != "CMID" ]; then
	echo "Error: Commit $CMID does not have enough BugID and GID!" >> $2/commit-bugid-gid.error
fi
