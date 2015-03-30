#!/bin/sh

ROOTDIR="."
LIBDIR=""

VER=`uname -r | cut -d "." -f 1`

sh $ROOTDIR/$LIBDIR/prepare_vroot_$VER\.sh $*
