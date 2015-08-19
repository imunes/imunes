#!/bin/sh

# Command that is used to install click modular router software into the
# virtual node template. The template is fetched form:
# http://imunes.net/dl/click.tar.gz

export MFLAGS=""
export MAKEFLAGS=""

click="click.tar.gz"
workdir="/tmp/vroot_prepare/tools"

if [ "$1" == "" ]; then
    echo "The command shoud be called with the destination vroot folder:"
    echo "# sh install_click.sh /var/imunes/vroot"
    exit
fi

VERSION=`uname -r | cut -d'-' -f1 | cut -d'.' -f1`

if [ $VERSION -ge 10 ]; then
    export LDFLAGS="-L/usr/lib -lexecinfo"
fi

mkdir -p $workdir
cd $workdir
if [ ! -f $click ]; then 
    fetch http://imunes.net/dl/$click
fi
tar xf $click
cd click
./configure --prefix=$1/usr/local --enable-etherswitch && make install-userlevel
