#!/bin/sh

. scripts/prepare_vroot_functions.sh

PACKAGES_MINIMAL="$PACKAGES_MINIMAL bind918 bind-tools"
#PACKAGES_MINIMAL=`echo $PACKAGES_MINIMAL | sed 's/quagga/frr8/'`
PACKAGES_COMMON=`echo $PACKAGES_COMMON | sed 's/lsof//'`
PACKAGES="$PACKAGES_MINIMAL $PACKAGES_COMMON isc-dhcp44-server isc-dhcp44-client isc-dhcp44-relay \
    sylpheed apache24 apr db18 jansson xorp netsurf midori wireshark gnome-themes-extra sakura vte3 \
    fping dsniff py39-scapy gdk-pixbuf2 gsfonts xpdf openvpn easy-rsa net-snmp"
#PACKAGES=`echo $PACKAGES | sed 's/scapy/py37-scapy/'`
PACKAGES=`echo $PACKAGES | sed -e 's/scapy/py39-scapy/' -e 's/xorp//'`

checkArgs $*

# Start installation
mkdir -p $WORKDIR
cd $WORKDIR
echo -n "" > $LOG

if [ $mini -eq 1 ]; then
    PKGS=${PACKAGES_MINIMAL}
else
    PKGS=${PACKAGES}
fi

if [ $offline -eq 0 ]; then
    fetchBaseOnline
fi

prepareUnionfs
populateFs

preparePackagesPkg
chroot $VROOT_MASTER /bin/sh -c 'env ASSUME_ALWAYS_YES=YES pkg bootstrap' >> $LOG 2>&1
checkPkgVersion
installPackagesPkg

if [ $mini -eq 0 ]; then
    log "OUT" "Installing additional tools..."
    sh $IMUNESDIR/scripts/install_usr_tools.sh >> $LOG 2>&1
    log "OUT" "Installing additional tools done."
fi

#configXorp
mkdir $VROOT_MASTER/usr/local/etc/snmp
mkdir $VROOT_MASTER/usr/local/etc/openvpn

configQuagga

wiresharkGUIfix

configApache24

configApache24 () {
    if [ -d "$VROOT_MASTER/usr/local/etc/apache24/" ]; then
	cd $VROOT_MASTER/usr/local/etc/apache24/
 	cp httpd.conf httpd.conf.backup
  	sed -i -e 's/#ServerName www.example.com:80/ServerName localhost/' /usr/local/etc/apache24/httpd.conf
    else
	log "ERR" "Apache24 not installed in \
	$VROOT_MASTER/usr/local/etc/apache24/\nScript aborted."
	exit 1
    fi

    cd $IMUNESDIR
    cp $ROOTDIR/$LIBDIR/scripts/quaggaboot.sh $VROOT_MASTER/usr/local/bin
    chmod 755 $VROOT_MASTER/usr/local/bin/quaggaboot.sh
}

cleanUnnecessary

log "OUT" "Installation successfully finished. Check the log for more \
information: $LOG"
