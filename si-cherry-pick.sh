#!/bin/bash 

###########################################################################################
#
#  This script is for the SI of the kumquat and the lef 
#    1 : you must get the commitID , changeID , and the path of the local tree of the local
#    2 : cherry pick 
#    3 : modify the remote
#    4 : you need use  the " git gui " to push the code to the nec server
#
###########################################################################################
#get list

cat cherry-pick.list-work |awk '{ print $2}' |sort -u > list
while read line
do
	num=`cat cherry-pick.list-work |grep $line |wc -l`
	echo "$line $num" >> list-num

done < list


#git log --grep 
#cd 8064/LINUX/android/
if [ -d SI-log  ];then
   echo "ok"
else
   echo "please get the log files"
   exit
fi

while read line
do
URL=`echo $line |awk '{print $2}'`
COMMITID=`echo  $line |awk '{print $1}'`
ChangeID=`echo  $line |awk '{print $4}'`
pwd=$PWD
pushd SI-log

log=`ls $ChangeID*`

if [ ${#log} = 0  ] ; then 
    echo "$ChangeID, $URL, Do not get the log----------------"
    exit
fi

echo $pwd $log
popd
echo "   $COMMITID    $URL       $ChangeID"
#echo $URL $ChangeID 
#cherry pick start
pushd  $URL
    git cherry-pick -x $COMMITID
    if [ $? = 0 ];then
	git commit --amend --author="華　捷  <j-hua@ncmobile.neccnt.com> " --file=$pwd/SI-log/$log
         JPcommit=`git log --oneline |head -1 |awk '{ print $1}'`
         echo "$COMMITID  $URL  $ChangeID  JP_LEF_CommitID:$JPcommit  " >> $pwd/SUCCESS.list
         echo "$JPcommit $URL $ChangeID " >> $pwd/Release.list
	
    else	
	Result_check=`git status -s | grep -E "DD|AU|UD|UA|DU|AA|UU"`
	if [ ${#Result_check} = 0  ];then 
		echo "$COMMITID  $URL  $ChangeID : Nothing To commit " >> $pwd/Failure.list
	else
		echo "$COMMITID  $URL  $ChangeID : Failure $Result_check" >> $pwd/Failure.list
	fi
    fi

    
#cherry picl end
#Add the nec remote start
if [ $? -ne 1 ];then

    prjname=`git config --get remote.origin.projectname`
    checkprj=`echo $prjname |cut -d '/' -f 1`
    CPU=`git config --get remote.origin.projectname|cut -d '/' -f 2`
    if [ $checkprj = "kag-jb" ] ;then
        M_prjname=`echo $prjname |cut -d '/' -f 3-`
        echo $M_prjname  $COMMITID   $URL $prjname
        git remote rm  origin
        #git remote add origin ghibiki5:AD-MASTER_12-2nd-JB/Q84_ACPU/$prjname
        if [ $CPU = "ACPU" ];then
                git remote add origin  ghibiki5:KAGUYA-JB/ACPU-JB/$M_prjname
        elif [ $CPU = "MCPU" ]; then
                git remote add origin  ghibiki5:KAGUYA-JB/MCPU-JB//$M_prjname
        else
                git remote add origin  ghibiki5:KAGUYA-JB/NCPU-JB//$M_prjname
        fi
        git config remote.origin.projectname "$M_prjname"

    elif [ $checkprj = "lef" ];then
        M_prjname=`echo $prjname |cut -d '/' -f 3-`
        echo $M_prjname  $COMMITID   $URL $prjname
        git remote rm  origin

        #git remote add origin ghibiki5:AD-MASTER_12-2nd-JB/Q84_ACPU/$prjname
        if [ $CPU = "ACPU" ];then
                git remote add origin  ghibiki5:AD-MASTER_13-1st/LEF_ACPU/$M_prjname
        elif [ $CPU = "MCPU" ]; then
                git remote add origin  ghibiki5:AD-MASTER_13-1st/LEF_MCPU/$M_prjname
        else
                git remote add origin  ghibiki5:AD-MASTER_13-1st/LEF_NCPU/$M_prjname
        fi
        git config remote.origin.projectname "$M_prjname"

    else
        echo "Don't need to modify the remote"
    fi

else
    echo "==========================="
    echo "=====Cherry pick ERROR====="
    echo "===========================" 
        echo "   $COMMITID    $URL       $ChangeID"
    echo "==========================="
fi
#ghbk-fbu-release <PJ名> <CPU名> <SI版本号> <FBU名>
#ghbk-fbu-release  ghbk-fbu-release  Q84_ACPU 0010500   FBU-TS-ALL
#success example :ghbk-fbu-release  12-2nd-Q89_ts  ACPU  6000100 FBU-TS-ALL 6ed134ca73e27859cca16f1e77565da35c38f13b
#SIVersion=$2
#ReleaseID=`git log -1 --oneline  |awk '{print $1}'`
#echo $SIVersion $ReleaseID
#ghbk-fbu-release AD-MASTER_13-1st LEF_ACPU $SIVersion FBU-TS-ALL $ReleaseID
echo "$URL----------- $COMMIT---------------"
popd

done <  $1
