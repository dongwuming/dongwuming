#!/bin/bash


while read line
do
Name=`echo $line |awk '{print $2}'`
ChangeID=`echo  $line |awk '{print $1}'`
pwd=$PWD
URL=`cat .repo/manifest.xml |grep ${Name}\" | cut -d '"' -f 4 `
#echo $URL $ChangeID

echo "$Name $ChangeID $URL"

pushd $URL > /dev/null

Merge=`git log --grep="Change-Id: $ChangeID" --oneline |awk '{print $2}'|head -1`

if [ "$Merge" = "Merge" ];then 

   commitID=`git log --grep=$ChangeID --oneline |awk '{print $1}'|head -2 |tail -1 `
	if [ ${#commitID} = 0 ];then
		echo "this is the merge summit, No need to cherry pick "
	fi
else
   commitID=`git log --grep="Change-Id: $ChangeID" --oneline |awk '{print $1}'| head -1 `
fi


if [ ${#commitID} = 0 ] ; then 

mChangeID=`echo $ChangeID | cut -c 2- `
changeID=`git log $mChangeID -1|grep Change-Id:|awk -F: '{print $2}'`
	if [ ! ${#changeID} = 0 ] ; then
  	commitID=`git log --grep="$changeID"  --oneline | awk '{ print $1}'|head -1`
	fi
fi

echo "$Name $ChangeID $URL $commitID"
echo "----------------------"
echo "$commitID   $URL   changeID  $ChangeID" >> $pwd/cherry-pick.list-work
#git cherry-pick -x $commitID
#echo "-------------- $URL $ChangeID---------------"
popd > /dev/null

done <  $1 

