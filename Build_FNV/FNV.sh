#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# select device and prepare varibles
BUILD_ROOT=~/$1
cd $BUILD_ROOT
. build/envsetup.sh
lunch fnv_$2-userdebug

# create log dir if not already present
if test ! -d "$ANDROID_PRODUCT_OUT"
    echo "$ANDROID_PRODUCT_OUT doesn't exist, creating now"
    then mkdir -p "$ANDROID_PRODUCT_OUT"
fi

# build
make -j$(($(grep processor /proc/cpuinfo | wc -l) * 2)) bacon 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log

# clean out of previous zip
ZIP=$(tail -2 "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')

# finish
echo "$2 build complete"

scp $ZIP website@androtransfer.com:~/www/androtransfer.com/public_html/sixstringsg/$2

if test -x irc ; then
     ./irc New build is up for $2 get it at http://xfer.in/?developer=sixstringsg&folder=$2
ssh antioch@sixstringsg.dyndns.org DISPLAY=:0 notify-send $2 build complete!
