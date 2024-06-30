#!/bin/sh

images="cloud.gif frswitch.gif host.gif hub.gif \
ipfirewall.gif lanswitch.gif pc.gif rj45.gif router.gif ext.gif"

sfact="70%"
tfact="75%"
tsize="40x40"

small_opt="-adaptive-resize $sfact"
tiny_opt="-adaptive-resize $tfact -gravity center -background none -extent $tsize"

for img in $images; do
    if [ ! -e small/$img ] || [ normal/$img -nt small/$img ]; then
	magick $small_opt normal/$img small/$img
	echo "Converting normal/$img to small."
    fi
    if [ ! -e tiny/$img ] || [ normal/$img -nt tiny/$img ]; then
	magick $tiny_opt normal/$img tiny/$img
	echo "Converting normal/$img to tiny."
    fi
done
