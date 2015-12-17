#!/bin/sh

set -e

export MFLAGS=""
export MAKEFLAGS=""

for module in rfee patmat; do
    cd src/ng_$module && make && make install && cd -
done
