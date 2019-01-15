#!/bin/sh

. scripts/prepare_vroot_functions.sh

PACKAGES_MINIMAL="$PACKAGES_MINIMAL bind913"
PACKAGES="$PACKAGES_MINIMAL $PACKAGES_COMMON isc-dhcp44-server isc-dhcp44-client \
    sylpheed xorp firefox wireshark gnome-themes-extra"

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

configQuagga
configXorp

wiresharkGUIfix

cleanUnnecessary

log "OUT" "Installation successfully finished. Check the log for more \
information: $LOG"
