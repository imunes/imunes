#!/bin/sh

if [ `id -u` -ne  0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

# $1 -- ERR / OUT for output and log, or LOG for log only
# $2 -- text to write
log () {
    if [ "$1" = "ERR" ] || [ "$1" = "OUT" ]; then
	printf "$2\n" | tee -a $LOG
    elif [ "$1" = "LOG" ]; then
	printf "$2\n" >> $LOG
    fi
}

# GLOBAL FOR EVERY VERSION
##########################
# directories
ROOTDIR="."
LIBDIR=""
IMUNESDIR=`pwd`
cd ~
HOMEDIR=`pwd`

# FreeBSD version and architecture
RELEASE=`uname -r|sed s/STABLE/RELEASE/|sed s/-p.*//`
if [ "$TESTING" = "1" ]; then
	RELEASE=`uname -r`
fi
RELEASE_NUM=`echo $RELEASE | cut -d'.' -f1`
RELEASE_VER=`echo $RELEASE | cut -d'.' -f2 | cut -d'-' -f1`
ARCH=`uname -m`
REPO="release_$RELEASE_VER"
if [ "$TESTING" = "1" ]; then
	REPO="latest"
fi

# unionfs settings
PREPAREDIR="vroot_prepare"
WORKDIR=/tmp/$PREPAREDIR

# fetch command
FETCH_CMD="fetch"

# postfix installation skip question
export BATCH="yes"

# log location
LOG="$WORKDIR/log"

VROOT_DIR=/var/imunes

# packages for installation
PACKAGES_MINIMAL="pkg quagga bash mrouted iftop"
PACKAGES_COMMON="netperf lsof elinks nmap lighttpd akpop3d links nano postfix \
   dsniff scapy p0f ettercap tcpreplay hping strongswan"

##########################

# package management
DISTSERVER="ftp://ftp.freebsd.org"
RELEASE_DIR="/pub/FreeBSD/releases/$ARCH/$RELEASE"
if [ "$TESTING" = "1" ]; then
	RELEASE_DIR="/pub/FreeBSD/snapshots/$ARCH/$RELEASE"
fi

# pkg repository
PKGREPO="http://pkg.freebsd.org/FreeBSD:$RELEASE_NUM:i386/$REPO"
export PKG_CACHEDIR=$WORKDIR/packages

BASE_FILES="base"
if [ "$ARCH" = "amd64" ]; then
    BASE_FILES="$BASE_FILES lib32"
    PKGREPO="http://pkg.freebsd.org/FreeBSD:$RELEASE_NUM:amd64/$REPO"
fi

##########################

mini=0
offline=0
checkArgs() {
    for arg in $*; do
	case $arg in
	    "mini")
		mini=1;;
	    "offline")
		offline=1;;
	esac
    done
}

##########################

checkPkgVersion() {
    vroot_pkg=`chroot $VROOT_DIR/vroot /bin/sh -c 'pkg info pkg' | head -n1`
    real_pkg=`pkg info pkg | head -n1`
    if [ "$vroot_pkg" = "$real_pkg" ]; then
	return 0
    fi
    lower_version=`printf "$vroot_pkg\n$real_pkg" | sort -V | head -n1`
    if [ "$lower_version" = "$real_pkg" ]; then
	log "ERR" "Your pkg version is older than the virtual root one, please update it:"
	log "ERR" "\t# pkg install pkg"
	exit 1
    fi
}

fetchBaseOnline () {
    if [ ! -f MANIFEST ]; then
	$FETCH_CMD $DISTSERVER$RELEASE_DIR/MANIFEST
    fi

    for file in ${BASE_FILES}; do
	file=$file.txz
	if [ ! -f $file ]; then
	    $FETCH_CMD $DISTSERVER$RELEASE_DIR/$file
	fi
	if  [ "`cat MANIFEST | grep $file | awk '{print $2}'`" != "`sha256 \
	    $file | awk '{print $4}'`" ]; then
	    $FETCH_CMD $DISTSERVER$RELEASE_DIR/$file
	fi
	if  [ "`cat MANIFEST | grep $file | awk '{print $2}'`" != "`sha256 \
	    $file | awk '{print $4}'`" ]; then
	    log "ERR" "Checksum problem with $file.\nScript aborted."
	    exit 1
	fi
    done
}

prepareUnionfs () {
    VROOT_MASTER=/var/imunes/vroot
    mkdir -p $VROOT_MASTER
    vroot_present=`ls -A $VROOT_MASTER`
    if [ "$vroot_present" ]; then
	log "ERR" "ERROR: $VROOT_MASTER is already populated.\nTo remove it \
run:\n	# make remove_vroot\n \
or:\n	# imunes -f -p"
	exit 2
    fi
}

### Populate fs ###
populateFs () {
    cd $WORKDIR

    for file in $BASE_FILES; do 
	if [ -f "$file.txz" ]; then
	    log "OUT" "Unpacking $file..."
	    tar -xf $file.txz -C $VROOT_MASTER
	    if [ $? -ne 0 ]; then
		log "ERR" "ERROR: While unpacking $file.txz\nScript aborted."
		exit 1
	    fi
	    log "OUT" "Unpacking $file done."
	else
	    log "ERR" "ERROR: no $file.txz in $WORKDIR. Run in online mode to download \
it.\nScript aborted."
	    exit 1
	fi
    done
}

# prepare packages for pkg install
preparePackagesPkg () {
    mkdir -p $WORKDIR/packages
    cd $WORKDIR/packages

    missing=""
    notmissing=""
    INCOMPLETE=0
    for file in ${PKGS}; do
	ls $file*.txz > /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    INCOMPLETE=1
	    missing="$file $missing"
	else
	    notmissing="$file $notmissing"
	fi
    done

    if [ $offline -eq 1 ] && [ $INCOMPLETE -eq 1 ]; then
	log "OUT" "These packages are missing from $WORKDIR/packages and will not \
be installed:\n $missing"
    fi

    if [ $INCOMPLETE -eq 0 ]; then
	offline=1
	log "OUT" "All packages are in $WORKDIR/packages and will \
be installed from the local repository imunes."
    fi

    mkdir -p $VROOT_MASTER/usr/local/etc/pkg/repos/
    echo "FreeBSD: { enabled: no }" > $VROOT_MASTER/usr/local/etc/pkg/repos/FreeBSD.conf
    if [ $offline -eq 1 ]; then
	mkdir -p $VROOT_MASTER/$WORKDIR/packages

	mount -t nullfs $WORKDIR $VROOT_MASTER/$WORKDIR

cat >> $VROOT_MASTER/usr/local/etc/pkg/repos/imunes.conf <<_EOF_
imunes: {
    url: "file:///tmp/vroot_prepare/packages",
    enabled: yes
}
_EOF_

    else
	if test -f /etc/resolv.conf; then
	    cp /etc/resolv.conf $VROOT_MASTER/etc
	fi
	cat >> $VROOT_MASTER/usr/local/etc/pkg/repos/release.conf <<_EOF_
release: {
    url: "$PKGREPO",
    enabled: yes
}
_EOF_

    fi
}

# install packages with pkg install
installPackagesPkg () {
    export PKG_CACHEDIR=$WORKDIR/packages

    log "OUT" "Installing packages..."

    err_list=""
    if [ $offline -eq 0 ]; then
	pkg -c $VROOT_MASTER update -r release >> $LOG 2>&1
	for pkg in ${PKGS}; do
	    pkg -c $VROOT_MASTER install -fyUr release $pkg >> $LOG 2>&1
	    if [ $? -ne 0 ]; then
		err_list="$pkg $err_list"
	    fi
	done

	for file in `find $VROOT_MASTER/$WORKDIR/packages/ -maxdepth 1 -type l`; do
	    unlink $file
	done

	cp -R $VROOT_MASTER/$WORKDIR/packages/* $WORKDIR/packages/
	pkg repo $WORKDIR/packages/
    else
	pkg -c $VROOT_MASTER update -r imunes >> $LOG 2>&1
	for pkg in ${PKGS}; do
	    pkg -c $VROOT_MASTER install -fyUr imunes $pkg >> $LOG 2>&1
	    if [ $? -ne 0 ]; then
		err_list="$pkg $err_list"
	    fi
	done

	umount $VROOT_MASTER/$WORKDIR
    fi

    log "OUT" "Installing packages done."
    cd $IMUNESDIR

    if [ "$err_list" != "" ]; then
	log "OUT" "There were errors installing these packages:\n $err_list"
    fi
}

configQuagga () {
    if [ -d "$VROOT_MASTER/usr/local/etc/quagga/" ]; then
	cd $VROOT_MASTER/usr/local/etc/quagga/
	touch zebra.conf ripd.conf ripngd.conf ospfd.conf ospf6d.conf bgpd.conf isisd.conf
	ln -s /boot.conf Quagga.conf
    else
	log "ERR" "Quagga not installed in \
$VROOT_MASTER/usr/local/etc/quagga/\nScript aborted."
	exit 1
    fi

    cd $IMUNESDIR
    cp $ROOTDIR/$LIBDIR/scripts/quaggaboot.sh $VROOT_MASTER/usr/local/bin
    chmod 755 $VROOT_MASTER/usr/local/bin/quaggaboot.sh
}

configXorp () {
    if [ -f $VROOT_MASTER/usr/local/sbin/xorp_rtrmgr ]; then
	cd $VROOT_MASTER/usr/local/bin/
	ln -s /usr/local/sbin/xorp_rtrmgr
    fi
}

wiresharkGUIfix () {
    # Avoid Wireshark 'run as root is dangerous' dialog
    mkdir $VROOT_MASTER/root/.wireshark/
    echo "privs.warn_if_elevated: FALSE" > $VROOT_MASTER/root/.wireshark/recent_common

    # Make Wireshark's main upper and middle window panes bigger on first start
    echo "gui.geometry_main_upper_pane: 135" > $VROOT_MASTER/root/.wireshark/recent
    echo "gui.geometry_main_lower_pane: 200" >> $VROOT_MASTER/root/.wireshark/recent
}

cleanUnnecessary () {
    rm -fr $VROOT_MASTER/tmp/*

    rm -f $VROOT_MASTER/etc/resolv.conf

    rm -rf $VROOT_MASTER/usr/local/etc/pkg/repos
}
