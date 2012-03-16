#!/bin/bash

# This script is simply for me to automate the building and uploading #
# of CodeNameAndroid for the devices that I am responsible for. This  #
# is for releases, not for nightlies. 				      #

# Starting Timer for build
START=$(date +%s)
DEVICE="$1"
ADDITIONAL="$2"

# Clean out old builds
cd ~/CNA
make clobber

# Sync Source, not too fast though, I don't want to have to restart   #
# it if it hangs.                                                     #
repo sync -j10

# Make the builds.
. build/envsetup.sh
lunch cna_captivatemtd-userdebug
make -j7 squish CNA_RELEASE=true | tee cna_captivate.log
lunch cna_fascinatemtd-userdebug
make -j7 squish CNA_RELEASE=true | tee cna_fascinate.log
lunch cna_galaxysmtd-userdebug
make -j7 squish CNA_RELEASE=true | tee cna_galaxys.log
lunch cna_vibrantmtd-userdebug
make -j7 squish CNA_RELEASE=true | tee cna_vibrant.log

# Set variables to grab zip names
CAPTIVATE={cat cna_captivate.log | grep .zip | tail -1 | awk '{print $2}'}
FASCINATE={cat cna_fascinate.log | grep .zip | tail -1 | awk '{print $2}'}
GALAXYS={cat cna_galaxys.log | grep .zip | tail -1 | awk '{print $2}'}
VIBRANT={cat cna_vibrant.log | grep .zip | tail -1 | awk '{print $2}'}

#Upload to goo
scp -P 2222 $CAPTIVATE glitch@upload.goo-inside.me:~/public_html/CNA/Captivate
scp -P 2222 $FASCINATE glitch@upload.goo-inside.me:~/public_html/CNA/Fascinate
scp -P 2222 $GALAXYS glitch@upload.goo-inside.me:~/public_html/CNA/GalaxyS
scp -P 2222 $VIBRANT glitch@upload.goo-inside.me:~/public_html/CNA/Vibrant

#Upload to Exynos
cp $CAPTIVATE /home/website/www/cna.exynos.co/public_html/release/captivatemtd
cp $FASCINATE /home/website/www/cna.exynos.co/public_html/release/fascinatemtd
cp $GALAXYS /home/website/www/cna.exynos.co/public_html/release/galaxysmtd
cp $VIBRANT /home/website/www/cna.exynos.co/public_html/release/vibrantmtd

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "Elapsed: "
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
printf "%d sec(s)\n" $E_SEC

#All done!
echo finished with the build! Don't forget to tell XDA!