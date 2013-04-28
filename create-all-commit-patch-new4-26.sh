#!/bin/bash

rm -f result-bug-check.list
DATESTR=`date '+%Y-%m-%d'`
OUTDIR=~/patch-outdir/$1/$2
LOCALDIR=$PWD
rm -rf $OUTDIR
mkdir -p $OUTDIR

#create patches and modify files list and the correct before after commit id
while read line
do
	ORDERID=`echo $line|awk '{print $1}'`
	PROJECTPATH=`echo $line|awk '{print $2}'`
	COMMITID=`echo $line|awk '{print $3}'`
	GHIBIKIID=`echo $line|awk '{print $NF}'`
	
	DIRNAME="${PROJECTPATH////_}-${ORDERID}-${GHIBIKIID}"

	echo "PROJECTPATH=$PROJECTPATH"
	echo "COMMITID=$COMMITID"
	echo "GHIBIKIID=$GHIBIKIID"

	pushd $PROJECTPATH
	BEFOREID=`git log --oneline -1 $COMMITID^1|awk '{print $1}'`
	mkdir -p $OUTDIR/$DIRNAME/
	echo "$PROJECTPATH $COMMITID" >> $OUTDIR/$DIRNAME/commitid
	git log --name-status --oneline -1 $COMMITID|sed -n '2,$p'|awk -vP=$PROJECTPATH '{print P"/"$2}' >> $OUTDIR/$DIRNAME/${PROJECTPATH//\//_}-modify-files.list
#	if [ -r $OUTDIR/$GHIBIKIID/$GHIBIKIID.patch ]; then
#		git format-patch -1 $COMMITID --stdout > $OUTDIR/$GHIBIKIID/$GHIBIKIID.patch-new
#		cat $OUTDIR/$GHIBIKIID/$GHIBIKIID.patch >> $OUTDIR/$GHIBIKIID/$GHIBIKIID.patch-new
#		mv $OUTDIR/$GHIBIKIID/$GHIBIKIID.patch-new $OUTDIR/$GHIBIKIID/$GHIBIKIID.patch
#	else
#		git format-patch -1 $COMMITID --stdout > $OUTDIR/$GHIBIKIID/$GHIBIKIID.patch
#	fi
	popd

	grep "$PROJECTPATH $GHIBIKIID" result-bug-check.list >/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		oldbeforeid=`grep "$PROJECTPATH $GHIBIKIID" result-bug-check.list|awk '{print $5}'`
		sed -i "s/$oldbeforeid/$BEFOREID/" result-bug-check.list
	else
		echo "$ORDERID $PROJECTPATH $GHIBIKIID $COMMITID $BEFOREID" >> result-bug-check.list
	fi
done < commit-bugid-gid.list

#create before after files
while read line
do
	ORDERID=`echo $line|awk '{print $1}'`
	PROJECTPATH=`echo $line|awk '{print $2}'`
	GHIBIKIID=`echo $line|awk '{print $3}'`
	AFTERID=`echo $line|awk '{print $4}'`
	BEFOREID=`echo $line|awk '{print $5}'`

	pushd $PROJECTPATH

	defaultbranch=`git branch|awk '{if ($1=="*") print $2}'`

	DIRNAME="${PROJECTPATH////_}-${ORDERID}-${GHIBIKIID}"

	mkdir -p $OUTDIR/$DIRNAME/after/$PROJECTPATH/
	mkdir -p $OUTDIR/$DIRNAME/before/$PROJECTPATH/

	#checkout to the require commit to get after files
	git checkout $AFTERID 
	echo "[${DIRNAME}]" >> $OUTDIR/commit-all-git.log
	git log -1 $AFTERID >> $OUTDIR/commit-all-git.log
	popd

	tar -T $OUTDIR/$DIRNAME/${PROJECTPATH//\//_}-modify-files.list -c | tar -x -C $OUTDIR/$DIRNAME/after/

	#checkout to the id before the require commit to get before files
	pushd $PROJECTPATH
	git checkout $BEFOREID 
	popd

	tar -T $OUTDIR/$DIRNAME/${PROJECTPATH//\//_}-modify-files.list -c | tar -x -C $OUTDIR/$DIRNAME/before/

	#return to origin branch
	pushd $PROJECTPATH
	git checkout $defaultbranch
	popd

	#create patch based on before/after directory
	pushd $OUTDIR/$DIRNAME
	PATHLIST=`ls *.patch 2>/dev/null`
	if [ -z "$PATHLIST" ]; then
		diff -uNra before after > ${PROJECTPATH//\//_}-$ORDERID-$GHIBIKIID.patch
	else
		NEWNAME=""
		for loop in $PATHLIST
		do
			OLDNAME=`echo $loop | awk -F- '{print $1"-"$2}'`
			NEWNAME="$OLDNAME-$NEWNAME"
			rm -f $loop
		done
		diff -uNra before after > ${NEWNAME}${PROJECTPATH//\//_}-$ORDERID-$GHIBIKIID.patch
	fi
	popd

done < result-bug-check.list
#compress
pushd $OUTDIR
    for i in `ls |awk -F '[' '{print $2}'|sed 's/.$//' |sed '/^$/d'|sort |uniq`
     do 
	find -maxdepth 1|grep $i |xargs tar -czvf ${i}.tgz -T
    done
popd

