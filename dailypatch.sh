#!/bin/bash
LOCAL_TOP_DIR=$PWD
PRODUCT_NAME=`echo $LOCAL_TOP_DIR |awk -F '/' '{print $5}'`
TYPE=`echo $PRODUCT_NAME |awk -F '-' '{print $1}'`
MAIL_TEMPLATE=/home/scm/mail-template/$PRODUCT_NAME-dailypatch-Mail.txt
DATESTR=`date +%m/%d/%y`
EMAIL_ADDRESS="kaka-pm@thundersoft.com kaka-dm@thundersoft.com ncmc_kgm@thundersoft.com scm@thundersoft.com"
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
fi
current_version=${DEFAULT_REVISION##*-}

rm -f commit-bugid-gid*
repo forall -c 'git checkout -f;git clean -fd'
repo sync -j4
echo $LOCAL_TOP_DIR $TYPE
repo forall -c '/home/scm/bin/create-bugid-ghibikiid.sh $REPO_PATH $1 $2' $LOCAL_TOP_DIR $TYPE
/home/scm/bin/create-all-commit-patch.sh $PRODUCT_NAME $current_version

if [ $? -eq 0 ];then
	eval "cat $MAIL_TEMPLATE | sed 's@version@$current_version@'| sed 's@PRODUCT_NAME@$PRODUCT_NAME@'|sed 's@DATE@$DATESTR@'| mutt -s '[$TYPE] DailyPatch ' -- $EMAIL_ADDRESS"
fi				

pushd $LOCAL_TOP_DIR/build
ln -s /home/scm/bin/qdroidbuild/build.sh .
popd
