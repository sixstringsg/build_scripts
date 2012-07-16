#!/bin/bash

THREADS=$(expr 2 + $(grep processor /proc/cpuinfo | wc -l))
LOADT=$((2+`awk '{print $3}' /proc/loadavg|awk '{printf "%.0f\n", $1}'`))
BUILD=`echo $1 |tr '[:lower:]' '[:upper:]'`
LBUILD=`echo $BUILD |tr '[:upper:]' '[:lower:]'`
DIR=/home/chris41g/android/$BUILD
DONE=$DIR/done
DEVICE=$DIR/device/samsung/epic4gtouch
OUT=$DIR/out/target/product/epic4gtouch
MAKE="make V=1 -j -l${LOADT} showcommands"
NOW=`date +%m%d`
ISGOO="${2}"
RELVER="${3}"
process_gummy()
{
	if [ ${BUILD} = "GUMMY" ]; then
		LBUILD="Gummy"
	fi
}
env_setup()
{
	cd $DIR
		. build/envsetup.sh && breakfast ${LBUILD}"_epic4gtouch-userdebug"
}

clean_up()
{
    rm -rf $DONE
    mkdir $DONE
	cd $DIR
	    $MAKE installclean
	    $MAKE clobber
}

repo_sync()
{
	cd $DIR
    	repo sync -j24
}

extras()
{
	if [ ${LBUILD} = "cm" ]; then
		echo "Get prebuilts!"
		$DIR/vendor/cm/get-prebuilts
	elif [ ${LBUILD} = "Gummy" ]; then
		echo "Get prebuilts!"
		$DIR/vendor/Gummy/get-prebuilts
	fi
    $DIR/e4gttools/apply.sh
}

build_it()
{
	cd $DIR
	if [ ${LBUILD} = "Gummy" ]; then
		$MAKE gummy
	else
    	$MAKE bacon
	fi
}

post_process()
{
	cp $OUT/${LBUILD}*epic4gtouch*.zip $DONE/
	cd $DONE
		for FILE in ${LBUILD}*epic4gtouch*.zip; do
			unzip $FILE system/build.prop
			echo "" >> $DONE/system/build.prop
			echo "# Goo-Manager Info" >> $DONE/system/build.prop
			echo "ro.goo.developerid=chris41g" >> $DONE/system/build.prop
			echo "ro.goo.rom="${LBUILD}"_epic4gtouch" >> $DONE/system/build.prop
			echo "ro.goo.version="$NOW  >> $DONE/system/build.prop
			zip -r $FILE system/build.prop
		done
}

resign_zip()
{
	cd ~/bin
		for FILE in ${DONE}/${LBUILD}_epic4gtouch_*.zip; do
			java -classpath testsign.jar testsign "${DONE}/$(basename ${FILE} .zip).zip" "${DONE}/$(basename ${FILE} .zip)${RELVER}.zip"
		done
}

md5_sum()
{
	if [ ${ISGOO} = "goo" ]; then
		cd $DONE
			for FILE in ${LBUILD}*epic4gtouch*.zip; do
				md5sum $FILE > ${FILE}.md5sum
			done
	else
		cd $OUT
			for FILE in ${LBUILD}*epic4gtouch*.zip; do
				md5sum $FILE > ${FILE}.md5sum
			done
	fi
}

upload_goo()
{
	cd $DONE
	if [ ${LBUILD} = "cm" ]; then
		scp -P2222 ${DONE}/${LBUILD}*.zip chris41g@goo.im:public_html/CM/
		scp -P2222 ${DONE}/${LBUILD}*.zip.md5sum chris41g@goo.im:public_html/CM/
	elif [ ${LBUILD} = "aokp" ]; then
		scp -P2222 ${DONE}/${LBUILD}*.zip chris41g@goo.im:public_html/AOKP/
		scp -P2222 ${DONE}/${LBUILD}*.zip.md5sum chris41g@goo.im:public_html/AOKP/
	elif [ ${LBUILD} = "gummy" ]; then
		scp -P2222 ${DONE}/${LBUILD}*.zip chris41g@goo.im:public_html/GUMMY/
		scp -P2222 ${DONE}/${LBUILD}*.zip.md5sum chris41g@goo.im:public_html/GUMMY/
fi
}

main()
{
	exec > >(tee ${DONE}/buildlog.txt) 2>&1
	process_gummy
	repo_sync
		export USE_CCACHE=1 CM_EXPERIMENTAL=1 CM_EXTRAVERSION=${RELVER}
	if [ ${BUILD} = "AOKP" ]; then
		cd vendor/aokp
		git reset --hard HEAD
		git remote rm origin
		git remote rm upstream
		git remote add upstream git://github.com/AOKP/vendor_aokp_ics.git
		git remote add origin git@github.com:EpicAOSP/vendor_aokp_ics.git -m ics
		git fetch upstream
		git merge upstream/ics
		git push origin
	fi
	env_setup
	clean_up
	extras
	build_it
	rm $OUT/*.chris41g.zip
	if [ ${ISGOO} = "goo" ]; then
		post_process
		resign_zip
		md5_sum
		upload_goo
	else
		md5_sum
	fi
    echo " All done..."
}
cd $DIR
echo "Building? = "${BUILD}
echo "Uploading to goo? = "${ISGOO}
echo "Release Ver? = "${RELVER}
main
