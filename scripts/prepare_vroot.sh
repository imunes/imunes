#!/bin/sh

ROOTDIR="."
LIBDIR=""
DOCKER_TEMPLATE="imunes/template"

VER=`uname -r | cut -d "." -f 1`
OS=`uname -s`

if [ "$OS" = "Linux" ]
then
    if [ `uname -m` = "aarch64" ]
    then
        docker pull ${DOCKER_TEMPLATE}:arm64
        docker tag ${DOCKER_TEMPLATE}:arm64 ${DOCKER_TEMPLATE}:latest
    else
        docker pull $DOCKER_TEMPLATE
    fi
else
    sh $ROOTDIR/$LIBDIR/scripts/prepare_vroot_$VER\.sh $*
fi
