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
RELEASE=`uname -r|sed s/STABLE/RELEASE/`
RELEASE_NUM=`echo $RELEASE | cut -d'.' -f1`
RELEASE_VER=`echo $RELEASE | cut -d'.' -f2 | cut -d'-' -f1`
ARCH=`uname -m`
REPO=latest

echo "10.2-RELEASE" | grep -q $RELEASE
if [ $? -eq 0 ]; then
    REPO="release_$RELEASE_VER"
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

# ZFS settings
VROOT_DIR=/var/imunes
VROOT_SIZE=1G
VROOT_FILE="imunes_vroot"
VROOT_DEST=$VROOT_DIR/$VROOT_FILE

# packages for installation
PACKAGES_MINIMAL="pkg quagga bash mrouted iftop"
PACKAGES_COMMON="netperf lsof elinks nmap lighttpd akpop3d links nano postfix \
   dsniff scapy p0f nmap ettercap tcpreplay hping strongswan" # isc-dhcp42-server

##########################

# package management
DISTSERVER="ftp://ftp.freebsd.org"
RELEASE_DIR="/pub/FreeBSD/releases/$ARCH/$RELEASE"

# pkg repository
PKGREPO="http://pkg.freebsd.org/freebsd:$RELEASE_NUM:x86:32/$REPO"
export PKG_CACHEDIR=$WORKDIR/packages

#export PACKAGESITE=$DISTSERVER/$RELEASE_DIR/packages/Latest/

BASE_FILES="base"
if [ "$ARCH" = "amd64" ]; then
    BASE_FILES="$BASE_FILES lib32"
    PKGREPO="http://pkg.freebsd.org/freebsd:$RELEASE_NUM:x86:64/$REPO"
fi

##########################

mini=0
offline=0
zfs=0
checkArgs() {
    for arg in $*; do
	case $arg in
	    "mini")
		mini=1;;
	    "offline")
		offline=1;;
	    "zfs")
		zfs=1;;
	esac
    done
}

##########################

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

prepareZfs () {
    ZPOOL=`zpool list | grep vroot | cut -d " " -f 1`
### Create zpool and zfs on a file if there is no vroot pool###
    if [ "$ZPOOL" != "vroot" ]; then
	mkdir -p $VROOT_DIR
	truncate -s $VROOT_SIZE $VROOT_DEST
	zpool create -f vroot $VROOT_DEST
    fi

    ZFS=`zfs list | grep "vroot/vroot" | cut -d " " -f 1`
    if [ "$ZFS" = "vroot/vroot" ]; then
	log "ERR" "ERROR: zfs vroot/vroot already exists. Remove it so that \
IMUNES can populate it.\nTo remove it run:\n    # zfs destroy -r \
vroot/vroot"
	exit 2
    fi

    zfs create vroot/vroot
    VROOT_MASTER=/vroot/vroot
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

# prepare packages for pkg_add
preparePackages () {
    mkdir -p $WORKDIR/packages
    mkdir -p $VROOT_MASTER/$WORKDIR/packages
    export PKG_CACHEDIR=$WORKDIR/packages

    cd $WORKDIR/packages
    missing=""
    notmissing=""
    INCOMPLETE=0
    for file in ${PKGS}; do
	if [ ! -f $file.txz ]; then
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

# install packages with pkg_add
installPackages () {
    err_list=""
    log "OUT" "Installing packages..."
    if [ $offline -eq 0 ] && [ $INCOMPLETE -eq 1 ]; then
	for pkg in ${missing}; do
	    pkg_add -rFK $pkg -C $VROOT_MASTER >> $LOG 2>&1
	    if [ $? -ne 0 ]; then
		err_list="$pkg $err_list"
	    fi
	done
	cp -R $VROOT_MASTER/$WORKDIR/packages/* $WORKDIR/packages/
    fi

    cp -R $WORKDIR/packages/* $VROOT_MASTER/$WORKDIR/packages/
    cp -R $VROOT_MASTER/$WORKDIR/packages/* $VROOT_MASTER/
    for pkg in ${notmissing}; do
	pkg_add -F $WORKDIR/packages/$pkg.tbz -C $VROOT_MASTER >> $LOG 2>&1 
	if [ $? -ne 0 ]; then
	    err_list="$pkg $err_list"
	fi
    done

    log "OUT" "Installing packages done."
    cd $IMUNESDIR

    if [ "$err_list" != "" ]; then
	log "OUT" "There were errors installing these packages:\n $err_list"
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
	touch zebra.conf ripd.conf ripngd.conf ospfd.conf ospf6d.conf bgpd.conf
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

# Avoid Wireshark 'run as root is dangerous' dialog
wiresharkDialog () {
    mkdir $VROOT_MASTER/root/.wireshark/
    echo "privs.warn_if_elevated: FALSE" > $VROOT_MASTER/root/.wireshark/recent_common
}

### Take zfs snapshot ###
takeZfsSnapshot () {
    log "OUT" "Creating zfs snapshot..."
    zfs snapshot vroot/vroot@clean
    log "OUT" "done."
}

cleanUnnecessary () {
    rm -fr $VROOT_MASTER/tmp/*

    rm -f $VROOT_MASTER/etc/resolv.conf

    rm -rf $VROOT_MASTER/usr/local/etc/pkg/repos
}
