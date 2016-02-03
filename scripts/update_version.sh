#!/bin/sh

if test -z "$ROOTDIR"; then
    ROOTDIR="/usr/local"
fi
LIBDIR="lib/imunes"

ver_file="$ROOTDIR/$LIBDIR/VERSION"

# check whether this is a git repository
git status > /dev/null 2>&1

if [ "$?" -eq 0 ]; then
    tag=`git describe --abbrev=0 --tags`
    if test `uname -s` = "Linux"; then
	sed -i'' "s/VERSION: .*/VERSION: $tag/" $ver_file
    else
	sed -i '' "s/VERSION: .*/VERSION: $tag/" $ver_file
    fi
    for attr in "%h" "%ai" "%ae"; do
	value=`git log --format="$attr" -n 1`
	if test `uname -s` = "Linux"; then
	    sed -i'' -e "s/\$Format:$attr\$$/$value/" $ver_file
	else
	    sed -i '' -e "s/\$Format:$attr\$$/$value/" $ver_file
	fi
    done
fi
