#****f* freebsd.tcl/moveFileFromNode
# NAME
#   moveFileFromNode -- copy file from virtual node
# SYNOPSIS
#   moveFileFromNode $node_id $path $ext_path
# FUNCTION
#   Moves file from virtual node to a specified external path.
# INPUTS
#   * node_id -- virtual node id
#   * path -- path to file in node
#   * ext_path -- external path
#****
proc moveFileFromNode { node_id path ext_path } {
	set node_dir [getNodeDir $node_id]

	catch { rexec mv $node_dir$path $ext_path }
}

#****f* freebsd.tcl/writeDataToNodeFile
# NAME
#   writeDataToNodeFile -- write data to virtual node
# SYNOPSIS
#   writeDataToNodeFile $node_id $path $data
# FUNCTION
#   Writes data to a file on the specified virtual node.
# INPUTS
#   * node_id -- virtual node id
#   * path -- path to file in node
#   * data -- data to write
#****
proc writeDataToNodeFile { node_id path data } {
	set node_dir [getNodeDir $node_id]

	if { [catch { rexec test -d $node_dir} status] } {
		return
	}

	if { [string match -nocase "*No such file or directory*" $status] } {
		return
	}

	writeDataToFile $node_dir/$path $data
}

#****f* freebsd.tcl/execCmdNodeBkg
# NAME
#   execCmdNodeBkg -- execute command on virtual node
# SYNOPSIS
#   execCmdNodeBkg $node_id $cmd
# FUNCTION
#   Executes a command on a virtual node (in the background).
# INPUTS
#   * node_id -- virtual node id
#   * cmd -- command to execute
#****
proc execCmdNodeBkg { node_id cmd } {
	pipesExec "jexec [getFromRunning "eid"].$node_id sh -c '$cmd'" "hold"
}

#****f* freebsd.tcl/checkForExternalApps
# NAME
#   checkForExternalApps -- check whether external applications exist
# SYNOPSIS
#   checkForExternalApps $app_list
# FUNCTION
#   Checks whether a list of applications exist on the machine running IMUNES
#   by using the 'command' command.
# INPUTS
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForExternalApps { app_list } {
	foreach app $app_list {
		set cmds "command -v $app"
		set status [ catch { exec sh -c $cmds } err ]
		if { $status } {
			return 1
		}
	}

	return 0
}

#****f* freebsd.tcl/checkForApplications
# NAME
#   checkForApplications -- check whether applications exist
# SYNOPSIS
#   checkForApplications $node_id $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the 'command' command.
# INPUTS
#   * node_id -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node_id app_list } {
	set private_ns [invokeNodeProc $node_id "getPrivateNs" [getFromRunning "eid"] $node_id]
	set os_cmd "jexec $private_ns sh -c"

	foreach app $app_list {
		set os_cmd "$os_cmd 'command -v $app'"
		catch { rexec {*}$os_cmd } err
		if { $err == "" } {
			return 1
		}
	}

	return 0
}

#****f* freebsd.tcl/startWiresharkOnNodeIfc
# NAME
#   startWiresharkOnNodeIfc -- start wireshark on an interface
# SYNOPSIS
#   startWiresharkOnNodeIfc $node_id $ifc
# FUNCTION
#   Start Wireshark on a virtual node on the specified interface.
# INPUTS
#   * node_id -- virtual node id
#   * ifc -- virtual node interface
#****
proc startWiresharkOnNodeIfc { node_id ifc } {
	global remote rcmd escalation_comm

	set eid [getFromRunning "eid"]

	if {
		$remote == "" &&
		[checkForExternalApps "startxcmd"] == 0 &&
		[checkForApplications $node_id "wireshark"] == 0
	} {
		startXappOnNode $node_id "wireshark -ki $ifc"
	} else {
		if { $remote != "" } {
			set wireshark_comm "$escalation_comm wireshark"

			exec -- echo -e "jexec $eid.$node_id tcpdump -s 0 -U -w - -i $ifc 2>/dev/null" | {*}$rcmd | \
				{*}$wireshark_comm -o "gui.window_title:$ifc@[getNodeName $node_id] ($eid)" -k -i - &
		} else {
			set wireshark_comm "wireshark"

			exec jexec $eid.$node_id tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
				{*}$wireshark_comm -o "gui.window_title:$ifc@[getNodeName $node_id] ($eid)" -k -i - &
		}
	}
}

#****f* freebsd.tcl/startXappOnNode
# NAME
#   startXappOnNode -- start X application in a virtual node
# SYNOPSIS
#   startXappOnNode $node_id $app
# FUNCTION
#   Start X application on virtual node
# INPUTS
#   * node_id -- virtual node id
#   * app -- application to start
#****
proc startXappOnNode { node_id app } {
	global debug remote

	if { $remote != "" } {
		sputs stderr "Running X applications in nodes on remote host is not supported."

		return
	}

	if { [checkForExternalApps "socat"] != 0 } {
		sputs stderr "To run X applications on the node, install socat on your host."
		return
	}

	set eid [getFromRunning "eid"]

	set logfile "/dev/null"
	if { $debug } {
		set logfile "/tmp/startxcmd_$eid\_$node_id.log"
	}

	eval exec startxcmd [getNodeName $node_id]@$eid $app > $logfile 2>> $logfile &
}

#****f* freebsd.tcl/startTcpdumpOnNodeIfc
# NAME
#   startTcpdumpOnNodeIfc -- start tcpdump on an interface
# SYNOPSIS
#   startTcpdumpOnNodeIfc $node_id $ifc
# FUNCTION
#   Start tcpdump in a terminal on a virtual node on the specified interface.
# INPUTS
#   * node_id -- virtual node id
#   * ifc -- virtual node interface
#****
proc startTcpdumpOnNodeIfc { node_id ifc } {
	if { [checkForApplications $node_id "tcpdump"] == 0 } {
		spawnShell $node_id "tcpdump -leni $ifc"
	}
}

#****f* freebsd.tcl/allSnapshotsAvailable
# NAME
#   allSnapshotsAvailable -- all snapshots available
# SYNOPSIS
#   allSnapshotsAvailable
# FUNCTION
#   Procedure that checks wheter all node ZFS snapshots are available on the
#   current system.
#****
proc allSnapshotsAvailable {} {
	global execMode vroot_unionfs gui

	set node_list [getFromRunning "node_list"]
	set snapshots {}
	foreach node_id $node_list {
		# TODO: create another field for other jail/docker arguments
		set img [lindex [split [getNodeCustomImage $node_id] " "] end]
		if { $img != "" } {
			lappend snapshots $img
		}
	}

	set snapshots [lsort -uniq $snapshots]
	set missing 0

	foreach vroot $snapshots {
		if { $vroot_unionfs } {
			catch { rexec ls -d $vroot } err
			if { $err == $vroot } {
				return 1
			} else {
				set msg "The root filesystem for virtual nodes ($vroot) is missing.\n"
				append msg "Run 'imunes -p' to create the root filesystem."
				if { ! $gui || $execMode == "batch" } {
					sputs stderr $msg
				} else {
					tk_dialog .dialog1 "IMUNES error" \
						$msg \
						info 0 Dismiss
				}

				return 0
			}
		}
	}

	return 1

	catch { rexec zfs list -t snapshot | awk {{print $1}} | sed "1 d" } out
	set snapshotList [split $out "\n"]
	foreach node_id $node_list {
		set snapshot [getNodeSnapshot $node_id]
		if { $snapshot == "" } {
			set snapshot "vroot/vroot@clean"
		}
		if { [llength [lsearch -inline $snapshotList $snapshot]] == 0 } {
			if { ! $gui || $execMode == "batch" } {
				if { $snapshot == "vroot/vroot@clean" } {
					sputs stderr "The main snapshot for virtual nodes is missing.
					Run 'make' or 'make vroot' to create the main ZFS snapshot."
				} else {
					sputs stderr "Error: ZFS snapshot image \"$snapshot\" for node \"$node_id\" is missing."
				}

				return 0
			} else {
				after idle { .dialog1.msg configure -wraplength 6i }
				if { $snapshot == "vroot/vroot@clean" } {
					set msg "The main snapshot for virtual nodes is missing.\n"
					append msg "Run 'make' or 'make vroot' to create the main ZFS snapshot."
					tk_dialog .dialog1 "IMUNES error" \
						$msg \
						info 0 Dismiss

					return 0
				} else {
					tk_dialog .dialog1 "IMUNES error" \
						"Error: ZFS snapshot image \"$snapshot\" for node \"$node_id\" is missing." \
						info 0 Dismiss

					return 0
				}
			}
		}
	}

	return 1
}

#****f* freebsd.tcl/checkHangingTCPs
# NAME
#   checkHangingTCPs -- timeout patch
# SYNOPSIS
#   checkHangingTCPs $eid $vimage
# FUNCTION
#   Timeout patch that is applied for hanging TCP connections. We need to wait
#   for TCP connections to close regularly because we can't terminate them in
#   FreeBSD 8. In FreeBSD that should be possible with the tcpdrop command.
# INPUTS
#   * eid -- experiment ID
#   * vimages -- list of current vimages
#****
proc checkHangingTCPs { eid vimage } {
	global execMode gui

	if { [lindex [split [rexec uname -r] "-"] 0] >= 9.0 } {
		return
	}

	set timeoutNeeded 0
	catch { rexec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT" } err
	if { $err != "" } {
		set timeoutNeeded 1
		break
	}

	if { $timeoutNeeded == 0 } {
		return
	}

	set sec 60
	if { ! $gui || $execMode == "batch" } {
		sputs "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec). "
		sputs "Please don't try killing the process."
	} else {
		set w .timewait
		catch { destroy $w }

		toplevel $w -takefocus 1
		wm transient $w .
		wm title $w "Please wait ..."
		set msg "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec).\n"
		append msg "Please don't try killing the process.\n"
		append msg "(countdown on status line)"
		message $w.msg \
			-justify left \
			-aspect 1200 \
			-text $msg
		pack $w.msg

		ttk::progressbar $w.p -orient horizontal -length 350 \
			-mode determinate -maximum $sec -value $sec
		pack $w.p
		update

		grab $w
	}

	set spin 1
	while { $spin == 1 } {
		set spin 0
		set err "-"
		while { $err != "" } {
			set spin 1
			after 1000
			set sec [expr $sec - 1]
			if { ! $gui || $execMode == "batch" } {
				sputs -nonewline "."
				flush stdout
			} else {
				statline "~ $sec seconds ..."
				$w.p step -1
				update
			}

			catch { rexec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT" } err
		}
	}

	if { $gui && $execMode != "batch" } {
		destroy .timewait
	}

	statline ""
}

#****f* freebsd.tcl/execSetIfcQDisc
# NAME
#   execSetIfcQDisc -- in exec mode set interface queuing discipline
# SYNOPSIS
#   execSetIfcQDisc $eid $node_id $iface_id $qdisc
# FUNCTION
#   Sets the queuing discipline during the simulation.
#   New queuing discipline is defined in qdisc parameter.
#   Queueing discipline can be set to fifo, wfq or drr.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface id
#   qdisc -- queuing discipline
#****
proc execSetIfcQDisc { eid node_id iface_id qdisc } {
	set link_id [getIfcLink $node_id $iface_id]
	set direction [linkDirection $node_id $iface_id]
	lassign [getLinkPeers $link_id] node1_id -

	switch -exact $qdisc {
		FIFO { set qdisc fifo }
		WFQ { set qdisc wfq }
		DRR { set qdisc drr }
	}

	pipesExec "jexec $eid ngctl msg $link_id: setcfg \"{ $direction={ $qdisc=1 } }\"" "hold"
}

#****f* freebsd.tcl/execSetIfcQDrop
# NAME
#   execSetIfcQDrop -- in exec mode set interface queue drop
# SYNOPSIS
#   execSetIfcQDrop $eid $node_id $iface_id $qdrop
# FUNCTION
#   Sets the queue dropping policy during the simulation.
#   New queue dropping policy is defined in qdrop parameter.
#   Queue dropping policy can be set to drop-head or drop-tail.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface id
#   qdrop -- queue dropping policy
#****
proc execSetIfcQDrop { eid node_id iface_id qdrop } {
	set link_id [getIfcLink $node_id $iface_id]
	set direction [linkDirection $node_id $iface_id]
	lassign [getLinkPeers $link_id] node1_id -

	switch -exact $qdrop {
		drop-head { set qdrop drophead }
		drop-tail { set qdrop droptail }
	}

	pipesExec "jexec $eid ngctl msg $link_id: setcfg \"{ $direction={ $qdrop=1 } }\"" "hold"
}

#****f* freebsd.tcl/execSetIfcQLen
# NAME
#   execSetIfcQLen -- in exec mode set interface queue length
# SYNOPSIS
#   execSetIfcQLen $eid $node_id $iface_id $qlen
# FUNCTION
#   Sets the queue length during the simulation.
#   New queue length is defined in qlen parameter.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface id
#   qlen -- new queue's length
#****
proc execSetIfcQLen { eid node_id iface_id qlen } {
	set link_id [getIfcLink $node_id $iface_id]
	set direction [linkDirection $node_id $iface_id]
	lassign [getLinkPeers $link_id] node1_id -

	if { $qlen == 0 } {
		set qlen -1
	}

	pipesExec "jexec $eid ngctl msg $link_id: setcfg \"{ $direction={ queuelen=$qlen } }\"" "hold"
}

#****f* freebsd.tcl/execSetLinkJitter
# NAME
#   execSetLinkJitter -- in exec mode set link jitter
# SYNOPSIS
#   execSetLinkJitter $eid $link_id
# FUNCTION
#   Sets the link jitter parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link_id -- link id
#****
proc execSetLinkJitter { eid link_id } {
	set jitter_up [getLinkJitterUpstream $link_id]
	set jitter_mode_up [getLinkJitterModeUpstream $link_id]
	set jitter_hold_up [expr [getLinkJitterHoldUpstream $link_id] + 0]

	set jitter_down [getLinkJitterDownstream $link_id]
	set jitter_mode_down [getLinkJitterModeDownstream $link_id]
	set jitter_hold_down [expr [getLinkJitterHoldDownstream $link_id] + 0]

	if { $jitter_mode_up in {"sequential" ""} } {
		set jit_mode_up 1
	} else {
		set jit_mode_up 2
	}

	if { $jitter_mode_down in {"sequential" ""} } {
		set jit_mode_down 1
	} else {
		set jit_mode_down 2
	}

	set ngcmds ""

	if { $jitter_up != "" } {
		set ngcmds "$ngcmds msg $link_id: setcfg {upstream={jitmode=-1}}\n"
		foreach val $jitter_up {
			set ngcmds "$ngcmds msg $link_id: setcfg {upstream={addjitter=[expr round($val*1000)]}}\n"
		}
		set ngcmds "$ngcmds msg $link_id: setcfg {upstream={jitmode=$jit_mode_up}}\n"
		set ngcmds "$ngcmds msg $link_id: setcfg {upstream={jithold=[expr round($jitter_hold_up*1000)]}}\n"
	}

	if { $jitter_down != "" } {
		set ngcmds "$ngcmds msg $link_id: setcfg {downstream={jitmode=-1}}\n"
		foreach val $jitter_down {
			set ngcmds "$ngcmds msg $link_id: setcfg {downstream={addjitter=[expr round($val*1000)]}}\n"
		}
		set ngcmds "$ngcmds msg $link_id: setcfg {downstream={jitmode=$jit_mode_down}}\n"
		set ngcmds "$ngcmds msg $link_id: setcfg {downstream={jithold=[expr round($jitter_hold_down*1000)]}}\n"
	}

	pipesExec "printf \"$ngcmds\" | ngctl -f -" "hold"
}

#****f* freebsd.tcl/execResetLinkJitter
# NAME
#   execResetLinkJitter -- in exec mode reset link jitter
# SYNOPSIS
#   execResetLinkJitter $eid $link_id
# FUNCTION
#   Resets the link jitter parameters to defaults during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   * eid -- experiment id
#   * link_id -- link id
#****
proc execResetLinkJitter { eid link_id } {
	rexec jexec $eid ngctl msg $link_id: setcfg \
		"{upstream={jitmode=-1} downstream={jitmode=-1}}"
}

proc fetchInterfaceData { node_id iface_id } {
	global node_existing_mac node_existing_ipv4 node_existing_ipv6
	set node_existing_mac [getFromRunning "mac_used_list"]
	set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
	set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

	global node_cfg

	set iface_name [_getIfcName $node_cfg $iface_id]
	if { $iface_name ni [getHostIfcList "lo* ipfw* tun*"] } {
		sputs "No interface $iface_name."

		return
	}

	set new_cfg $node_cfg

	catch { rexec ifconfig -v -f inet:cidr,inet6:cidr $iface_name } full
	set lines [split $full "\n"]
	foreach line $lines {
		if { [regexp {^([[:alnum:]]+):.*<([^>]+)>.*mtu ([^$]+)$} $line -> iface_name flags mtu] } {
			set loopback 0
			set ipv4_addrs {}
			set ipv6_addrs {}

			if { "UP" in [split $flags ","] } {
				set oper_state ""
			} else {
				set oper_state "down"
			}
			set new_cfg [_setIfcOperState $new_cfg $iface_id $oper_state]

			if { "LOOPBACK" in [split $flags ","] } {
				set loopback 1
			}

			if { $mtu != "" && [_getIfcMTU $new_cfg $iface_id] != $mtu} {
				set new_cfg [_setIfcMTU $new_cfg $iface_id $mtu]
			}
		} elseif { [regexp {^\tether ([^ ]+)} $line -> new_mac] } {
			if { $loopback } {
				continue
			}

			set old_mac [_getIfcMACaddr $new_cfg $iface_id]

			if { $old_mac != $new_mac } {
				set node_existing_mac [removeFromList $node_existing_mac $old_mac "keep_doubles"]
				lappend node_existing_mac $new_mac

				set new_cfg [_setIfcMACaddr $new_cfg $iface_id $new_mac]
			}
		} elseif { [regexp {^\tinet ([^ ]+)} $line -> ip4addr] } {
			lappend ipv4_addrs $ip4addr
		} elseif { [regexp {^\tinet6 (?!fe80:)([^ ]+)} $line -> ip6addr] } {
			lappend ipv6_addrs $ip6addr
		}
	}

	set old_ipv4_addrs [lsort [_getIfcIPv4addrs $new_cfg $iface_id]]
	set new_ipv4_addrs [lsort $ipv4_addrs]
	if { $old_ipv4_addrs != $new_ipv4_addrs } {
		set node_existing_ipv4 [removeFromList $node_existing_ipv4 $old_ipv4_addrs "keep_doubles"]
		lappend node_existing_ipv4 {*}$new_ipv4_addrs

		setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $ipv4_addrs
		set new_cfg [_setIfcIPv4addrs $new_cfg $iface_id $ipv4_addrs]
	}

	set old_ipv6_addrs [lsort [_getIfcIPv6addrs $new_cfg $iface_id]]
	set new_ipv6_addrs [lsort $ipv6_addrs]
	if { $old_ipv6_addrs != $new_ipv6_addrs } {
		set node_existing_ipv6 [removeFromList $node_existing_ipv6 $old_ipv6_addrs "keep_doubles"]
		lappend node_existing_ipv6 {*}$new_ipv6_addrs

		setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $ipv6_addrs
		set new_cfg [_setIfcIPv6addrs $new_cfg $iface_id $ipv6_addrs]
	}

	if { $new_cfg == $node_cfg } {
		return
	}

	return $new_cfg
}

#****f* freebsd.tcl/fetchNodeRunningConfig
# NAME
#   fetchNodeRunningConfig -- get interfaces list from the node
# SYNOPSIS
#   fetchNodeRunningConfig $node_id
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc fetchNodeRunningConfig { node_id } {
	global node_existing_mac node_existing_ipv4 node_existing_ipv6
	set node_existing_mac [getFromRunning "mac_used_list"]
	set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
	set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

	# overwrite any unsaved changes to this node
	set cur_node_cfg [cfgGet "nodes" $node_id]
	set cur_node_cfg_gui [cfgGet "gui" "nodes" $node_id]

	set ifaces_names [allIfacesNames $node_id]

	set iface_id ""
	set loopback 0
	set ipv4_addrs {}
	set ipv6_addrs {}
	catch { rexec jexec [getFromRunning "eid"].$node_id ifconfig -v -f inet:cidr,inet6:cidr } full
	set lines [split $full "\n"]
	foreach line $lines {
		if { [regexp {^([[:alnum:]]+):.*<([^>]+)>.*mtu ([^$]+)$} $line -> iface_name flags mtu]} {
			if { $iface_id != "" } {
				set old_ipv4_addrs [lsort [_getIfcIPv4addrs $cur_node_cfg $iface_id]]
				set new_ipv4_addrs [lsort $ipv4_addrs]
				if { $old_ipv4_addrs != $new_ipv4_addrs } {
					set node_existing_ipv4 [removeFromList $node_existing_ipv4 $old_ipv4_addrs "keep_doubles"]
					lappend node_existing_ipv4 {*}$new_ipv4_addrs

					setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $ipv4_addrs
					set cur_node_cfg [_setIfcIPv4addrs $cur_node_cfg $iface_id $ipv4_addrs]
				}

				set old_ipv6_addrs [lsort [_getIfcIPv6addrs $cur_node_cfg $iface_id]]
				set new_ipv6_addrs [lsort $ipv6_addrs]
				if { $old_ipv6_addrs != $new_ipv6_addrs } {
					set node_existing_ipv6 [removeFromList $node_existing_ipv6 $old_ipv6_addrs "keep_doubles"]
					lappend node_existing_ipv6 {*}$new_ipv6_addrs

					setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $ipv6_addrs
					set cur_node_cfg [_setIfcIPv6addrs $cur_node_cfg $iface_id $ipv6_addrs]
				}
			}

			set iface_id ""
			set loopback 0
			set ipv4_addrs {}
			set ipv6_addrs {}
			if { $iface_name ni $ifaces_names } {
				continue
			}

			set iface_id [ifaceIdFromName $node_id $iface_name]

			if { "UP" in [split $flags ","] } {
				set oper_state ""
			} else {
				set oper_state "down"
			}
			set cur_node_cfg [_setIfcOperState $cur_node_cfg $iface_id $oper_state]

			if { "LOOPBACK" in [split $flags ","] } {
				set loopback 1
			}

			if { $mtu != "" && [_getIfcMTU $cur_node_cfg $iface_id] != $mtu} {
				set cur_node_cfg [_setIfcMTU $cur_node_cfg $iface_id $mtu]
			}

		} elseif { $iface_id != "" && [regexp {^\tether ([^ ]+)} $line -> new_mac] } {

			if { $loopback } {
				continue
			}

			set old_mac [_getIfcMACaddr $cur_node_cfg $iface_id]

			if { $old_mac != $new_mac } {
				set node_existing_mac [removeFromList $node_existing_mac $old_mac "keep_doubles"]
				lappend node_existing_mac $new_mac

				set cur_node_cfg [_setIfcMACaddr $cur_node_cfg $iface_id $new_mac]
			}
		} elseif { $iface_id != "" && [regexp {^\tinet ([^ ]+)} $line -> ip4addr] } {

			lappend ipv4_addrs $ip4addr
		} elseif { $iface_id != "" && [regexp {^\tinet6 (?!fe80:)([^ ]+)} $line -> ip6addr]} {

			lappend ipv6_addrs $ip6addr
		}
	}

	if { $iface_id != "" } {
		set old_ipv4_addrs [lsort [_getIfcIPv4addrs $cur_node_cfg $iface_id]]
		set new_ipv4_addrs [lsort $ipv4_addrs]
		if { $old_ipv4_addrs != $new_ipv4_addrs } {
			set node_existing_ipv4 [removeFromList $node_existing_ipv4 $old_ipv4_addrs "keep_doubles"]
			lappend node_existing_ipv4 {*}$new_ipv4_addrs

			setToRunning "${node_id}|${iface_id}_old_ipv4_addrs" $ipv4_addrs
			set cur_node_cfg [_setIfcIPv4addrs $cur_node_cfg $iface_id $ipv4_addrs]
		}

		set old_ipv6_addrs [lsort [_getIfcIPv6addrs $cur_node_cfg $iface_id]]
		set new_ipv6_addrs [lsort $ipv6_addrs]
		if { $old_ipv6_addrs != $new_ipv6_addrs } {
			set node_existing_ipv6 [removeFromList $node_existing_ipv6 $old_ipv6_addrs "keep_doubles"]
			lappend node_existing_ipv6 {*}$new_ipv6_addrs

			setToRunning "${node_id}|${iface_id}_old_ipv6_addrs" $ipv6_addrs
			set cur_node_cfg [_setIfcIPv6addrs $cur_node_cfg $iface_id $ipv6_addrs]
		}
	}

	lassign [getDefaultGateways $node_id {} {}] my_gws {} {}
	lassign [getDefaultRoutesConfig $node_id $my_gws] default_routes4 default_routes6

	set croutes4 {}
	set croutes6 {}

	catch { rexec jexec [getFromRunning "eid"].$node_id netstat -rn4 --libxo json} json
	set route_table [dictGet [json::json2dict $json] "statistics" "route-information" "route-table" "rt-family"]

	foreach elem $route_table {
		foreach rt [dictGet $elem "rt-entry"] {
			if { "G" ni [split [dictGet $rt "flags"] ""] } {
				continue
			}

			set dst [dictGet $rt "destination"]
			if { $dst == "default" } {
				set dst "0.0.0.0/0"
			} elseif { [string first "/" $dst] == -1 } {
				set dst "$dst/32"
			}
			set gateway [dictGet $rt "gateway"]

			set new_route "$dst $gateway"
			if { $new_route in $default_routes4 } {
				continue
			}

			lappend croutes4 $new_route
		}
	}

	set old_croutes4 [lsort [_getNodeStatIPv4routes $cur_node_cfg]]
	set new_croutes4 [lsort $croutes4]
	if { $old_croutes4 != $new_croutes4 } {
		setToRunning "${node_id}_old_croutes4" $new_croutes4
		set cur_node_cfg [_setNodeStatIPv4routes $cur_node_cfg $new_croutes4]
	}

	catch { rexec jexec [getFromRunning "eid"].$node_id netstat -rn6 --libxo json} json
	set route_table [dictGet [json::json2dict $json] "statistics" "route-information" "route-table" "rt-family"]

	foreach elem $route_table {
		foreach rt [dictGet $elem "rt-entry"] {
			set flags [dictGet $rt "flags"]
			if { "G" ni [split $flags ""] } {
				continue
			}

			set dst [dictGet $rt "destination"]
			if { $dst == "default" } {
				set dst "::/0"
			} elseif { [string first "/" $dst] == -1 } {
				set dst "$dst/128"
			}
			set gateway [dictGet $rt "gateway"]

			set new_route "$dst $gateway"
			if { $new_route in $default_routes6 } {
				continue
			}

			lappend croutes6 $new_route
		}
	}

	set old_croutes6 [lsort [_getNodeStatIPv6routes $cur_node_cfg]]
	set new_croutes6 [lsort $croutes6]
	if { $old_croutes6 != $new_croutes6 } {
		setToRunning "${node_id}_old_croutes6" $new_croutes6
		set cur_node_cfg [_setNodeStatIPv6routes $cur_node_cfg $new_croutes6]
	}

	# don't trigger anything new - save variables state
	prepareInstantiateVars
	prepareTerminateVars

	updateNodeGUI $node_id "*" $cur_node_cfg_gui

	updateNode $node_id "*" $cur_node_cfg

	# don't trigger anything new - restore variables state
	updateInstantiateVars
	updateTerminateVars

	if { $node_existing_mac != [getFromRunning "mac_used_list"] } {
		setToRunning "mac_used_list" $node_existing_mac
	}

	if { $node_existing_ipv4 != [getFromRunning "ipv4_used_list"] } {
		setToRunning "ipv4_used_list" $node_existing_ipv4
	}

	if { $node_existing_ipv6 != [getFromRunning "ipv6_used_list"] } {
		setToRunning "ipv6_used_list" $node_existing_ipv6
	}

	return $cur_node_cfg
}

# ifconfig parse proc !

#****f* freebsd.tcl/getHostIfcList
# NAME
#   getHostIfcList -- get interfaces list from host
# SYNOPSIS
#   getHostIfcList
# FUNCTION
#   Returns the list of all network interfaces on the host.
# RESULT
#   * extifcs -- list of all external interfaces
#****
proc getHostIfcList { { filter_list "lo0" } } {
	# fetch interface list from the system
	if { [catch { rexec ifconfig -l } extifcs] } {
		return ""
	}

	# exclude loopback interface
	foreach ignore $filter_list {
		set extifcs [lsearch -all -inline -not $extifcs $ignore]
	}

	return $extifcs
}

#****f* freebsd.tcl/getHostIfcVlanExists
# NAME
#   getHostIfcVlanExists -- check if host VLAN interface exists
# SYNOPSIS
#   getHostIfcVlanExists $node_id $ifname
# FUNCTION
#   Returns 1 if VLAN interface with the name $name for the given node cannot
#   be created.
# INPUTS
#   * node_id -- node id
#   * ifname -- interface id
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node_id ifname } {
	global execMode gui

	# check if VLAN ID is already taken
	# this can be only done by trying to create it, as it's possible that the same
	# VLAN interface already exists in some other namespace
	set iface_id [ifaceIdFromName $node_id $ifname]
	set vlan [getIfcVlanTag $node_id $iface_id]
	try {
		rexec ifconfig $ifname.$vlan create
	} on ok {} {
		rexec ifconfig $ifname.$vlan destroy

		return 0
	} on error err {
		set msg "Unable to create external interface '$ifname.$vlan':\n$err\n\nPlease\
			verify that VLAN ID $vlan with parent interface $ifname is not already\
			assigned to another VLAN interface, potentially in a different jail."
	}

	if { ! $gui || $execMode == "batch" } {
		sputs stderr $msg
	} else {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" $msg \
			info 0 Dismiss
	}

	return 1
}

#****f* freebsd.tcl/nodeLogIfacesCreate
# NAME
#   nodeLogIfacesCreate -- create node logical interfaces
# SYNOPSIS
#   nodeLogIfacesCreate $node_id
# FUNCTION
#   Creates logical interfaces for the given node.
# INPUTS
#   * node_id -- node id
#****
proc nodeLogIfacesCreate { node_id ifaces } {
	set jail_id "[getFromRunning "eid"].$node_id"

	foreach iface_id $ifaces {
		set iface_name [getIfcName $node_id $iface_id]
		switch -exact [getIfcType $node_id $iface_id] {
			vlan {
				set tag [getIfcVlanTag $node_id $iface_id]
				set dev [getIfcVlanDev $node_id $iface_id]
				if { $tag != "" && $dev != "" } {
					pipesExec "jexec $jail_id [getVlanTagIfcCmd $iface_name $dev $tag]" "hold"
					addStateNodeIface $node_id $iface_id "creating"
				} else {
					removeStateNodeIface $node_id $iface_id "running"
				}
			}
			lo {
				addStateNodeIface $node_id $iface_id "creating"
				if { $iface_name != "lo0" } {
					pipesExec "jexec $jail_id ifconfig $iface_name create" "hold"
				}
			}
		}
	}
}

#****f* freebsd.tcl/removeNodeIfcIPaddrs
# NAME
#   removeNodeIfcIPaddrs -- remove node iterfaces' IP addresses
# SYNOPSIS
#   removeNodeIfcIPaddrs $eid $node_id
# FUNCTION
#   Remove all IPv4 and IPv6 addresses from interfaces on the given node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc removeNodeIfcIPaddrs { eid node_id } {
	set jail_id "$eid.$node_id"

	foreach ifc [ifcList $node_id] {
		foreach ipv4 [getIfcIPv4addrs $node_id $ifc] {
			pipesExec "jexec $jail_id ifconfig $ifc $ipv4 -alias" "hold"
		}
		foreach ipv6 [getIfcIPv6addrs $node_id $ifc] {
			pipesExec "jexec $jail_id ifconfig $ifc inet6 $ipv6 -alias" "hold"
		}
	}
}

#****f* freebsd.tcl/loadKernelModules
# NAME
#   loadKernelModules -- load kernel modules
# SYNOPSIS
#   loadKernelModules
# FUNCTION
#   Load necessary kernel modules.
#****
proc loadKernelModules {} {
	global all_modules_list

	set kernel_modules "nullfs unionfs ng_eiface ng_pipe ng_socket if_tun vlan ipsec pf"
	catch { rexec kldload $kernel_modules }

	catch { rexec sysctl net.inet.ipf.jail_allowed=1 }

	foreach node_type $all_modules_list {
		invokeTypeProc $node_type "prepareSystem"
	}
}

#****f* freebsd.tcl/prepareVirtualFS
# NAME
#   prepareVirtualFS -- prepare virtual filesystem
# SYNOPSIS
#   prepareVirtualFS
# FUNCTION
#   Prepares all necessary files for the virtual filesystem.
#****
proc prepareVirtualFS {} {
	global vroot_unionfs

	if { $vroot_unionfs } {
		# UNIONFS - anything to do here?
	} else {
		rexec zfs create vroot/[getFromRunning "eid"]
	}
}

#****f* freebsd.tcl/prepareDevfs
# NAME
#   prepareDevfs -- prepare dev filesystem
# SYNOPSIS
#   prepareDevfs
# FUNCTION
#   Prepares devfs rules necessary for virtual nodes.
#****
proc prepareDevfs { { force 0 } } {
	global devfs_number

	catch { rexec devfs rule showsets } devcheck
	if { $force == 1 || $devfs_number ni $devcheck } {
		# Prepare a devfs ruleset for L3 vnodes
		rexec devfs ruleset $devfs_number
		rexec devfs rule delset
		rexec devfs rule add hide
		rexec devfs rule add path null unhide
		rexec devfs rule add path zero unhide
		rexec devfs rule add path random unhide
		rexec devfs rule add path urandom unhide
		rexec devfs rule add path ipl unhide
		rexec devfs rule add path ipnat unhide
		rexec devfs rule add path pf unhide
		rexec devfs rule add path crypto unhide
		rexec devfs rule add path ptyp* unhide
		rexec devfs rule add path ptyq* unhide
		rexec devfs rule add path ptyr* unhide
		rexec devfs rule add path ptys* unhide
		rexec devfs rule add path ptyp* unhide
		rexec devfs rule add path ptyq* unhide
		rexec devfs rule add path ptyr* unhide
		rexec devfs rule add path ptys* unhide
		rexec devfs rule add path ttyp* unhide
		rexec devfs rule add path ttyq* unhide
		rexec devfs rule add path ttyr* unhide
		rexec devfs rule add path ttys* unhide
		rexec devfs rule add path ttyp* unhide
		rexec devfs rule add path ttyq* unhide
		rexec devfs rule add path ttyr* unhide
		rexec devfs rule add path ttys* unhide
		rexec devfs rule add path ptmx unhide
		rexec devfs rule add path pts unhide
		rexec devfs rule add path pts/* unhide
		rexec devfs rule add path fd unhide
		rexec devfs rule add path fd/* unhide
		rexec devfs rule add path stdin unhide
		rexec devfs rule add path stdout unhide
		rexec devfs rule add path stderr unhide
		rexec devfs rule add path mem unhide
		rexec devfs rule add path kmem unhide
		rexec devfs rule add path bpf* unhide
		rexec devfs rule add path tun* unhide
		rexec devfs ruleset 0
	}
}

#****f* freebsd.tcl/createExperimentContainer
# NAME
#   createExperimentContainer -- create experiment container
# SYNOPSIS
#   createExperimentContainer
# FUNCTION
#   Creates a root jail (container) for the current experiment.
#****
proc createExperimentContainer {} {
	# Create top-level vimage
	rexec jail -c name=[getFromRunning "eid"] vnet children.max=[llength [getFromRunning "node_list"]] persist
}

#****f* freebsd.tcl/createLinkBetween
# NAME
#   createLinkBetween -- create link between
# SYNOPSIS
#   createLinkBetween $node1_id $node2_id $iface1_id $iface2_id
# FUNCTION
#   Creates link between two given nodes.
# INPUTS
#   * node1_id -- node id of the first node
#   * node2_id -- node id of the second node
#   * iface1_id -- interface id on the first node
#   * iface2_id -- interface id on the second node
#****
proc createLinkBetween { node1_id node2_id iface1_id iface2_id link_id } {
	set eid [getFromRunning "eid"]

	addStateLink $link_id "creating"

	lassign [invokeNodeProc $node1_id "getHookData" $node1_id $iface1_id] - ng_peer1 ng_hook1
	lassign [invokeNodeProc $node2_id "getHookData" $node2_id $iface2_id] - ng_peer2 ng_hook2

	set direct [getLinkDirect $link_id]

	# for direct links, skip pipe creation
	if { $direct } {
		pipesExec "jexec $eid ngctl connect $ng_peer1: $ng_peer2: $ng_hook1 $ng_hook2" "hold"
	} else {
		set ngcmds "mkpeer $ng_peer1: pipe $ng_hook1 upper"
		set ngcmds "$ngcmds\n name $ng_peer1:$ng_hook1 $link_id"
		set ngcmds "$ngcmds\n connect $link_id: $ng_peer2: lower $ng_hook2"

		pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"
	}

	foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
		invokeNodeProc $node_id "attachToLink" $eid $node_id $iface_id $link_id $direct
	}
}

#****f* freebsd.tcl/configureLinkBetween
# NAME
#   configureLinkBetween -- configure link between
# SYNOPSIS
#   configureLinkBetween $node1_id $node2_id $iface1_id $iface2_id $link_id
# FUNCTION
#   Configures link between two given nodes.
# INPUTS
#   * node1_id -- node id of the first node
#   * node2_id -- node id of the second node
#   * iface1_id -- interface id on the first node
#   * iface2_id -- interface id on the second node
#   * link_id -- link id
#****
proc configureLinkBetween { node1_id node2_id iface1_id iface2_id link_id } {
	global linkJitterConfiguration

	if { $link_id != "" && [getLinkDirect $link_id] } {
		return
	}

	set eid [getFromRunning "eid"]
	set bandwidth [expr [getLinkBandwidth $link_id] + 0]
	set delay [expr [getLinkDelay $link_id] + 0]
	set ber [expr [getLinkBER $link_id] + 0]
	set loss [expr [getLinkLoss $link_id] + 0]
	set dup [expr [getLinkDup $link_id] + 0]

	if { $bandwidth == 0 } {
		set bandwidth -1
	}
	if { $delay == 0 } {
		set delay -1
	}
	if { $ber == 0 } {
		set ber -1
	}
	if { $loss == 0 } {
		set loss -1
	}
	if { $dup == 0 } {
		set dup -1
	}

	# Link parameters
	set ngcmds "msg $link_id: setcfg {bandwidth=$bandwidth delay=$delay upstream={BER=$ber duplicate=$dup} downstream={BER=$ber duplicate=$dup}}"

	pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"

	# FIXME: remove this to interface configuration?
	# Queues
	if { "rj45" ni "[getNodeType $node1_id] [getNodeType $node2_id]" } {
		foreach node_id "$node1_id $node2_id" ifc "$iface1_id $iface2_id" {
			set qdisc [getIfcQDisc $node_id $ifc]
			if { $qdisc != "FIFO" } {
				execSetIfcQDisc $eid $node_id $ifc $qdisc
			}

			set qdrop [getIfcQDrop $node_id $ifc]
			if { $qdrop != "drop-tail" } {
				execSetIfcQDrop $eid $node_id $ifc $qdrop
			}

			set qlen [getIfcQLen $node_id $ifc]
			if { $qlen != 50 } {
				execSetIfcQLen $eid $node_id $ifc $qlen
			}
		}
	}

	if  { $linkJitterConfiguration } {
		execSetLinkJitter $eid $link_id
	}
}

proc unconfigureLinkBetween { eid node1_id node2_id iface1_id iface2_id link_id } {
	if { $link_id != "" && [getFromRunning "${link_id}_destroy_type"] } {
		return
	}

	set ngcmds "msg $link_id: setcfg {bandwidth=-1 delay=-1 upstream={BER=-1 duplicate=-1} downstream={BER=-1 duplicate=-1}}"

	pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"
}

#****f* freebsd.tcl/destroyLinkBetween
# NAME
#   destroyLinkBetween -- destroy link between
# SYNOPSIS
#   destroyLinkBetween $eid $node1_id $node2_id
# FUNCTION
#   Destroys link between two given nodes.
# INPUTS
#   * eid -- experiment id
#   * node1_id -- node id of the first node
#   * node2_id -- node id of the second node
#****
proc destroyLinkBetween { eid node1_id node2_id iface1_id iface2_id link_id } {
	addStateLink $link_id "destroying"

	set direct [getFromRunning "${link_id}_destroy_type"]
	foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
		invokeNodeProc $node_id "detachFromLink" $eid $node_id $iface_id $link_id $direct
	}

	if {
		$direct ||
		"wlan" in "[getNodeType $node1_id] [getNodeType $node2_id]"
	} {
		lassign [invokeNodeProc $node1_id "getHookData" $node1_id $iface1_id] - ng_peer1 ng_hook1
		lassign [invokeNodeProc $node2_id "getHookData" $node2_id $iface2_id] - ng_peer2 ng_hook2

		pipesExec "jexec $eid ngctl disconnect $ng_peer1: $ng_hook1" "hold"
		pipesExec "jexec $eid ngctl disconnect $ng_peer2: $ng_hook2" "hold"
	} else {
		pipesExec "jexec $eid ngctl msg $link_id: shutdown" "hold"
	}
}

#****f* freebsd.tcl/terminate_removeExperimentContainer
# NAME
#   terminate_removeExperimentContainer -- remove experiment container
# SYNOPSIS
#   terminate_removeExperimentContainer $eid $widget
# FUNCTION
#   Removes the root jail of the given experiment.
# INPUTS
#   * eid -- experiment id
#   * widget -- status widget
#****
proc terminate_removeExperimentContainer { eid } {
	# Remove the main vimage which contained all other nodes, hopefully we
	# cleaned everything.
	catch { rexec jexec $eid kill -9 -1 2> /dev/null }
	catch { rexec jail -r $eid }
}

proc terminate_removeExperimentFiles { eid } {
	global vroot_unionfs execMode gui

	set VROOT_BASE [getVrootDir]

	# Remove the main vimage which contained all other nodes, hopefully we
	# cleaned everything.
	if { $vroot_unionfs } {
		# UNIONFS
		catch { rexec rm -fr $VROOT_BASE/$eid }
	} else {
		# ZFS
		if { ! $gui || $execMode == "batch" } {
			rexec jail -r $eid
			rexec zfs destroy -fr vroot/$eid
		} else {
			rexec jail -r $eid &
			rexec zfs destroy -fr vroot/$eid &

			catch { rexec zfs list | grep -c "$eid" } output
			set zfsCount [lindex [split $output] 0]

			while { $zfsCount != 0 } {
				catch { rexec zfs list | grep -c "$eid/" } output

				set zfsCount [lindex [split $output] 0]
				$widget.p configure -value $zfsCount
				update

				after 200
			}
		}
	}
}

#****f* freebsd.tcl/getCpuCount
# NAME
#   getCpuCount -- get CPU count
# SYNOPSIS
#   getCpuCount
# FUNCTION
#   Gets a CPU count of the host machine.
# RESULT
#   * cpucount - CPU count
#****
proc getCpuCount {} {
	global remote max_jobs

	if { $max_jobs == "h" } {
		set max_jobs [expr round([lindex [rexec sysctl kern.smp.cpus] 1]/2)]
	}

	if { $remote == "" } {
		if { $max_jobs > 0 } {
			return $max_jobs
		}
	} else {
		# buffer for non-closed SSH connections
		set remote_jobs [expr round($max_jobs/3)]
		if { $remote_jobs == 0 } {
			set remote_jobs 1
		}

		return $remote_jobs
	}

	return [lindex [rexec sysctl kern.smp.cpus] 1]
}

#****f* freebsd.tcl/captureExtIfcByName
# NAME
#   captureExtIfcByName -- capture external interface
# SYNOPSIS
#   captureExtIfcByName $eid $ifname
# FUNCTION
#   Captures the external interface given by the ifname.
# INPUTS
#   * eid -- experiment id
#   * ifname -- physical interface name
#****
proc captureExtIfcByName { eid ifname node_id } {
	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

	pipesExec "ifconfig $ifname vnet $private_ns" "hold"
	pipesExec "jexec $private_ns ifconfig $ifname up promisc" "hold"
}

#****f* freebsd.tcl/releaseExtIfcByName
# NAME
#   releaseExtIfcByName -- release external interface by name
# SYNOPSIS
#   releaseExtIfcByName $eid $ifname
# FUNCTION
#   Releases the external interface with the name ifname.
# INPUTS
#   * eid -- experiment id
#   * ifname -- physical interface name
#****
proc releaseExtIfcByName { eid ifname node_id } {
	set private_ns [invokeNodeProc $node_id "getPrivateNs" $eid $node_id]

	pipesExec "ifconfig $ifname -vnet $private_ns" "hold"
	pipesExec "ifconfig $ifname up -promisc" "hold"
}

proc getStateIfcCmd { iface_name state } {
	return "ifconfig $iface_name $state"
}

proc getNameIfcCmd { iface_name name } {
	return "ifconfig $iface_name name $name"
}

proc getMacIfcCmd { iface_name mac_addr } {
	return "ifconfig $iface_name link $mac_addr"
}

proc getVlanTagIfcCmd { iface_name dev_name tag } {
	return "ifconfig $dev_name.$tag create name $iface_name"
}

proc getMtuIfcCmd { iface_name mtu } {
	return "ifconfig $iface_name mtu $mtu"
}

proc getNatIfcCmd { iface_name } {
	return "sh -c 'echo \"map $iface_name 0/0 -> 0/32\" | ipnat -f -'"
}

proc getRemoveNatIfcCmd { iface_name } {
	return "sh -c 'echo \"map $iface_name 0/0 -> 0/32\" | ipnat -f - -pr'"
}

proc getIPv4IfcCmd { ifc addr primary } {
	if { $addr == "dhcp" } {
		return "dhclient -b $ifc 2>/dev/null &"
	}

	if { $primary } {
		return "ifconfig $ifc inet $addr"
	}

	return "ifconfig $ifc inet add $addr"
}

proc getDelIPv4IfcCmd { ifc addr } {
	if { $addr == "dhcp" } {
		return "pkill -f 'dhclient.*$ifc\\>'"
	}

	return "ifconfig $ifc inet $addr -alias"
}

proc getIPv6IfcCmd { ifc addr primary } {
	if { $primary } {
		return "ifconfig $ifc inet6 $addr"
	}

	return "ifconfig $ifc inet6 add $addr"
}

proc getDelIPv6IfcCmd { ifc addr } {
	return "ifconfig $ifc inet6 $addr -alias"
}

proc getIPv4RouteCmd { statrte } {
	return "route -q add -inet $statrte"
}

proc getRemoveIPv4RouteCmd { statrte } {
	return "route -q delete -inet $statrte"
}

proc getIPv6RouteCmd { statrte } {
	return "route -q add -inet6 $statrte"
}

proc getRemoveIPv6RouteCmd { statrte } {
	return "route -q delete -inet6 $statrte"
}

proc getIPv4IfcRouteCmd { subnet iface } {
	return "route -q add -inet $subnet -interface $iface"
}

proc getRemoveIPv4IfcRouteCmd { subnet iface } {
	return "route -q delete -inet $subnet -interface $iface"
}

proc getIPv6IfcRouteCmd { subnet iface } {
	return "route -q add -inet6 $subnet -interface $iface"
}

proc getRemoveIPv6IfcRouteCmd { subnet iface } {
	return "route -q delete -inet6 $subnet -interface $iface"
}

proc checkSysPrerequisites {} {
	# XXX
	# check for all comands that we use:
	# jail, jexec, jls, ngctl
}

proc ipsecFilesToNode { node_id ca_cert local_cert ipsecret_file } {
	global ipsecConf ipsecSecrets

	if { $ca_cert != "" } {
		set trimmed_ca_cert [lindex [split $ca_cert /] end]

		set fileId [open $ca_cert "r"]
		set trimmed_ca_cert_data [read $fileId]
		close $fileId

		writeDataToNodeFile $node_id /usr/local/etc/ipsec.d/cacerts/$trimmed_ca_cert $trimmed_ca_cert_data
	}

	if { $local_cert != "" } {
		set trimmed_local_cert [lindex [split $local_cert /] end]

		set fileId [open $local_cert "r"]
		set trimmed_local_cert_data [read $fileId]
		close $fileId

		writeDataToNodeFile $node_id /usr/local/etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
	}

	if { $ipsecret_file != "" } {
		set trimmed_local_key [lindex [split $ipsecret_file /] end]

		set fileId [open $ipsecret_file "r"]
		set local_key_data [read $fileId]
		close $fileId

		writeDataToNodeFile $node_id /usr/local/etc/ipsec.d/private/$trimmed_local_key $local_key_data

		set ipsecSecrets "${ipsecSecrets}: RSA $trimmed_local_key"
	}

	writeDataToNodeFile $node_id /usr/local/etc/ipsec.conf $ipsecConf
	writeDataToNodeFile $node_id /usr/local/etc/ipsec.secrets $ipsecSecrets
}

proc sshServiceStartCmds {} {
	return { "service sshd onestart" }
}

proc sshServiceStopCmds {} {
	return { "service sshd onestop" }
}

proc inetdServiceRestartCmds {} {
	return "service inetd onerestart"
}

# XXX nat64 procedures
proc configureTunIface { tayga4pool tayga6prefix } {
	set cfg {}

	# we cannot set interface name here because tayga doesn't see it if we do
	lappend cfg "ifid=\$(ifconfig tun create)"
	lappend cfg "ifconfig \$ifid inet6 -ifdisabled"
	lappend cfg "[getStateIfcCmd "\$ifid" "up"]"
	lappend cfg "[getIPv4IfcRouteCmd $tayga4pool "\$ifid"]"
	lappend cfg "[getIPv6IfcRouteCmd $tayga6prefix "\$ifid"]"
	lappend cfg "sed -i '' \"s/tun-device\ttun64/tun-device\t\$ifid/\" /usr/local/etc/tayga.conf"

	if { $tayga4pool != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "!"
		lappend cfg "ip route $tayga4pool \$ifid"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	if { $tayga6prefix != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "ipv6 route $tayga6prefix \$ifid"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	return $cfg
}

proc unconfigureTunIface { tayga4pool tayga6prefix } {
	set cfg {}

	lappend cfg "ifid=\$(cat /usr/local/etc/tayga.conf | grep tun-device | awk '{print \$NF}')"
	if { $tayga4pool != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "!"
		lappend cfg "no ip route $tayga4pool \$ifid"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	if { $tayga6prefix != "" } {
		lappend cfg "vtysh << __EOF__"
		lappend cfg "conf term"

		lappend cfg "no ipv6 route $tayga6prefix \$ifid"

		lappend cfg "!"
		lappend cfg "__EOF__"
	}

	lappend cfg "[getStateIfcCmd "\$ifid" "down"]"

	return $cfg
}

proc startRoutingDaemons { node_id } {
	set cmds "zebra -dP0"
	set cmds "$cmds; staticd -dP0"

	foreach protocol { rip ripng ospf ospf6 } {
		if { [getNodeProtocol $node_id $protocol] != 1 } {
			continue
		}

		set cmds "$cmds; ${protocol}d -dP0"
	}

	foreach protocol { ldp bfd } {
		if { [getNodeProtocol $node_id $protocol] != 1 } {
			continue
		}

		set cmds "$cmds; ${protocol}d -dP0"
	}

	foreach protocol { bgp isis } {
		if { [getNodeProtocol $node_id $protocol] != 1 } {
			continue
		}

		set cmds "$cmds; ${protocol}d -dP0"
	}

	set cmds "$cmds; sed -i '' '/Disabling MPLS support/d' /err.log"

	pipesExec "jexec [getFromRunning "eid"].$node_id sh -c '$cmds'" "hold"
}
