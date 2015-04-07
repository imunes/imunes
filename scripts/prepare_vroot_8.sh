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

# $1 -- file to fetch.
fetchFile () {
    $FETCH_CMD $DISTSERVER$RELEASE_DIR/$arg/$1
    if [ $? -ne 0 ]; then
	log "ERR" "ERROR: Couldn't fetch $1 from $DISTSERVER$RELEASE_DIR/$arg/"
	exit 1
    fi
}

# $1 -- checksum file to check/fetch.
haveChecksum () {
    log "LOG" "Is there $1 in \"$arg\" directory?"
    if [ ! -f $1 ]; then
	if [ $offline -eq 0 ]; then
	    fetchFile $1
	else
	    log "ERR" "No $1 in \"$arg\" directory. \nERROR: Script aborted. \
Run in online mode to download $1."
	    exit 1
	fi
    fi
    log "LOG" "$1 found!"
}

# $1 -- MD5 or SHA256 check.
fileChecksum () {
    if [ $1 = "MD5" ]; then
	CHECKSUM="CHECKSUM.MD5"
	COMMAND="md5"
    elif [ $1 = "SHA256" ]; then
	CHECKSUM="CHECKSUM.SHA256"
	COMMAND="sha256"
    fi
    fileToCheck=$2
    if  [ "`cat $CHECKSUM | grep $fileToCheck`" != "`$COMMAND $fileToCheck`" ]; then
	if [ $offline -eq 0 ]; then
	    log "LOG" "$1 checksum problem with $fileToCheck.\nDownloading $fileToCheck \
from server..."
	    fetchFile $fileToCheck
	    if [ "`cat $CHECKSUM | grep $fileToCheck`" != "`$COMMAND $fileToCheck`" ]; then
		log "ERR" "ERROR: $1 checksum problem with $fileToCheck.\nScript \
aborted."
		exit 1
	    fi
	else
	    log "ERR" "ERROR: $1 checksum problem with $fileToCheck.\nRun in online \
mode to download new $fileToCheck\nScript aborted."
	    exit 1
	fi
    fi
}

prepareFiles () {
    for arg in $BASE_FILES
    do
	log "LOG" "Preparing $arg..."

	mkdir -p $arg
	cd $arg

	haveChecksum CHECKSUM.MD5
	haveChecksum CHECKSUM.SHA256

	TMP_VAR=`cat CHECKSUM.MD5 | awk '{print $2}' | sed 's/[\(\)]//g'`

	log "LOG" "Checking file checksums..."
	for file in ${TMP_VAR}
	do
	    if [ ! -f $file ]; then
		if [ $offline -eq 0 ]; then
		    fetchFile $file
		else
		    log "ERR" "ERROR: File $file not downloaded. Use online \
mode to download it."
		    exit 1
		fi
	    fi

	    if [ "$file" != "CHECKSUM.MD5" ] && \
		[ "$file" != "CHECKSUM.SHA256" ]; then
		fileChecksum MD5 $file
		fileChecksum SHA256 $file
	    fi
	done
	log "LOG" "Files checked!"

	cd ..
	log "LOG" "Preparing $arg finished! \
\n---------------------------------------------------------\n\n"
    done
}

unpackAll () {
    for arg in $BASE_FILES
    do
	cd $arg 
	log "OUT" "Unpacking $arg... "
	cat $arg.?? |  tar --unlink -xpzf - -C $VROOT_MASTER
	if [ $? -ne 0 ]; then
	    log "ERR" "ERROR: While unpacking $arg.\nScript aborted."
	    exit 1
	fi
	log "OUT" "Unpacking $arg done."
	cd ..
    done
}

if [ `id -u` -ne  0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

ROOTDIR="."
LIBDIR=""

### Set varibles and fetch base manpages and lib files ###
RELEASE=`uname -r | cut -d "-" -f 1`-RELEASE
#RELEASE=8.3-RELEASE
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

DISTSERVER="ftp://ftp.at.freebsd.org/"
RELEASE_DIR="pub/FreeBSD/releases/$ARCH/$RELEASE"
export PACKAGESITE=$DISTSERVER/$RELEASE_DIR/packages/Latest/
FETCH_CMD="fetch"

export BATCH="yes"

PACKAGES_MINIMAL="quagga bash mrouted iftop"
PACKAGES="$PACKAGES_MINIMAL netperf lsof elinks isc-dhcp42-server nmap \
lighttpd akpop3d cone links nano postfix xorp"

LOG="$WORKDIR/log"

BASE_FILES="base manpages"
if [ "$ARCH" = "amd64" ]; then
    BASE_FILES="$BASE_FILES lib32"
fi

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

prepareFiles

if [ $zfs -eq 1 ]; then
    ZPOOL=`zpool list | grep vroot | cut -d " " -f 1`
### Create zpoll and zfs on a file if there is no vroot pool###
    if [ "$ZPOOL" != "vroot" ]; then
	mkdir -p $VROOT_DIR
	truncate -s $VROOT_SIZE $VROOT_DEST
	zpool create -f vroot $VROOT_DEST
    fi

    ZFS=`zfs list | grep "vroot/vroot" | cut -d " " -f 1`
    if [ "$ZFS" = "vroot/vroot" ]; then
	log "ERR" "ERROR: zfs vroot/vroot already exists. remove it so that \
IMUNES can populate it. \nTo remove it run:\n    # zfs destroy -r \
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
run:\n    # chflags -R noschg $VROOT_MASTER && rm -fr $VROOT_MASTER"
	exit 2
    fi
fi

### Populate fs ###
cd $WORKDIR

unpackAll

cp /etc/resolv.conf $VROOT_MASTER/etc

mkdir -p $WORKDIR/packages
mkdir -p $VROOT_MASTER/$WORKDIR/packages
export PKGDIR="$WORKDIR/packages"

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
    log "ERR" "\nThese packages are missing from $WORKDIR/packages and \
will not be installed:\n$missing\n"
fi

err_list=""

log "OUT" "Installing packages..."
if [ $offline -eq 0 ] && [ $INCOMPLETE == 1 ]; then
    for pkg in ${missing}; do
	pkg_add -rK $DISTSERVER$RELEASE_DIR/packages/Latest/$pkg.tbz -C \
	$VROOT_MASTER >> $LOG
	if [ $? -ne 0 ]; then
	    err_list="$pkg $err_list"
	fi
    done
    cp -r $VROOT_MASTER/$WORKDIR/packages $WORKDIR/
fi

cp -r $WORKDIR/packages $VROOT_MASTER/$WORKDIR/
for pkg in ${notmissing}; do
    pkg_add -F $WORKDIR/packages/$pkg.tbz -C $VROOT_MASTER >> $LOG
    if [ $? -ne 0 ]; then
	err_list="$pkg $err_list"
    fi
done
log "OUT" "Installing packages done."

log "ERR" ""
if [ "$err_list" != "" ]; then
    log "ERR" "There were errors installing these packages:\n$err_list\n"
fi

rm -fr $VROOT_MASTER/tmp/*

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

rm $VROOT_MASTER/etc/resolv.conf

if [ $zfs -eq 1 ]; then
    ### Take zfs snapshot ###
    log "OUT" "Creating zfs snapshot..."
    zfs snapshot vroot/vroot@clean
    log "OUT" "done."
fi

log "LOG" ""
log "OUT" "Installation successfully finished. Check the log for more \
information: $LOG"
