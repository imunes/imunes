#!/bin/sh

set -e

export MFLAGS=""
export MAKEFLAGS=""

for module in rfee; do
    cd src/ng_$module && make && make install && cd -
done
