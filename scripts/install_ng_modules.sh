#!/bin/sh

set -e

export MFLAGS=""
export MAKEFLAGS=""

if test -z "$KMODDIR"; then
    export KMODDIR="/boot/kernel"
fi

for module in rfee patmat source; do
    cd src/ng_$module && make && make install && cd -
done
