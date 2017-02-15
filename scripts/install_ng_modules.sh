#!/bin/sh

set -e

export MFLAGS=""
export MAKEFLAGS=""

for module in rfee patmat source; do
    cd src/ng_$module && make && make KMODDIR=/boot/kernel install && cd -
done
