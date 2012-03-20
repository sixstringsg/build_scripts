#!/bin/bash

# This script is to make my life easier when building CM9 kangs. It  #
# will build for all the Galaxy S devices, but can be modified for   #
# others. It will read cherrypicks from the included cherry file.    #

# Starting Timer for build
START=$(date +%s)
DEVICE="$1"
ADDITIONAL="$2"

# Clean out old builds
cd ~/CM9
make clobber

# Sync Source, not too fast though, I don't want to have to restart   #
# it if it hangs.                                                     #
repo sync -j10

# Check on a cherry-pick file, if it exists, run it. If not, build a  #
# clean build.                                                        #
if test -x cherry ; then
	echo cherry-pick file found, picking cherries now!
	./cherry
else
	echo no cherries found, running a clean build
fi

# Make the builds.
. build/envsetup.sh
lunch cm_captivatemtd-userdebug
make -j7 bacon | tee cm9_captivate.log
lunch cm_fascinatemtd-userdebug
make -j7 bacon | tee cm9_fascinate.log
lunch cm_galaxysmtd-userdebug
make -j7 bacon | tee cm9_galaxys.log
lunch cm_vibrantmtd-userdebug
make -j7 bacon | tee cm9_vibrant.log

# Set variables to grab zip names
CAPTIVATE=$(tail cm9_captivate.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
FASCINATE=$(tail cm9_fascinate.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
GALAXYS=$(tail cm9_galaxys.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
VIBRANT=$(tail cm9_vibrant.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')

#Upload to goo
scp -P 2222 $CAPTIVATE glitch@upload.goo-inside.me:~/public_html/CM9_Kangs/Captivate
scp -P 2222 $FASCINATE glitch@upload.goo-inside.me:~/public_html/CM9_Kangs/Fascinate
scp -P 2222 $GALAXYS glitch@upload.goo-inside.me:~/public_html/CM9_Kangs/GalaxyS
scp -P 2222 $VIBRANT glitch@upload.goo-inside.me:~/public_html/CM9_Kangs/Vibrant

#Upload to Exynos
cp $CAPTIVATE /home/website/www/nightly.exynos.co/public_html/release/captivate
cp $FASCINATE /home/website/www/nightly.exynos.co/public_html/release/fascinate
cp $GALAXYS /home/website/www/nightly.exynos.co/public_html/release/galaxys
cp $VIBRANT /home/website/www/nightly.exynos.co/public_html/release/vibrant

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "Elapsed: "
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
printf "%d sec(s)\n" $E_SEC

#All done!
echo finished with the build! Don't forget to tell XDA!
