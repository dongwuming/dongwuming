#!/bin/bash

#Qphone build ver0.0.1
#shiwt@thunderst.com
function build_prepare(){
	echo "set the QPHONE_BUILD_ID env-variable"
#	PRODUCT_NAME=$1
#	PRODUCT_RELEASE_DIR=$2
	
	PRODUCT_BUILD_DIR=$(echo $(pwd) | awk -F "/" '{print $NF}')
	TARGETSTRING="revision"
	DEFAULT_REVISION=
	if [ -f ".repo/manifest.xml" ];then   
		for ii in `cat .repo/manifest.xml | grep "<default " | awk '{print $2,$3}'`
		do
			if [ `echo $ii | grep "$TARGETSTRING"` ];then
				echo $ii
				DEFAULT_REVISION=`echo $ii | awk -F "\"" '{print $2}'`
				break
			fi
		done
		echo "default version: $DEFAULT_REVISION"
	else
		echo "Can not find .repo/manifest.xml"
		DEFAULT_REVISION="$PRODUCT_NAME"
	fi
	
	if [ "$mydate" == "DATE" ];then
		QPHONE_BUILD_ID=`date +%Y%m%d%H%M%S`
		#QPHONE_BUILD_ID=`date +%Y%m%d`
	else
		QPHONE_BUILD_ID="$mydate"
	fi

	export QPHONE_BUILD_ID
	export USER=scm	
	#mytag="$PRODUCT_BUILD_DIR-$QPHONE_BUILD_ID"
	mytag="$DEFAULT_REVISION-$QPHONE_BUILD_ID"
	
	echo "tag is $mytag"	
	umask 0
	source ./build/envsetup.sh
	source ~/bin/qdroidbuild/qdroidcommand
#	rename_update_file
#	setup_build_env "$PRODUCT_NAME" "$PRODUCT_RELEASE_DIR"
}

case "$#" in
	"4" | "3" )
		echo "$0 [DATE/DropX-Y.Z] Mobile image-type-list \"QDroid/Drop6/DailyBuild\" "
		echo "example: $0 [DATE/DropX-Y.Z] Mobile \"board_ddd_eng,5902@1 1 7 3@1,ThirdApks@LCT/oems.sh|board_ddd_user@1 1 7 1\" \"QDroid/Drop6/DailyBuild\""	
			
		mydate=$1
		product_n="$2"
		PRODUCT_NAME="${product_n%%/*}"   # aa/bb/cc --> aa
		PRODUCT_BUILD_LIST="$3"
		echo "MY LIST:$PRODUCT_BUILD_LIST"
		build_prepare "$PRODUCT_NAME" "$PRODUCT_RELEASE_DIR"		
		source ~/bin/qdroidbuild/qdroidcommand
		#source /project/home/scm/bin/qdroidbuild/qdroidcommand
		rename_update_file
		getbuildopt "$PRODUCT_BUILD_LIST"
		echo "in $0  all image type:${ALL_BUILD_IMAGE_TYPE[@]}"
		echo "in $0  all oem setup:${ALL_BUILD_OEM_SETUP[@]}"
		echo ${#ALL_BUILD_IMAGE_TYPE[@]}

		n=0
		while [ $n -lt "${#ALL_BUILD_IMAGE_TYPE[@]}" ];do
			echo "in while $n"
			echo ${ALL_BUILD_IMAGE_TYPE[$n]}
			echo ${ALL_BUILD_CHOOSECOMBO[$n]}
			echo ${ALL_BUILD_THIRDPARTY[$n]}
			echo ${ALL_BUILD_OEM_SETUP[$n]}
			echo ${ALL_BUILD_PRODUCT_PATH_SETUP[$n]}
			(build_temp "${ALL_BUILD_IMAGE_TYPE[$n]}" "${ALL_BUILD_CHOOSECOMBO[$n]}" "${ALL_BUILD_THIRDPARTY[$n]}" "${ALL_BUILD_OEM_SETUP[$n]}" "${ALL_BUILD_PRODUCT_PATH_SETUP[$n]}" "$n")
			let n++
		done
		echo "Build Finish!"
		;;
	*)
		echo "Nothing Please Check Your argc"
		echo "example: $0 [DATE/DropX-Y.Z] Mobile \"board_ddd_eng@1 1 7 3@1,ThirdApks@LCT/oems.sh|board_ddd_user@1 1 7 1\" \"QDroid/Drop6/DailyBuild\""	
		exit	
		;;
esac


