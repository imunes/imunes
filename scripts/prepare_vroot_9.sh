#!/bin/sh

# $1 -- ERR / OUT for output and log, or LOG for log only
# $2 -- text to write
log () {
    if [ "$1" = "ERR" ] || [ "$1" = "OUT" ]; then
	printf "$2\n" | tee -a $LOG
    elif [ "$1" = "LOG" ]; then
	printf "$2\n" >> $LOG
    fi
}

if [ `id -u` -ne  0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

ROOTDIR="."
LIBDIR=""

### Set varibles and fetch base manpages and lib files ###
RELEASE=`uname -r | cut -d "-" -f 1`-RELEASE
#RELEASE=9.2-RELEASE
ARCH=`uname -m`
IMUNESDIR=`pwd`

cd ~
HOMEDIR=`pwd`

PREPAREDIR="vroot_prepare"
WORKDIR=/tmp/$PREPAREDIR

VROOT_DIR=/var/imunes
VROOT_SIZE=1G
VROOT_FILE="imunes_vroot"
#VROOT_DEST=$VROOT_DIR/$VROOT_FILE$VROOT_SIZE
VROOT_DEST=$VROOT_DIR/$VROOT_FILE

DISTSERVER="ftp://ftp.de.freebsd.org/"
RELEASE_DIR="pub/FreeBSD/releases/$ARCH/$RELEASE"
if [ "$RELEASE" = "9.2-RELEASE" ]; then
    export PACKAGESITE=$DISTSERVER/pub/FreeBSD/ports/$ARCH/packages-9.2-release/Latest/
else
    export PACKAGESITE=$DISTSERVER/pub/FreeBSD/ports/$ARCH/packages-9-stable/Latest/
fi
FETCH_CMD="fetch"

export BATCH="yes"

BASE_FILES="base"
if [ "$ARCH" = "amd64" ]; then
    BASE_FILES="$BASE_FILES lib32"
fi

PACKAGES_MINIMAL="quagga bash mrouted iftop"
PACKAGES="$PACKAGES_MINIMAL netperf lsof elinks isc-dhcp42-server nmap \
lighttpd akpop3d cone links nano postfix xorp-devel firefox wireshark"

LOG="$WORKDIR/log"

mini=0
offline=0
zfs=0
for arg in $*
do
    case $arg in
	"mini")
	    mini=1;;
	"offline")
	    offline=1;;
	"zfs")
	    zfs=1;;
    esac
done

mkdir -p $WORKDIR
cd $WORKDIR
echo -n "" > $LOG

if [ $mini -eq 1 ]; then
    PKGS=${PACKAGES_MINIMAL}
else
    PKGS=${PACKAGES}
fi

if [ $offline -eq 0 ]; then
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
fi

if [ $zfs -eq 1 ]; then
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
else
    VROOT_MASTER=/var/imunes/vroot
    mkdir -p $VROOT_MASTER
    vroot_present=`ls -A $VROOT_MASTER`
    if [ "$vroot_present" ]; then
	log "ERR" "ERROR: $VROOT_MASTER is already populated.\nTo remove it \
run:\n    # chflags -R noschg $VROOT_MASTER && rm -fr $VROOT_MASTER
or:\n    # sudo sh -c \"chflags -R noschg $VROOT_MASTER && rm -fr $VROOT_MASTER\""
	exit 2
    fi
fi

### Populate zfs ###
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

cp /etc/resolv.conf $VROOT_MASTER/etc

mkdir -p $WORKDIR/packages
mkdir -p $VROOT_MASTER/$WORKDIR/packages
export PKGDIR=$WORKDIR/packages

cd $WORKDIR/packages
missing=""
notmissing=""
INCOMPLETE=0
for file in ${PKGS}; do
    if [ ! -f $file.tbz ]; then
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

err_list=""

log "OUT" "Installing packages..."
if [ $offline -eq 0 ] && [ $INCOMPLETE == 1 ]; then
    for pkg in ${missing}; do
	pkg_add -rFK $pkg -C $VROOT_MASTER >> $LOG 2>&1
	if [ $? -ne 0 ]; then
	    err_list="$pkg $err_list"
	fi
    done
    cp $VROOT_MASTER/$WORKDIR/packages/* $WORKDIR/packages/
fi

cp $WORKDIR/packages/* $VROOT_MASTER/$WORKDIR/packages/
cp $VROOT_MASTER/$WORKDIR/packages/* $VROOT_MASTER/
for pkg in ${notmissing}; do
    pkg_add -F $WORKDIR/packages/$pkg.tbz -C $VROOT_MASTER >> $LOG 2>&1 
    if [ $? -ne 0 ]; then
	err_list="$pkg $err_list"
    fi
done

log "OUT" "Installing packages done."

if [ $mini -eq 0 ]; then
    log "OUT" "Installing additional tools..."
    sh $IMUNESDIR/scripts/install_click.sh $VROOT_MASTER >> $LOG 2>&1
    log "OUT" "Installing additional tools done."
fi

if [ "$err_list" != "" ]; then
    log "OUT" "There were errors installing these packages:\n $err_list"
fi

rm -fr $VROOT_MASTER/tmp/*
rm -fr $VROOT_MASTER/*.tbz

if [ -d "$VROOT_MASTER/usr/local/etc/quagga/" ]; then
    cd $VROOT_MASTER/usr/local/etc/quagga/
    touch zebra.conf ripd.conf ripngd.conf ospfd.conf ospf6d.conf bgpd.conf
    ln -s /boot.conf Quagga.conf
else
    log "ERR" "Quagga not installed in \
$VROOT_MASTER/usr/local/etc/quagga/\nScript aborted."
    exit 1
fi

if [ -f $VROOT_MASTER/usr/local/sbin/xorp_rtrmgr ]; then
    cd $VROOT_MASTER/usr/local/bin/
    ln -s /usr/local/sbin/xorp_rtrmgr
fi

cd $IMUNESDIR
cp $ROOTDIR/$LIBDIR/scripts/quaggaboot.sh $VROOT_MASTER/usr/local/bin
chmod 755 $VROOT_MASTER/usr/local/bin/quaggaboot.sh

rm $VROOT_MASTER/etc/resolv.conf

# Avoid Wireshark 'run as root is dangerous' dialog
mkdir $VROOT_MASTER/root/.wireshark/
echo "privs.warn_if_elevated: FALSE" > $VROOT_MASTER/root/.wireshark/recent_common

if [ $zfs -eq 1 ]; then
    ### Take zfs snapshot ###
    log "OUT" "Creating zfs snapshot..."
    zfs snapshot vroot/vroot@clean
    log "OUT" "done."
fi

log "OUT" "Installation successfully finished. Check the log for more \
information: $LOG"
