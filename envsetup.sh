#!/bin/bash
#
# usage:
#       under the porting workspace, run:
#       $. /path/to/envsetup.sh [android_build_top] [android_product_out]
#
# description:
#       If android build environment has been setup (i.e. lunch'ed), the value of
#       android_build_top and android_product_out specified here would not be used.
#       If android_build_top or android_product_out is empty, then ?

set -- `getopt "a:l:b:h:p:" "$@"`
android_top=
android_lunch=
ANDROID_BRANCH=
PORT_PRODUCT="Unknown"
help=
while :
do
case "$1" in
    -a) shift; android_top="$1" ;;
    -l) shift; android_lunch="$1";;
    -b) shift; ANDROID_BRANCH="$1";;
    -p) shift; PORT_PRODUCT="$1";;
    -h) help=1;;
    --) break ;;
esac
shift
done
shift

if [ -n "$help" ]; then
    echo "Usage: . /path/to/envsetup [-a android-top [-l lunch-option] [-b android-branch]]"
    return
fi

if [ -n "$android_top" ]; then
    if [ ! -d "$android_top" ]; then
         echo "Failed: $android_top does not exist"
         return
    fi
    PORT_ROOT=$PWD
    cd $android_top
    . build/envsetup.sh
    lunch $android_lunch
    USE_ANDROID_OUT=true
    export USE_ANDROID_OUT
    cd $PORT_ROOT
else
    ANDROID_BRANCH=
fi

#TOPFILE=build/porting.mk
#if [ -f $TOPFILE ] ; then
#   PORT_ROOT=$PWD
#else
#   while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
#       cd .. > /dev/null
#   done
#   if [ -f $PWD/$TOPFILE ]; then
       PORT_ROOT=$PWD
#   else
#       echo "Failed! run me under you porting workspace"
#       return
#   fi
#fi
export PATH=$PORT_ROOT/tools:$PATH

if [ -n "$PORT_ROOT" ]; then
    PORT_BUILD=$PORT_ROOT/build
    PORT_TOOLS=$PORT_ROOT/tools
    ANDROID_TOP=${ANDROID_BUILD_TOP:=$1}
    ANDROID_OUT=${ANDROID_PRODUCT_OUT:=$2}
    export PORT_ROOT PORT_BUILD PORT_TOOLS ANDROID_TOP ANDROID_OUT ANDROID_BRANCH PORT_PRODUCT
    echo "PORT_ROOT       = $PORT_ROOT"
    echo "PORT_BUILD      = $PORT_BUILD"
    echo "PORT_TOOLS      = $PORT_TOOLS"
    echo "PORT_DEVICE     = $PORT_DEVICE"
    echo "ANDROID_TOP     = $ANDROID_TOP"
    echo "ANDROID_OUT     = $ANDROID_OUT"
fi
