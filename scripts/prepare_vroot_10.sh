#!/bin/sh

. scripts/prepare_vroot_functions.sh

PACKAGES="$PACKAGES_MINIMAL $PACKAGES_COMMON isc-dhcp43-server sylpheed \
xorp firefox wireshark gnome-themes-standard bind99"

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

preparePackagesPkg
chroot $VROOT_MASTER /bin/sh -c 'env ASSUME_ALWAYS_YES=YES pkg bootstrap' >> $LOG 2>&1
installPackagesPkg

if [ $mini -eq 0 ]; then
    installAdditionalTools install_click.sh
fi

configQuagga
configXorp

wiresharkDialog

cleanUnnecessary

log "OUT" "Installation successfully finished. Check the log for more \
information: $LOG"
