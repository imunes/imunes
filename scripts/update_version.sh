#!/bin/sh

ROOTDIR="/usr/local"
LIBDIR="lib/imunes"
ver_file="$ROOTDIR/$LIBDIR/VERSION"

# check whether this is a git repository
git status > /dev/null 2>&1

if [ "$?" -eq 0 ]; then
    for attr in "%h" "%ai" "%ae"; do
	value=`git log --format="$attr" -n 1`
	sed -i"" -e "s/\$Format:$attr\$$/$value/" $ver_file
    done
fi
