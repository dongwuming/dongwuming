#!/bin/bash

#create all-file.list
find -name "*-files.list" | xargs -I file cat file > all-file.list
sort -u all-file.list > aa
mv aa all-file.list

#remove all-before and all-after directory
rm -rf all-before
rm -rf all-after

#create folder list by order
find -maxdepth 1 -type d |awk -F/ '{if ($2!="") print $2}'|sort -t- -k2 -n > after.list
find -maxdepth 1 -type d |awk -F/ '{if ($2!="") print $2}'|sort -t- -k2 -n -r > before.list

mkdir all-before all-after

for loop in `cat after.list`
do
	cp -ra $loop/after/* all-after/
done

for loop in `cat before.list`
do
	cp -ra $loop/before/* all-before/
done

rm -f after.list before.list

#create all-removed-file.list and all-added-file.list
pushd all-before
find . -type f|cut -c3- > ../before-file.list
popd
pushd all-after
find . -type f|cut -c3- > ../after-file.list
popd

diff -u before-file.list after-file.list |grep ^-|grep -v ^---|cut -c2- > all-removed-file.list
diff -u before-file.list after-file.list |grep ^+|grep -v ^+++|cut -c2- > all-added-file.list
rm -f before-file.list after-file.list

#create all-modified-file.list
cp -ra all-after all-modified
for loop in `cat all-added-file.list`
do
	rm -f all-modified/$loop
done

pushd all-modified
find . -type f|cut -c3- > ../all-modified-file.list
popd
rm -rf all-modified

