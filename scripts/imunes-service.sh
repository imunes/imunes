#!/bin/sh

. /etc/rc.subr

name="imunes-service"
start_cmd="${name}_start"
stop_cmd=":"

imunes-service_start() {
    startupFolder="/var/imunes-service"
    export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin
    for topology in `ls $startupFolder`; do
	imunes -b $startupFolder/$topology
    done
}

load_rc_config $name
run_rc_command "$1"
