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
	if { [catch { rexec test -d $node_dir}] } {
		return
	}

	writeDataToFile $node_dir/$path $data
}

#****f* freebsd.tcl/execCmdNode
# NAME
#   execCmdNode -- execute command on virtual node
# SYNOPSIS
#   execCmdNode $node_id $cmd
# FUNCTION
#   Executes a command on a virtual node and returns the output.
# INPUTS
#   * node_id -- virtual node id
#   * cmd -- command to execute
# RESULT
#   * returns the execution output
#****
proc execCmdNode { node_id cmd } {
	catch { eval [concat "rexec jexec " [getFromRunning "eid"].$node_id $cmd] } output

	return $output
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
#   by using the which command.
# INPUTS
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForExternalApps { app_list } {
	foreach app $app_list {
		set status [ catch { exec which $app } err ]
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
#   the which command.
# INPUTS
#   * node_id -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node_id app_list } {
	foreach app $app_list {
		set status [ catch { rexec jexec [getFromRunning "eid"].$node_id which $app } err ]
		if { $status } {
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
		puts stderr "Running X applications in nodes on remote host is not supported."

		return
	}

	if { [checkForExternalApps "socat"] != 0 } {
		puts stderr "To run X applications on the node, install socat on your host."
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
		spawnShell $node_id "tcpdump -ni $ifc"
	}
}

#****f* freebsd.tcl/existingShells
# NAME
#   existingShells -- check which shells exist in a node
# SYNOPSIS
#   existingShells $shells $node_id
# FUNCTION
#   This procedure checks which of the provided shells are available
#   in a running node.
# INPUTS
#   * shells -- list of shells.
#   * node_id -- node id of the node for which the check is performed.
#****
proc existingShells { shells node_id { first_only "" } } {
	set cmds "retval=\"\" ;\n"
	append cmds "\n"
	append cmds "for s in $shells; do\n"
	append cmds "	x=\"\$(which \$s)\" ;\n"
	append cmds "	test \$? -eq 0 && retval=\"\$retval \$x\" "
	if { $first_only != "" } {
		append cmds "&& break; \n"
	} else {
		append cmds "; \n"
	}
	append cmds "done ;\n"
	append cmds "echo \"\$retval\"\n"

	set cmds "\'$cmds\'"

	catch { rexec jexec [getFromRunning "eid"].$node_id sh -c {*}$cmds } existing

	return $existing
}

#****f* freebsd.tcl/spawnShell
# NAME
#   spawnShell -- spawn shell
# SYNOPSIS
#   spawnShell $node_id $cmd
# FUNCTION
#   This procedure spawns a new shell for a specified node.
#   The shell is specified in cmd parameter.
# INPUTS
#   * node_id -- node id of the node for which the shell is spawned.
#   * cmd -- the path to the shell.
#****
proc spawnShell { node_id cmd } {
	global ttyrcmd

	if { [checkTerminalMissing] } {
		return
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	exec xterm -name imunes-terminal \
		-T "IMUNES: [getNodeName $node_id] (console) [lindex [split $cmd /] end]" \
		-e {*}$ttyrcmd "jexec $jail_id $cmd" &
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
					puts stderr $msg
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
					puts stderr "The main snapshot for virtual nodes is missing.
					Run 'make' or 'make vroot' to create the main ZFS snapshot."
				} else {
					puts stderr "Error: ZFS snapshot image \"$snapshot\" for node \"$node_id\" is missing."
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
	if { [catch { rexec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT" } err] == 0 } {
		set timeoutNeeded 1
		break
	}

	if { $timeoutNeeded == 0 } {
		return
	}

	set sec 60
	if { ! $gui || $execMode == "batch" } {
		puts "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec). "
		puts "Please don't try killing the process."
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
		while { [catch { rexec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT" } err] == 0 } {
			set spin 1
			after 1000
			set sec [expr $sec - 1]
			if { ! $gui || $execMode == "batch" } {
				puts -nonewline "."
				flush stdout
			} else {
				statline "~ $sec seconds ..."
				$w.p step -1
				update
			}
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

#****f* freebsd.tcl/execSetIfcVlanConfig
# NAME
#   execSetIfcVlanConfig -- in exec mode set interface vlan configuration
# SYNOPSIS
#   execSetIfcVlanConfig $node_id $iface_id
# FUNCTION
#   Configures VLAN type and tag during the simulation.
# INPUTS
#   node_id -- node id
#   iface_id -- interface name
#****
proc execSetIfcVlanConfig { node_id iface_id } {
	set vlantype [getIfcVlanType $node_id $iface_id]
	set vlantag [getIfcVlanTag $node_id $iface_id]

	if { $vlantype == "trunk" } {
		set hook_name "downstream"
		set addfilter ""
	} else {
		set hook_name "v$vlantag"
		set addfilter "msg $node_id-vlan: addfilter { vlan=$vlantag hook=\\\"$hook_name\\\" }\n"
	}

	set total_hooks [getFromRunning "${node_id}|${hook_name}_hooks"]
	if { $total_hooks != "" } {
		# bridge already exists
		setToRunning "${node_id}|${hook_name}_hooks" [incr total_hooks]

		return
	}

	set ngcmds "mkpeer $node_id-vlan: bridge $hook_name link0\n"
	append ngcmds "name $node_id-vlan:$hook_name $node_id-$hook_name\n"
	append ngcmds $addfilter

	pipesExec "printf \"$ngcmds\" | jexec [getFromRunning "eid"] ngctl -f -" "hold"

	setToRunning "${node_id}|${hook_name}_hooks" 1
}

#****f* freebsd.tcl/execDelIfcVlanConfig
# NAME
#   execDelIfcVlanConfig -- in exec mode restore interface vlan configuration
# SYNOPSIS
#   execDelIfcVlanConfig $eid $node_id $iface_id
# FUNCTION
#   Restores VLAN configuration to the default state during the simulation.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface_id -- interface name
#****
proc execDelIfcVlanConfig { eid node_id iface_id } {
	set vlantag [getIfcVlanTag $node_id $iface_id]
	set vlantype [getIfcVlanType $node_id $iface_id]

	if { $vlantype == "trunk" } {
		set hook_name "downstream"
	} else {
		set hook_name "v$vlantag"
	}

	set total_hooks [getFromRunning "${node_id}|${hook_name}_hooks"]
	if { $total_hooks > 1 } {
		# not the last link on bridge
		setToRunning "${node_id}|${hook_name}_hooks" [incr total_hooks -1]

		return
	}

	set ngcmds "shutdown $node_id-vlan:$hook_name\n"
	pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"

	unsetRunning "${node_id}|${hook_name}_hooks"
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

#****f* freebsd.tcl/killProcess
# NAME
#   killProcess -- kill processes with the given regex
# SYNOPSIS
#   killProcess $regex
# FUNCTION
#   Executes a pkill command to kill all processes with a corresponding regex.
# INPUTS
#   * regex -- regularl expression of the processes
#****
proc killExtProcess { regex } {
	pipesExec "pkill -f \"$regex\"" "hold"
}

proc fetchInterfaceData { node_id iface_id } {
	global node_existing_mac node_existing_ipv4 node_existing_ipv6
	set node_existing_mac [getFromRunning "mac_used_list"]
	set node_existing_ipv4 [getFromRunning "ipv4_used_list"]
	set node_existing_ipv6 [getFromRunning "ipv6_used_list"]

	global node_cfg

	set iface_name [_getIfcName $node_cfg $iface_id]
	if { $iface_name ni [getExtIfcs] } {
		puts "No interface $iface_name."

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
proc getHostIfcList {} {
	# fetch interface list from the system
	set extifcs [rexec ifconfig -l]
	# exclude loopback interface
	set ilo [lsearch $extifcs lo0]
	set extifcs [lreplace $extifcs $ilo $ilo]

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
		puts stderr $msg
	} else {
		after idle { .dialog1.msg configure -wraplength 4i }
		tk_dialog .dialog1 "IMUNES error" $msg \
			info 0 Dismiss
	}

	return 1
}

#****f* freebsd.tcl/prepareFilesystemForNode
# NAME
#   prepareFilesystemForNode -- prepare node filesystem
# SYNOPSIS
#   prepareFilesystemForNode $node_id
# FUNCTION
#   Prepares the node virtual filesystem.
# INPUTS
#   * node_id -- node id
#****
proc prepareFilesystemForNode { node_id } {
	global vroot_unionfs vroot_linprocfs devfs_number

	set eid [getFromRunning "eid"]

	# Prepare a copy-on-write filesystem root
	if { $vroot_unionfs } {
		# UNIONFS
		set VROOTDIR [getVrootDir]
		set VROOT_RUNTIME $VROOTDIR/$eid/$node_id
		set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node_id
		set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

		pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
		pipesExec "mkdir -p $VROOT_OVERLAY" "hold"

		set vroot [lindex [split [getNodeCustomImage $node_id] " "] end]
		if { $vroot == "" } {
			set vroot "$VROOTDIR/vroot"
		}
		pipesExec "mount_nullfs -o ro $vroot $VROOT_RUNTIME" "hold"
		pipesExec "mount_unionfs -o noatime $VROOT_OVERLAY $VROOT_RUNTIME" "hold"
	} else {
		# ZFS
		set VROOT_ZFS vroot/$eid/$node_id
		set VROOT_RUNTIME /$VROOT_ZFS
		set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

		set snapshot [getNodeSnapshot $node_id]
		if { $snapshot == "" } {
			set snapshot "vroot/vroot@clean"
		}

		pipesExec "zfs clone $snapshot $VROOT_ZFS" "hold"
	}

	if { $vroot_linprocfs } {
		pipesExec "mount -t linprocfs linprocfs $VROOT_RUNTIME/compat/linux/proc" "hold"
		#HACK - linux_sun_jdk16 - java hack, won't work if proc isn't accessed
		#before execution, so we need to cd to it.
		pipesExec "cd $VROOT_RUNTIME/compat/linux/proc" "hold"
	}

	# Mount and configure a restricted /dev
	pipesExec "mount -t devfs devfs $VROOT_RUNTIME_DEV" "hold"
	pipesExec "devfs -m $VROOT_RUNTIME_DEV ruleset $devfs_number" "hold"
	pipesExec "devfs -m $VROOT_RUNTIME_DEV rule applyset" "hold"
}

#****f* freebsd.tcl/createNodeContainer
# NAME
#   createNodeContainer -- create a node container
# SYNOPSIS
#   createNodeContainer $node_id
# FUNCTION
#   Creates a jail (container) for the given node.
# INPUTS
#   * node_id -- node id
#****
proc createNodeContainer { node_id } {
	set node_dir [getNodeDir $node_id]

	set jail_cmd "jail -c name=[getFromRunning "eid"].$node_id path=$node_dir securelevel=1 \
		host.hostname=\"[getNodeName $node_id]\" vnet persist"

	dputs "Node $node_id -> '$jail_cmd'"

	pipesExec "$jail_cmd" "hold"
}

proc isNodeStarted { node_id } {
	global nodecreate_timeout

	set node_type [getNodeType $node_id]
	if { [$node_type.virtlayer] != "VIRTUALIZED" } {
		if { $node_type in "rj45 ext" } {
			return true
		}

		try {
			rexec jexec [getFromRunning "eid"] ngctl show $node_id:
		} on error {} {
			return false
		}

		return true
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	try {
		if { $nodecreate_timeout >= 0 } {
			rexec timeout [expr $nodecreate_timeout/5.0] jls -j $jail_id
		} else {
			rexec jls -j $jail_id
		}
	} on error {} {
		return false
	}

	return true
}

proc isNodeNamespaceCreated { node_id } {
	return true
}

#****f* freebsd.tcl/nodePhysIfacesCreate
# NAME
#   nodePhysIfacesCreate -- create node physical interfaces
# SYNOPSIS
#   nodePhysIfacesCreate $node_id
# FUNCTION
#   Creates physical interfaces for the given node.
# INPUTS
#   * node_id -- node id
#****
proc nodePhysIfacesCreate { node_id ifaces } {
	set eid [getFromRunning "eid"]
	set jail_id "$eid.$node_id"

	set node_type [getNodeType $node_id]

	# Create a vimage
	# Create "physical" network interfaces
	foreach iface_id $ifaces {
		setToRunning "${node_id}|${iface_id}_running" "creating"

		set iface_name [getIfcName $node_id $iface_id]
		set public_hook $node_id-$iface_name
		set prefix [string trimright $iface_name "0123456789"]
		if { $node_type == "ext" } {
			set iface_name $node_id
		}

		switch -exact $prefix {
			e {
			}
			eth {
				# save newly created ngnodeX into a shell variable ifid and
				# rename the ng node to $public_hook (unique to this experiment)
				set cmds "ifid=\$(printf \"mkpeer . eiface $public_hook ether \n"
				set cmds "$cmds show .:$public_hook\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
				set cmds "$cmds; jexec $eid ngctl name \$ifid: $public_hook"
				set cmds "$cmds; jexec $eid ifconfig \$ifid name $public_hook"

				pipesExec $cmds "hold"
				pipesExec "jexec $eid ifconfig $public_hook vnet $node_id" "hold"
				pipesExec "jexec $jail_id ifconfig $public_hook name $iface_name" "hold"

				set ether [getIfcMACaddr $node_id $iface_id]
				if { $ether == "" } {
					autoMACaddr $node_id $iface_id
				}
				set ether [getIfcMACaddr $node_id $iface_id]

				global ifc_dad_disable
				if { $ifc_dad_disable } {
					pipesExec "jexec $jail_id sysctl net.inet6.ip6.dad_count=0" "hold"
				}

				pipesExec "jexec $jail_id ifconfig $iface_name link $ether" "hold"
			}
			ext {
				set outifc "$eid-$node_id"

				# save newly created ngnodeX into a shell variable ifid and
				# rename the ng node to $public_hook (unique to this experiment)
				set cmds "ifid=\$(printf \"mkpeer . eiface $public_hook ether \n"
				set cmds "$cmds show .:$public_hook\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
				set cmds "$cmds; jexec $eid ngctl name \$ifid: $public_hook"
				set cmds "$cmds; jexec $eid ifconfig \$ifid name $outifc"

				pipesExec $cmds "hold"
				pipesExec "ifconfig $outifc -vnet $eid" "hold"

				set ether [getIfcMACaddr $node_id $iface_id]
				if { $ether == "" } {
					autoMACaddr $node_id $iface_id
				}

				set ether [getIfcMACaddr $node_id $iface_id]
				pipesExec "ifconfig $outifc link $ether" "hold"
			}
			default {
				# capture physical interface directly into the node, without using a bridge
				# we don't know the name, so make sure all other options cover other IMUNES
				# 'physical' interfaces
				# XXX not yet implemented
				if { [getIfcType $node_id $iface_id] == "stolen" } {
					captureExtIfcByName $eid $iface_name $node_id
					if { [getNodeType $node_id] in "hub lanswitch" } {
						lassign [[getNodeType $node_id].nghook $eid $node_id $iface_id] \
							ngpeer1 nghook1
						lassign "$iface_name lower" \
							ngpeer2 nghook2

						pipesExec "jexec $eid ngctl connect $ngpeer1: $ngpeer2: $nghook1 $nghook2" "hold"
					}
				}
			}
		}
	}

	pipesExec ""
}

proc attachToL3NodeNamespace { node_id } {}

proc createNamespace { ns } {}

proc destroyNamespace { ns } {}

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
					setToRunning "${node_id}|${iface_id}_running" "creating"
				} else {
					setToRunning "${node_id}|${iface_id}_running" "false"
				}
			}
			lo {
				setToRunning "${node_id}|${iface_id}_running" "creating"
				if { $iface_name != "lo0" } {
					pipesExec "jexec $jail_id ifconfig $iface_name create" "hold"
				}
			}
		}
	}
}

#****f* freebsd.tcl/configureICMPoptions
# NAME
#   configureICMPoptions -- configure ICMP options
# SYNOPSIS
#   configureICMPoptions $node_id
# FUNCTION
#  Configures the necessary ICMP sysctls in the given node.
# INPUTS
#   * node_id -- node id
#****
proc configureICMPoptions { node_id } {
	set jail_id "[getFromRunning "eid"].$node_id"

	pipesExec "jexec $jail_id sysctl net.inet.icmp.bmcastecho=1" "hold"
	pipesExec "jexec $jail_id sysctl net.inet.icmp.icmplim=0" "hold"

	# Enable more fragments per packet for IPv4
	pipesExec "jexec $jail_id sysctl net.inet.ip.maxfragsperpacket=64000" "hold"
	pipesExec "jexec $jail_id touch /tmp/init" "hold"
}

proc isNodeInitNet { node_id } {
	global nodecreate_timeout

	set jail_id "[getFromRunning "eid"].$node_id"

	try {
		if { $nodecreate_timeout >= 0 } {
			rexec timeout [expr $nodecreate_timeout/5.0] jexec $jail_id rm /tmp/init > /dev/null
		} else {
			rexec jexec $jail_id rm /tmp/init > /dev/null
		}
	} on error {} {
		return false
	}

	return true
}

#****f* freebsd.tcl/runConfOnNode
# NAME
#   runConfOnNode -- run configuration script on node
# SYNOPSIS
#   runConfOnNode $node_id
# FUNCTION
#   Run startup configuration file on the given node.
# INPUTS
#   * node_id -- node id
#****
proc runConfOnNode { node_id } {
	global nodeconf_timeout

	set jail_id "[getFromRunning "eid"].$node_id"

	set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		set bootcmd [getNodeCustomConfigCommand $node_id "NODE_CONFIG" $custom_selected]
		set bootcfg [getNodeCustomConfig $node_id "NODE_CONFIG" $custom_selected]
		set bootcfg "$bootcfg\n[join [[getNodeType $node_id].generateConfig $node_id] "\n"]"
		set confFile "custom.conf"
	} else {
		set bootcfg [join [[getNodeType $node_id].generateConfig $node_id] "\n"]
		set bootcmd [[getNodeType $node_id].bootcmd $node_id]
		set confFile "boot.conf"
	}

	generateHostsFile $node_id

	set cfg "set -x\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg
	set cmds "rm -f /out.log /err.log ;"
	set cmds "$cmds $bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
	# renaming the file signals that we're done
	set cmds "$cmds mv /tout.log /out.log ;"
	set cmds "$cmds mv /terr.log /err.log"
	if { $nodeconf_timeout >= 0 } {
		pipesExec "timeout --foreground $nodeconf_timeout jexec $jail_id sh -c '$cmds'" "hold"
	} else {
		pipesExec "jexec $jail_id sh -c '$cmds'" "hold"
	}
}

proc startNodeIfaces { node_id ifaces } {
	global ifacesconf_timeout

	set jail_id "[getFromRunning "eid"].$node_id"

	set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		set bootcmd [getNodeCustomConfigCommand $node_id "IFACES_CONFIG" $custom_selected]
		set bootcfg [getNodeCustomConfig $node_id "IFACES_CONFIG" $custom_selected]
		set confFile "custom_ifaces.conf"
	} else {
		set bootcfg [join [[getNodeType $node_id].generateConfigIfaces $node_id $ifaces] "\n"]
		set bootcmd [[getNodeType $node_id].bootcmd $node_id]
		set confFile "boot_ifaces.conf"
	}

	set cfg "set -x\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg
	set cmds "rm -f /out_ifaces.log /err_ifaces.log ;"
	set cmds "$cmds $bootcmd /$confFile >> /tout_ifaces.log 2>> /terr_ifaces.log ;"
	# renaming the file signals that we're done
	set cmds "$cmds mv /tout_ifaces.log /out_ifaces.log ;"
	set cmds "$cmds mv /terr_ifaces.log /err_ifaces.log"
	if { $ifacesconf_timeout >= 0 } {
		pipesExec "timeout --foreground $ifacesconf_timeout jexec $jail_id sh -c '$cmds'" "hold"
	} else {
		pipesExec "jexec $jail_id sh -c '$cmds'" "hold"
	}
}

proc unconfigNode { eid node_id } {
	set jail_id "$eid.$node_id"

	set custom_selected [getNodeCustomConfigSelected $node_id "NODE_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		return
	}

	set bootcfg [join [[getNodeType $node_id].generateUnconfig $node_id] "\n"]
	set bootcmd [[getNodeType $node_id].bootcmd $node_id]
	set confFile "unboot.conf"

	set cfg "set -x\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg
	set cmds "rm -f /out.log /err.log ;"
	set cmds "$cmds $bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
	# renaming the file signals that we're done
	set cmds "$cmds mv /tout.log /out.log ;"
	set cmds "$cmds mv /terr.log /err.log"
	pipesExec "jexec $jail_id sh -c '$cmds'" "hold"
}

proc unconfigNodeIfaces { eid node_id ifaces } {
	set jail_id "$eid.$node_id"

	set custom_selected [getNodeCustomConfigSelected $node_id "IFACES_CONFIG"]
	if { [getNodeCustomEnabled $node_id] == true && $custom_selected ni "\"\" DISABLED" } {
		return
	}

	set bootcfg [join [[getNodeType $node_id].generateUnconfigIfaces $node_id $ifaces] "\n"]
	set bootcmd [[getNodeType $node_id].bootcmd $node_id]
	set confFile "unboot_ifaces.conf"

	set cfg "set -x\n$bootcfg"
	writeDataToNodeFile $node_id /$confFile $cfg
	set cmds "rm -f /out_ifaces.log /err_ifaces.log ;"
	set cmds "$cmds $bootcmd /$confFile >> /tout_ifaces.log 2>> /terr_ifaces.log ;"
	# renaming the file signals that we're done
	set cmds "$cmds mv /tout_ifaces.log /out_ifaces.log ;"
	set cmds "$cmds mv /terr_ifaces.log /err_ifaces.log"
	pipesExec "jexec $jail_id sh -c '$cmds'" "hold"
}

proc isNodeIfacesCreated { node_id ifaces } {
	global ifacesconf_timeout

	set eid [getFromRunning "eid"]

	set node_type [getNodeType $node_id]
	if { [$node_type.virtlayer] == "NATIVE" && $node_type != "rj45" } {
		# TODO: other nodes?
		return $ifaces
	}

	if { $node_type == "rj45" } {
		set jail_id $eid
	} else {
		set jail_id "$eid.$node_id"
	}

	set cmds "retval=\"\" ;\n"
	foreach iface_id $ifaces {
		if { [getFromRunning "${node_id}|${iface_id}_running"] == "true" } {
			continue
		}

		set iface_name [getIfcName $node_id $iface_id]

		if { $node_type == "rj45" } {
			set vlan [getIfcVlanTag $node_id $iface_id]
			if { $vlan != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
				set iface_name $iface_name.$vlan
			}
		}

		append cmds "x=\$(ifconfig $iface_name) ;\n"
		append cmds "test \$? -eq 0 && retval=\"\$retval $iface_id\" ;\n"
	}
	append cmds "echo \"\$retval\" ;"
	set cmds "\'$cmds\'"

	catch {
		if { $ifacesconf_timeout >= 0 } {
			rexec timeout [expr $ifacesconf_timeout/5.0] jexec $jail_id sh -c {*}$cmds
		} else {
			rexec jexec $jail_id sh -c {*}$cmds
		}
	} created_ifaces

	return $created_ifaces
}

proc isNodeIfacesConfigured { node_id } {
	global ifacesconf_timeout

	set jail_id "[getFromRunning "eid"].$node_id"

	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		return true
	}

	try {
		if { $ifacesconf_timeout >= 0 } {
			rexec timeout [expr $ifacesconf_timeout/5.0] jexec $jail_id test -f /out_ifaces.log > /dev/null
		} else {
			rexec jexec $jail_id test -f /out_ifaces.log > /dev/null
		}
	} on error {} {
		return false
	}

	return true
}

proc isLinkStarted { link_id } {
	global nodecreate_timeout

	set mirror_link_id [getLinkMirror $link_id]
	if { $mirror_link_id != "" && [getFromRunning "${mirror_link_id}_running"] == "true" } {
		return true
	}

	lassign [getLinkPeers $link_id] node1_id node2_id
	if {
		[getLinkDirect $link_id] ||
		"wlan" in "[getNodeType $node1_id] [getNodeType $node2_id]"
	} {
		# TODO
		return true
	}

	set eid [getFromRunning "eid"]

	try {
		if { $nodecreate_timeout >= 0 } {
			rexec timeout [expr $nodecreate_timeout/5.0] jexec $eid ngctl show $link_id:
		} else {
			rexec jexec $eid ngctl show $link_id:
		}
	} on error {} {
		return false
	}

	return true
}

proc isNodeConfigured { node_id } {
	global nodeconf_timeout

	set jail_id "[getFromRunning "eid"].$node_id"

	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		return true
	}

	try {
		if { $nodeconf_timeout >= 0 } {
			rexec timeout [expr $nodeconf_timeout/5.0] jexec $jail_id test -f /out.log > /dev/null
		} else {
			rexec jexec $jail_id test -f /out.log > /dev/null
		}
	} on error {} {
		return false
	}

	return true
}

proc isNodeError { node_id } {
	global nodeconf_timeout

	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		return false
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	try {
		set cmd "sed \"/^+ /d\" /err.log"
		if { $nodeconf_timeout >= 0 } {
			rexec timeout [expr $nodeconf_timeout/5.0] jexec $jail_id $cmd
		} else {
			rexec jexec $jail_id $cmd
		}
	} on error {} {
		return ""
	} on ok errlog {
		if { $errlog == "" } {
			return false
		}

		return true
	}
}

proc isNodeErrorIfaces { node_id } {
	global ifacesconf_timeout

	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		return false
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	try {
		set cmd "sed \"/^+ /d\" /err_ifaces.log"
		if { $ifacesconf_timeout >= 0 } {
			rexec timeout [expr $ifacesconf_timeout/5.0] jexec $jail_id $cmd
		} else {
			rexec jexec $jail_id $cmd
		}
	} on error {} {
		return ""
	} on ok errlog {
		if { $errlog == "" } {
			return false
		}

		return true
	}
}

proc isNodeUnconfigured { node_id } {
	global skip_nodes nodeconf_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		return true
	}

	try {
		set cmd "\'test ! -f /tout.log && test -f /out.log\'"
		if { $nodeconf_timeout >= 0 } {
			rexec timeout [expr $nodeconf_timeout/5.0] jexec $jail_id sh -c {*}$cmd
		} else {
			rexec jexec $jail_id sh -c {*}$cmd
		}
	} on error {} {
		return false
	}

	return true
}

proc isNodeIfacesUnconfigured { node_id } {
	global skip_nodes ifacesconf_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		return true
	}

	try {
		set cmd "\'test ! -f /tout_ifaces.log && test -f /out_ifaces.log\'"
		if { $ifacesconf_timeout >= 0 } {
			rexec timeout [expr $ifacesconf_timeout/5.0] jexec $jail_id sh -c {*}$cmd
		} else {
			rexec jexec $jail_id sh -c {*}$cmd
		}
	} on error {} {
		return false
	}

	return true
}

proc isNodeStopped { node_id } {
	global skip_nodes nodeconf_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		return true
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	try {
		if { $nodeconf_timeout >= 0 } {
			rexec timeout [expr $nodeconf_timeout/5.0] jexec $jail_id rm /tmp/shut > /dev/null
		} else {
			rexec jexec $jail_id rm /tmp/shut > /dev/null
		}
	} on error {} {
		return false
	}

	return true
}

proc isLinkDestroyed { link_id } {
	global nodecreate_timeout skip_links

	if {
		$link_id in $skip_links ||
		[getFromRunning "${link_id}_running"] != "true"
	} {
		return true
	}

	set mirror_link_id [getLinkMirror $link_id]
	if { $mirror_link_id != "" && [getFromRunning "${mirror_link_id}_running"] != "true" } {
		return true
	}

	lassign [getLinkPeers $link_id] node1_id node2_id
	if { "wlan" in "[getNodeType $node1_id] [getNodeType $node2_id]" } {
		# TODO
		return true
	}

	set eid [getFromRunning "eid"]

	try {
		if { $nodecreate_timeout >= 0 } {
			rexec timeout [expr $nodecreate_timeout/5.0] jexec $eid ngctl show $link_id:
		} else {
			rexec jexec $eid ngctl show $link_id:
		}
	} on error {} {
		return true
	}

	return false
}

proc isNodeIfacesDestroyed { node_id ifaces } {
	global skip_nodes ifacesconf_timeout

	if {
		$node_id in $skip_nodes || $ifaces == "" ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	set eid [getFromRunning "eid"]

	set node_type [getNodeType $node_id]
	if { $node_type == "ext" } {
		return [catch { rexec ! ifconfig $eid-$node_id }]
	}

	set cmds ""
	foreach iface_id $ifaces {
		set iface_name [getIfcName $node_id $iface_id]
		if { $iface_name in "lo0" } {
			continue
		}

		if { [isIfcLogical $node_id $iface_id] } {
			append cmds "jexec $eid.$node_id ifconfig $iface_name > /dev/null 2>/dev/null || "
		} else {
			append cmds "jexec $eid ngctl show $node_id-$iface_name: > /dev/null 2>/dev/null || "
		}
	}

	append cmds "false"
	set cmd "\'$cmds\'"

	try {
		if { $ifacesconf_timeout >= 0 } {
			rexec timeout [expr $ifacesconf_timeout/5.0] sh -c "$cmds"
		} else {
			rexec sh -c "$cmds"
		}
	} on error {} {
		return true
	}

	return false
}

proc isNodeDestroyed { node_id } {
	global skip_nodes nodecreate_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	set node_type [getNodeType $node_id]
	if { [$node_type.virtlayer] != "VIRTUALIZED" } {
		if { $node_type in "rj45 ext" } {
			return true
		}

		try {
			rexec jexec [getFromRunning "eid"] ngctl show $node_id:
		} on error {} {
			return true
		}

		return false
	}

	set jail_id "[getFromRunning "eid"].$node_id"

	try {
		if { $nodecreate_timeout >= 0 } {
			rexec timeout [expr $nodecreate_timeout/5.0] jls -d -j $jail_id
		} else {
			rexec jls -d -j $jail_id
		}
	} on error {} {
		return true
	}

	return false
}

proc isNodeDestroyedFS { node_id } {
	global skip_nodes nodecreate_timeout

	if {
		$node_id in $skip_nodes ||
		[getFromRunning "${node_id}_running"] ni "true delete"
	} {
		return true
	}

	if { [[getNodeType $node_id].virtlayer] != "VIRTUALIZED" } {
		return true
	}

	return [catch { rexec ! test -d [getVrootDir]/$eid/$node_id }]
}

#****f* freebsd.tcl/killAllNodeProcesses
# NAME
#   killAllNodeProcesses -- kill all node processes
# SYNOPSIS
#   killAllNodeProcesses $eid $node_id
# FUNCTION
#   Kills all processes in the given node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc killAllNodeProcesses { eid node_id } {
	set jail_id "$eid.$node_id"

	pipesExec "jexec $jail_id kill -9 -1 2> /dev/null" "hold"
	pipesExec "jexec $jail_id tcpdrop -a 2> /dev/null" "hold"
	pipesExec "jexec $jail_id touch /tmp/shut" "hold"
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

#****f* freebsd.tcl/destroyNodeVirtIfcs
# NAME
#   destroyNodeVirtIfcs -- destroy node virtual interfaces
# SYNOPSIS
#   destroyNodeVirtIfcs $eid $node_id
# FUNCTION
#   Destroy any virtual interfaces (tun, vlan, gif, ..) before removing the #
#   jail. This is to avoid possible kernel panics.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc destroyNodeVirtIfcs { eid node_id } {
	set jail_id $eid.$node_id

	pipesExec "jexec $jail_id sh -c 'for iface in \$(ifconfig -l); do echo \$iface ; ifconfig \$iface destroy ; done'" "hold"
}

#****f* freebsd.tcl/removeNodeContainer
# NAME
#   removeNodeContainer -- remove node container
# SYNOPSIS
#   removeNodeContainer $eid $node_id
# FUNCTION
#   Removes the jail (container) of the given node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc removeNodeContainer { eid node_id } {
	set jail_id $eid.$node_id

	pipesExec "jail -r $jail_id" "hold"
}

#****f* freebsd.tcl/removeNodeFS
# NAME
#   removeNodeFS -- remove node filesystem
# SYNOPSIS
#   removeNodeFS $eid $node_id
# FUNCTION
#   Removes the filesystem of the given node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc removeNodeFS { eid node_id } {
	global vroot_unionfs vroot_linprocfs

	set jail_id $eid.$node_id

	set VROOTDIR [getVrootDir]
	set VROOT_RUNTIME $VROOTDIR/$eid/$node_id
	set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node_id
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
	pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
	if { $vroot_unionfs } {
		# 1st: unionfs RW overlay
		pipesExec "umount -f $VROOT_RUNTIME" "hold"
		# 2nd: nullfs RO loopback
		pipesExec "umount -f $VROOT_RUNTIME" "hold"
		pipesExec "rm -rf $VROOT_RUNTIME" "hold"
		# 3rd: node unionfs upper
		pipesExec "rm -rf $VROOT_OVERLAY" "hold"
	}

	if { $vroot_linprocfs } {
		pipesExec "umount -f $VROOT_RUNTIME/compat/linux/proc" "hold"
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

	catch { rexec kldload nullfs }
	catch { rexec kldload unionfs }

	catch { rexec kldload ng_eiface }
	catch { rexec kldload ng_pipe }
	catch { rexec kldload ng_socket }
	catch { rexec kldload if_tun }
	catch { rexec kldload vlan }
	catch { rexec kldload ipsec }
	catch { rexec kldload pf }
	#catch { rexec kldload ng_iface }
	#catch { rexec kldload ng_cisco }

	foreach module $all_modules_list {
		if { [info procs $module.prepareSystem] == "$module.prepareSystem" } {
			$module.prepareSystem
		}
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

	set ngpeer1 \
		[lindex [[getNodeType $node1_id].nghook $eid $node1_id $iface1_id] 0]
	set ngpeer2 \
		[lindex [[getNodeType $node2_id].nghook $eid $node2_id $iface2_id] 0]
	set nghook1 \
		[lindex [[getNodeType $node1_id].nghook $eid $node1_id $iface1_id] 1]
	set nghook2 \
		[lindex [[getNodeType $node2_id].nghook $eid $node2_id $iface2_id] 1]

	# for direct links, skip pipe creation
	if { [getLinkDirect $link_id] } {
		pipesExec "jexec $eid ngctl connect $ngpeer1: $ngpeer2: $nghook1 $nghook2" "hold"

		return
	}

	set ngcmds "mkpeer $ngpeer1: pipe $nghook1 upper"
	set ngcmds "$ngcmds\n name $ngpeer1:$nghook1 $link_id"
	set ngcmds "$ngcmds\n connect $link_id: $ngpeer2: lower $nghook2"

	pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"
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
	if { [getLinkDirect $link_id] || "wlan" in "[getNodeType $node1_id] [getNodeType $node2_id]" } {
		lassign [[getNodeType $node1_id].nghook $eid $node1_id $iface1_id] ngpeer1 nghook1
		lassign [[getNodeType $node2_id].nghook $eid $node2_id $iface2_id] ngpeer2 nghook2

		pipesExec "jexec $eid ngctl disconnect $ngpeer1: $nghook1" "hold"
		pipesExec "jexec $eid ngctl disconnect $ngpeer2: $nghook2" "hold"

		return
	}

	pipesExec "jexec $eid ngctl msg $link_id: shutdown" "hold"
}

#****f* freebsd.tcl/nodeIfacesDestroy
# NAME
#   nodeIfacesDestroy -- destroy virtual node interfaces
# SYNOPSIS
#   nodeIfacesDestroy $eid $vimages
# FUNCTION
#   Destroys all virtual node interfaces.
# INPUTS
#   * eid -- experiment id
#   * vimages -- list of virtual nodes
#****
proc nodeIfacesDestroy { eid node_id ifaces } {
	set node_type [getNodeType $node_id]
	if { $node_type == "rj45" } {
		foreach iface_id $ifaces {
			releaseExtIfcByName $eid [getIfcName $node_id $iface_id] $node_id
		}
	} else {
		foreach iface_id $ifaces {
			set iface_name [getIfcName $node_id $iface_id]
			if { [getIfcType $node_id $iface_id] == "stolen" } {
				releaseExtIfcByName $eid $iface_name $node_id
			} elseif { [isIfcLogical $node_id $iface_id] } {
				pipesExec "jexec $eid\.$node_id ifconfig $iface_name destroy" "hold"
			} else {
				pipesExec "jexec $eid ngctl rmnode $node_id-$iface_name:" "hold"
			}
		}
	}

	foreach iface_id $ifaces {
		setToRunning "${node_id}|${iface_id}_running" "false"
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

#****f* freebsd.tcl/l2node.nodeCreate
# NAME
#   l2node.nodeCreate -- instantiate
# SYNOPSIS
#   l2node.nodeCreate $eid $node_id
# FUNCTION
#   Procedure l2node.nodeCreate creates a new netgraph node of the appropriate type.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is either lanswitch or hub)
#****
proc l2node.nodeCreate { eid node_id } {
	set nodeType [getNodeType $node_id]

	switch -exact $nodeType {
		lanswitch {
			set ngtype bridge
		}
		hub {
			set ngtype hub
		}
	}

	switch -exact $nodeType {
		lanswitch -
		hub {
			# create an ng node and make it persistent in the same command
			# bridge demands hookname 'linkX'
			set ngcmds "mkpeer $ngtype link1 link1\n"
			set ngcmds "$ngcmds msg .link1 setpersistent\n"
			set ngcmds "$ngcmds name .link1 $node_id\n"
		}
	}

	if { [getNodeVlanFiltering $node_id] } {
		set ngcmds "$ngcmds mkpeer $node_id: vlan link0 unconfig\n"
		set ngcmds "$ngcmds name $node_id:link0 $node_id-vlan\n"
	}

	pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"
}

#****f* freebsd.tcl/l2node.nodeDestroy
# NAME
#   l2node.nodeDestroy -- destroy
# SYNOPSIS
#   l2node.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a l2node (netgraph) node by sending a shutdown
#   message.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node
#****
proc l2node.nodeDestroy { eid node_id } {
	pipesExec "jexec $eid ngctl msg $node_id: shutdown" "hold"
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
	return [lindex [rexec sysctl kern.smp.cpus] 1]
}

#****f* freebsd.tcl/captureExtIfc
# NAME
#   captureExtIfc -- capture external interface
# SYNOPSIS
#   captureExtIfc $eid $node_id $iface_id
# FUNCTION
#   Captures the external interface given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc captureExtIfc { eid node_id iface_id } {
	global execMode gui

	set ifname [getIfcName $node_id $iface_id]
	set vlan [getIfcVlanTag $node_id $iface_id]
	if { $vlan != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
		try {
			rexec ifconfig $ifname.$vlan create
		} on error err {
			set msg "Error: VLAN $vlan on external interface $ifname can't be\
				created.\n($err)"

			if { ! $gui || $execMode == "batch" } {
				puts stderr $msg
			} else {
				after idle { .dialog1.msg configure -wraplength 4i }
				tk_dialog .dialog1 "IMUNES error" $msg \
					info 0 Dismiss
			}

			return -code error
		} on ok {} {
			set ifname $ifname.$vlan
		}
	}

	captureExtIfcByName $eid $ifname $node_id
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
	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		set nodeNs $eid
	} else {
		set nodeNs $eid.$node_id
	}

	pipesExec "ifconfig $ifname vnet $nodeNs" "hold"
	pipesExec "jexec $nodeNs ifconfig $ifname up promisc" "hold"
}

#****f* freebsd.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node_id $iface_id
# FUNCTION
#   Releases the external interface captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface id
#****
proc releaseExtIfc { eid node_id iface_id } {
	set ifname [getIfcName $node_id $iface_id]
	set vlan [getIfcVlanTag $node_id $iface_id]
	if { $vlan != "" && [getIfcVlanDev $node_id $iface_id] != "" } {
		catch { rexec ifconfig $ifname.$vlan -vnet $eid destroy }

		return
	}

	releaseExtIfcByName $eid $ifname $node_id
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
	if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
		set nodeNs $eid
	} else {
		set nodeNs $eid.$node_id
	}

	pipesExec "ifconfig $ifname -vnet $nodeNs" "hold"
	pipesExec "ifconfig $ifname up -promisc" "hold"
}

#****f* freebsd.tcl/enableIPforwarding
# NAME
#   enableIPforwarding -- enable IP forwarding
# SYNOPSIS
#   enableIPforwarding $node_id
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * node_id -- node id
#****
proc enableIPforwarding { node_id } {
	global ipFastForwarding

	set eid [getFromRunning "eid"]

	pipesExec "jexec $eid\.$node_id sysctl net.inet.ip.forwarding=1" "hold"
	if { $ipFastForwarding } {
		pipesExec "jexec $eid\.$node_id sysctl net.inet.ip.fastforwarding=1" "hold"
	}
	pipesExec "jexec $eid\.$node_id sysctl net.inet6.ip6.forwarding=1" "hold"
}

#****f* freebsd.tcl/getExtIfcs
# NAME
#   getExtIfcs -- get external interfaces
# SYNOPSIS
#   getExtIfcs
# FUNCTION
#   Returns the list of all available external interfaces except those defined
#   in the ignore loop.
# RESULT
#   * ifsc - list of interfaces
#****
proc getExtIfcs {} {
	catch { rexec ifconfig -l } ifcs
	foreach ignore "lo* ipfw* tun*" {
		set ifcs [ lsearch -all -inline -not $ifcs $ignore ]
	}

	return "$ifcs"
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

proc configureExternalConnection { eid node_id } {
	set cmds ""
	set ifc [lindex [ifcList $node_id] 0]
	set outifc "$eid-$node_id"

	set ether [getIfcMACaddr $node_id $ifc]
	if { $ether != "" } {
		autoMACaddr $node_id $ifc
		set ether [getIfcMACaddr $node_id $ifc]
	}
	set cmds "ifconfig $outifc link $ether"

	set addrs [getIfcIPv4addrs $node_id $ifc]
	setToRunning "${node_id}|${ifc}_old_ipv4_addrs" $addrs
	foreach ipv4 $addrs {
		set cmds "$cmds\n ifconfig $outifc $ipv4"
	}

	set addrs [getIfcIPv6addrs $node_id $ifc]
	setToRunning "${node_id}|${ifc}_old_ipv6_addrs" $addrs
	foreach ipv6 $addrs {
		set cmds "$cmds\n ifconfig $outifc inet6 $ipv6"
	}

	set cmds "$cmds\n ifconfig $outifc up"

	pipesExec "$cmds" "hold"
}

proc unconfigureExternalConnection { eid node_id } {
	set cmds ""
	set ifc [lindex [ifcList $node_id] 0]
	set outifc "$eid-$node_id"

	set addrs [getFromRunning "${node_id}|${ifc}_old_ipv4_addrs"]
	foreach ipv4 $addrs {
		set cmds "ifconfig $outifc inet $ipv4 -alias"
	}

	set addrs [getFromRunning "${node_id}|${ifc}_old_ipv6_addrs"]
	foreach ipv6 $addrs {
		set cmds "ifconfig $outifc inet $ipv6 -alias"
	}

	pipesExec "$cmds" "hold"
}

proc stopExternalConnection { eid node_id } {
	pipesExec "ifconfig $eid-$node_id down" "hold"
}

proc setupExtNat { eid node_id ifc } {
	set extIfc [getNodeName $node_id]
	set extIp [lindex [getIfcIPv4addrs $node_id $ifc] 0]
	if { $extIp == "" } {
		return
	}
	set prefixLen [lindex [split $extIp "/"] 1]
	set subnet "[ip::prefix $extIp]/$prefixLen"

	set cmds "echo 'map $extIfc $subnet -> 0/32' | ipnat -f -"

	pipesExec "$cmds" "hold"
}

proc unsetupExtNat { eid node_id ifc } {
	set extIfc [getNodeName $node_id]
	set extIp [lindex [getIfcIPv4addrs $node_id $ifc] 0]
	if { $extIp == "" } {
		return
	}
	set prefixLen [lindex [split $extIp "/"] 1]
	set subnet "[ip::prefix $extIp]/$prefixLen"

	set cmds "echo 'map $extIfc $subnet -> 0/32' | ipnat -f - -pr"

	pipesExec "$cmds" "hold"
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

	set cmds "$cmds; sed -i '' '/Disabling MPLS support/d' /terr.log"

	pipesExec "jexec [getFromRunning "eid"].$node_id sh -c '$cmds'" "hold"
}
