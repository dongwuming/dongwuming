#!/bin/bash  
#####################################################################
#
#  Function: This is for the ncmc to check the log format of the LEF 
#  Auther: zhangpf1265@thundersoft.com
#  Time:2013-02-06
#
#####################################################################
[ -f si.config ]
#while read line 
#File_log=$line
#do 
GID=0
FID=0
FNAME=0
RID=0
ABT=0
NEXT="G-HIBIKI_ID"
gerrit_action_cmd=/home/scm/scripts/gerrit_action.py
gerrit_user=jenkins
gerrit_url=http://192.168.11.200/ncmc
File_log=$1
ChangeID=$2

#########################
#
#    #review -1 
# 
########################


Set_review_1 ()
{
 echo $2
 echo $1

 $gerrit_action_cmd -u "$gerrit_user" -r "$gerrit_url" -c $2 -a review  -s -1 -m "$1  Please reference $BUILD_URL"
}

##############################
#
# check the number of colon':'
#
#############################

Number_colon ()
{
	#判断域是否为2
        Number=`echo $1 | mawk -F":" '{print NF}'`
        if [ $Number -ne 2 ] ; then
        echo $2
	echo $Number
        #review-1，
        Set_review_1 $3  $2
	exit 1
        fi

}

#main

############################
#
# Check the format and get 
# the value of the variable 
#
############################
while read line
do
	case $NEXT in
	G-HIBIKI_ID)
		echo $line|grep -e "^[[:space:]]*G-HIBIKI ID:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			Number_colon "$line" "ERROR:G-HIBIKI ID's char is invalid" "$ChangeID"
			GHIBIKI_ID=`echo $line|cut -d ":" -f 2|sed 's/^[[:space:]]*//'|sed 's/[[:space:]]*$//'` 
			GID=1
			NEXT="Feature_ID"
			continue
		fi
		;;
	Feature_ID)
		echo $line|grep -e  "^[[:space:]]*Feature ID:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			Number_colon "$line" "ERROR:Feature_ID's char is invalid" "$ChangeID"
			Feature_ID=`echo $line|cut -d ":" -f 2|sed 's/^[[:space:]]*//'|sed 's/[[:space:]]*$//' `
			FID=1
			NEXT="Function_Name"
			continue
		fi
		;;
	Function_Name)
		echo $line|grep -e  "^[[:space:]]*Function Name:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			Function_Name=`echo $line|cut -d ":" -f 2|sed 's/^[[:space:]]*//'|sed 's/[[:space:]]*$//'`
			FNAME=1
			NEXT="Redmine_ID"
			continue
		fi
		;;
	Redmine_ID)
                echo $line|grep -e  "^[[:space:]]*Redmine ID:" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
			Number_colon "$line" "ERROR:Redmine_ID's char is invalid" "$ChangeID"
                        Redmine_ID=`echo $line|cut -d ":" -f 2|sed 's/^[[:space:]]*//'|sed 's/[[:space:]]*$//'`
			RID=1
                        NEXT="ABSTRACT"
                        continue
                fi
                ;;

	ABSTRACT)
		echo $line|grep -e  "^[[:space:]]*ABSTRACT:" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			ABSTRACT=`echo $line|grep "ABSTRACT" |cut -d ":" -f 2|sed 's/^ //'|sed 's/ $//'`
			ABT=1
			continue
		fi
		;;
	esac
done <  $File_log


#check the log model
#GID FID FNAME RID
echo "GID: $GID; FID: $FID; FNAME:$FNAME; RID:$RID ABT:$ABT "

if [ $GID = 0 ]||[ $FID = 0 ]||[ $FNAME = 0 ]||[ $RID = 0 ]||[ $ABT = 0 ];then 
        
	echo "ERROR:The format of the log is invalid  "
	#review -1 ;
        Set_review_1 "ERROR:The format of the log is invalid! " "$ChangeID"
	exit 1
fi


echo "==============================="
	echo "G-HIBIKI_ID:$GHIBIKI_ID"
	echo "Feature_ID:$Feature_ID"
	echo "Function_Name:$Function_Name"
	echo "Redmine_ID:$Redmine_ID"
	echo "ABSTRACT:$ABSTRACT"


#[AD-MASTER_13-1st] [0032000] [Q84-DRV-NC-CAMERA-C-TS]

#[Requirement number]:
#[Function define]:
#[FBU name]:FBU-TS-ALL
#[Comment]:LEF-0507-SI
#[Sync commit exist/no]:
#[Sync commit ID]:
#[Target base]:0031100
#[Bug number]:AD13-1st-PR1-03275
#[GHIBIKI number]:

#Deplace the log
#The first line
#[AD-MASTER_13-1st] [0032000] [Q84-DRV-NC-CAMERA-C-TS] 
#F_HBK=AD-MASTER_13-1st
F_HBK=`cat si.config |cut -d '/' -f 1`
S_Version=`cat si.config |cut -d '/' -f 2`
#from Function_Name 第一个值

T_S=`echo $Function_Name | cut -d '[' -f 2 |sed 's/]//'`
if [ ${#T_S} -eq 0 ] ;then
        T_S=TS-ALL
fi

#Function define
NEC_Function_Name=$Function_Name

#Requirement number
NEC_Feature_ID=$Feature_ID

#Comment
SI_Time=`date '+%m%d'`
Branch=`cat si.config |cut -d '/' -f 4`

#Target base
Base_version=`cat si.config |cut -d '/' -f 3`

#Bug number
#GHIBIKI number
#echo ${GHIBIKI_ID} |grep "\-PR"
IN=`echo $Function_Name | cut -d '[' -f 3 |sed 's/]//'`
if [ "$IN" = "CRIN" ];then
	Bug_number=
	GHIBIK_number=$GHIBIKI_ID
fi
if [ "$IN" = "PRIN" ];then
	Bug_number=$GHIBIKI_ID
	GHIBIK_number=
fi

echo "[$F_HBK] [$S_Version] [$T_S]" > ${File_log}_NEC.log
echo "" >>  ${File_log}_NEC.log
echo "[Requirement number]:$NEC_Feature_ID" >>  ${File_log}_NEC.log
echo "[Function define]:$NEC_Function_Name" >>  ${File_log}_NEC.log
echo "[FBU name]:FBU-TS-ALL" >>  ${File_log}_NEC.log
echo "[Comment]:${Branch}-${SI_Time}-SI,$ABSTRACT" >>  ${File_log}_NEC.log
echo "[Sync commit exist/no]:no" >>  ${File_log}_NEC.log
echo "[Sync commit ID]:" >>  ${File_log}_NEC.log
echo "[Target base]:$Base_version" >>  ${File_log}_NEC.log
echo "[Bug number]:$Bug_number" >>  ${File_log}_NEC.log
echo "[GHIBIKI number]:$GHIBIK_number" >> ${File_log}_NEC.log

#done < list-TS-log
