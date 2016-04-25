#!/bin/sh

checkinstall --version > /dev/null 2>&1
if test $? -ne 0; then
    echo "To use this script to create .deb package, please install checkinstall package."
    exit 1
fi

if test "$1" != "-S" && test "$1" != "-R" && test "$1" != "-D"; then
    echo "This script takes one argument:"
    echo "-S	Build a Slackware package"
    echo "-R	Build a RPM package"
    echo "-D	Build a Debian package"
    exit 1
fi

git clone https://github.com/imunes/imunes imunes_deb && cd imunes_deb

if test $? -eq 0; then
    checkinstall $1 --install=no \
	--pkgsource="https://github.com/imunes/imunes" \
	--pkglicense="BSD" \
	--deldesc=no \
	--nodoc \
	--maintainer="denisSal\\<denis.sale@gmail.com\\>" \
	--pkgarch=$(dpkg \
	--print-architecture) \
	--pkgversion="2.0.1" \
	--pkgrelease="SNAPSHOT" \
	--pkgname=imunes \
	--requires="tcl8.6 \(\>= 8.6.0\),libtk8.6 \(\>= 8.6.0\),docker.io \(\>=1.6.1\),openvswitch-switch \(\>=2.0.2\),tcllib \(\>=1.15\),xterm \(\>=297\),wireshark \(\>=1.10.6\),imagemagick \(\>=8.6\),util-linux \(\>=2.20.1\),make \(\>=3.81\)" < ../desc

    if test $? -eq 0; then
	cp imunes_*deb ../
    fi
else
    echo "Fetching source failed..."
    exit 1
fi
