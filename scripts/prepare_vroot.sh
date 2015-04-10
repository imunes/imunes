#!/bin/sh

ROOTDIR="."
LIBDIR=""

VER=`uname -r | cut -d "." -f 1`

sh $ROOTDIR/$LIBDIR/scripts/prepare_vroot_$VER\.sh $*
