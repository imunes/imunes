#!/bin/sh

set -e

export MFLAGS=""
export MAKEFLAGS=""

VROOT_MASTER=/var/imunes/vroot
IMUNESDIR=`pwd`

tayga="http://www.litech.org/tayga/tayga-0.9.2.tar.bz2"
workdir="/tmp/vroot_prepare/tools"

mkdir -p $workdir

# Build and install tayga
echo "Installing tayga..."
cd $workdir

if [ ! -f `basename $tayga` ]; then
    fetch $tayga
fi

tar xf `basename $tayga`
cd `find . -type d -name 'tayga*'`
patch < $IMUNESDIR/src/patches/tayga_fbsd_patch.diff
./configure && make

cp tayga $VROOT_MASTER/usr/local/bin
echo "Installing tayga done."
