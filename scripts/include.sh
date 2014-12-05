#!/bin/bash

# Grab common shell functions
# TODO

source scripts/utils.sh || exit 1

# Figure out where everything is:

[ -z "$TOP" ] && TOP="$(pwd)"
[ -z "$BUILD" ] && BUILD="$TOP/build"

# Directories for downloaded source tarballs and patches.

#[ -z "$PATCHDIR" ] && PATCHDIR="$MYDIR/patches"
[ -z "$SRCDIR" ] && SRCDIR="$TOP/sources"
mkdir -p "$SRCDIR" || dienow

# Put package cache in the control image, so the target system image can
# build from this source.

WORK="$TOP/build/$IMAGENAME" &&
SRCTREE="$WORK" #&&
#blank_tempdir "$WORK" 
