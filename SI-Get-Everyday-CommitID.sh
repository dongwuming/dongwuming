#!/bin/bash

#it need run in repo forall and give two options,
#the first is the PROJECTPATH,
#the second is the PWD in which you run the script
#repo forall -c '/home/ncmc-t3/bin/create-bugid-ghibikiid.sh $REPO_PATH /home/scm/build-spaces/ncmc-t3/LINUX/android'

NEXT="CMID"
PROJECTPATH=$1
LISTFILE=SI-commit-gid-${PROJECTPATH//\//_}.list

rm -f $LISTFILE

#TAG=`git tag |grep ORG-${3} |grep -v COL|awk END'{print $0}'`
#TAG=`git tag |grep Q84Mv| awk 'END{print $1}'`
TAG=$3
echo $TAG
echo "git log ${TAG}..HEAD > gitlog.list"
git log ${TAG}..HEAD > gitlog.list

commitnum=0

while read line
do
	case $NEXT in
	CMID)
		echo $line|grep "^commit" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			CMID=`echo $line| awk '{print $2}'`
			NEXT="GID"
			continue
		fi
		;;
	GID)
		echo $line|grep "G-HIBIKI ID:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			GID=`echo $line| awk -F: '{print $2}' | sed 's/^ *//'|sed 's/[ |,]/_/g'`
			GID="[${GID}]"
			NEXT="FEATUREID"
			continue
		else
			echo $line|grep "^Merge:" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				echo "[$PROJECTPATH] $CMID is a merge commit" >> $2/commit-bugid-gid.error
				NEXT="CMID"
				continue
			fi
			echo $line|grep "Change-Id:" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				GTID=`echo $line| awk -F: '{print $2}'| cut -c1-10|sed 's/^ *//'`
				NEXT="CMID"
				echo "${PROJECTPATH} ${CMID} ${GTID}" >> $LISTFILE
				((commitnum++))
				continue
			fi
		fi
		;;
	FEATUREID)
		echo $line|grep "^[[:space:]]*Feature ID:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			FID=`echo $line| awk -F: '{print $2}' | sed 's/^ *//'|sed 's/[ |,]/_/g'`
			FID="[${FID}]"
			NEXT="BUGID"
			continue
		else
			echo $line|grep "Change-Id:" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				GTID=`echo $line| awk -F: '{print $2}'| cut -c1-10|sed 's/^ *//'`
				NEXT="CMID"
				echo "${PROJECTPATH} ${CMID} ${GTID}" >> $LISTFILE
				((commitnum++))
				continue
			fi
		fi
		;;
	BUGID)
		echo $line|grep "Function Name:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			BUGID=`echo $line| awk -F: '{print $2}' | sed 's/^ *//'|sed 's/[ |,]/_/g'`
			BUGID="[${BUGID}]"
			NEXT="REDMINEID"
			continue
		else
			echo $line|grep "Change-Id:" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				GTID=`echo $line| awk -F: '{print $2}'| cut -c1-10|sed 's/^ *//'`
				NEXT="CMID"
				echo "${PROJECTPATH} ${CMID} ${GTID}" >> $LISTFILE
				((commitnum++))
				continue
			fi
		fi
		;;
	REDMINEID)
		echo $line|grep "Redmine ID:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			RID=`echo $line| awk -F: '{print $2}' | sed 's/^ *//'|sed 's/[ |,]/_/g'`
			RID="[${RID}]"
			NEXT="GERRITID"
			continue
		else
			echo $line|grep "Change-Id:" > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				GTID=`echo $line| awk -F: '{print $2}'| cut -c1-10|sed 's/^ *//'`
				NEXT="CMID"
				echo "${PROJECTPATH} ${CMID} ${GTID}" >> $LISTFILE
				((commitnum++))
				continue
			fi
		fi
		;;
	GERRITID)
		echo $line|grep "Change-Id:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			GTID=`echo $line| awk -F: '{print $2}'| cut -c1-10|sed 's/^ *//'`
			NEXT="CMID"
			echo "${PROJECTPATH} ${CMID} ${GTID}" >> $LISTFILE
			((commitnum++))
		fi
	esac
	echo $line|grep "^commit" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Error: Commit $CMID does not have Change-Id!" >> $2/commit-bugid-gid.error
		CMID=`echo $line| awk '{print $2}'`
		NEXT="GID"
		continue
	fi
done < gitlog.list

rm -f gitlog.list

#merge the project's list to the whole list together
for ((i=1;i<=commitnum;i++))
do
	line=`eval "sed -n '${i}p' $LISTFILE"`
	linenum=$((commitnum-i+1))
	echo "$linenum $line" >> $2/SI-commit-gid.list
done

rm -f $LISTFILE

if [ $NEXT != "CMID" ]; then
	echo "Error: Commit $CMID does not have enough BugID and GID!" >> $2/commit-bugid-gid.error
fi
