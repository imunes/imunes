#!/bin/sh

ROOTDIR="."
LIBDIR=""

VER=`uname -r | cut -d "." -f 1`

# FIXME: make this work on linux
sh $ROOTDIR/$LIBDIR/scripts/prepare_vroot_$VER\.sh $*
