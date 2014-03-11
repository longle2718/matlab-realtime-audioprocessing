#!/bin/bash
# Automate cropping the TIDIGIT adults database to only contain single digits

for D in `find TIDIGIT/train/man/* -type d`
do
	#echo $D
	cd $D
	for F in `find [1-9]?.wav`
	do
		#echo ${F:0:1}
		cp $F ../../../../TIDIGIT_adults_crop/train/${F:0:1}/`basename $D`.wav
	done
	cd -
done
 
for D in `find TIDIGIT/train/woman/* -type d`
do
	#echo $D
	cd $D
	for F in `find [1-9]?.wav`
	do
		#echo ${F:0:1}
		cp $F ../../../../TIDIGIT_adults_crop/train/${F:0:1}/`basename $D`.wav
	done
	cd -
done

for D in `find TIDIGIT/test/man/* -type d`
do
	#echo $D
	cd $D
	for F in `find [1-9]?.wav`
	do
		#echo ${F:0:1}
		cp $F ../../../../TIDIGIT_adults_crop/test/${F:0:1}/`basename $D`.wav
	done
	cd -
done
 
for D in `find TIDIGIT/test/woman/* -type d`
do
	#echo $D
	cd $D
	for F in `find [1-9]?.wav`
	do
		#echo ${F:0:1}
		cp $F ../../../../TIDIGIT_adults_crop/test/${F:0:1}/`basename $D`.wav
	done
	cd -
done
