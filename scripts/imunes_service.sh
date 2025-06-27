#!/bin/sh
#
# PROVIDE: imunes
# REQUIRE: NETWORKING FILESYSTEMS jail devfs
#

. /etc/rc.subr

name="imunes"
start_cmd="${name}_start"
stop_cmd="${name}_stop"

startupFolder="/var/imunes-service"
serviceDirectory="/var/run/imunes-service"
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin


imunes_start() {
	mkdir -p $serviceDirectory
    for topology in `ls $startupFolder`; do
	eid=$(basename $(mktemp -p $serviceDirectory iXXXXX))
	imunes -b -e $eid $startupFolder/$topology
    done
}

imunes_stop() {
    for eid in `ls $serviceDirectory`; do
	imunes -b -e $eid
	rm $serviceDirectory/$eid
    done
}

load_rc_config $name
run_rc_command "$1"
