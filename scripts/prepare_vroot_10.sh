#!/bin/sh

. scripts/prepare_vroot_functions.sh

PACKAGES="$PACKAGES_MINIMAL $PACKAGES_COMMON isc-dhcp43-server thunderbird \
xorp firefox wireshark gnome-themes-standard"

checkArgs $*

if [ $zfs -eq 1 ]; then
    echo "ZFS not supported in 10.1"
    exit 1
fi

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

if [ $offline -eq 0 ]; then
    cp /etc/resolv.conf $VROOT_MASTER/etc
    chroot $VROOT_MASTER /bin/sh -c 'env ASSUME_ALWAYS_YES=YES pkg bootstrap' >> $LOG 2>&1
fi

preparePackagesPkg
installPackagesPkg

if [ $mini -eq 0 ]; then
    installAdditionalTools install_click.sh
fi

configQuagga
configXorp

wiresharkDialog

rm -fr $VROOT_MASTER/tmp/*
rm -fr $VROOT_MASTER/*.txz

rm $VROOT_MASTER/etc/resolv.conf

log "OUT" "Installation successfully finished. Check the log for more \
information: $LOG"
