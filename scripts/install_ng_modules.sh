#!/bin/sh

set -e

export MFLAGS=""
export MAKEFLAGS=""

if test -z "$KMODDIR"; then
	export KMODDIR="/boot/kernel"
fi

if test -z "$(ls /usr/src/ 2>/dev/null)"; then
	echo 'Kernel source not installed in /usr/src/. Skipping ng_* module building.'
	exit 0
fi

for module in rfee patmat source; do
	cd src/ng_$module && make && make install && cd -
done
