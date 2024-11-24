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

    catch { exec mv $node_dir$path $ext_path }
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
    catch { eval [concat "exec jexec " [getFromRunning "eid"].$node_id $cmd] } output

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
	set status [ catch { exec jexec [getFromRunning "eid"].$node_id which $app } err ]
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
    set eid [getFromRunning "eid"]

    if { [checkForExternalApps "startxcmd"] == 0 && \
	[checkForApplications $node_id "wireshark"] == 0 } {

	startXappOnNode $node_id "wireshark -ki $ifc"
    } else {
	exec jexec $eid.$node_id tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
	    wireshark -o "gui.window_title:$ifc@[getNodeName $node_id] ($eid)" -k -i - &
    }
}

#****f* freebsd.tcl/captureOnExtIfc
# NAME
#   captureOnExtIfc -- start wireshark on an interface
# SYNOPSIS
#   captureOnExtIfc $node_id $command
# FUNCTION
#   Start tcpdump or Wireshark on the specified external interface.
# INPUTS
#   * node_id -- node id
#   * command -- tcpdump or wireshark
#****
proc captureOnExtIfc { node_id command } {
    set ifc [lindex [ifcList $node_id] 0]
    if { "$ifc" == "" } {
	return
    }

    set eid [getFromRunning "eid"]
    if { $command == "tcpdump" } {
	exec xterm -name imunes-terminal -T "Capturing $eid-$node_id" -e "tcpdump -ni $eid-$node_id" 2> /dev/null &
    } else {
	exec $command -o "gui.window_title:[getNodeName $node_id] ($eid)" -k -i $eid-$node_id 2> /dev/null &
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
    global debug

    if { [checkForExternalApps "socat"] != 0 } {
	puts "To run X applications on the node, install socat on your host."
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
#   Start tcpdump in xterm on a virtual node on the specified interface.
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
proc existingShells { shells node_id } {
    set cmd "jexec [getFromRunning "eid"].$node_id which $shells"

    set err [catch { eval exec $cmd } res]
    if  { $err } {
	return ""
    }

    return $res
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
    set jail_id "[getFromRunning "eid"].$node_id"

    exec xterm -name imunes-terminal -sb -rightbar \
	-T "IMUNES: [getNodeName $node_id] (console) [lindex [split $cmd /] end]" \
	-e "jexec $jail_id $cmd" &
}

#****f* freebsd.tcl/fetchRunningExperiments
# NAME
#   fetchRunningExperiments -- fetch running experiments
# SYNOPSIS
#   fetchRunningExperiments
# FUNCTION
#   Returns IDs of all running experiments as a list.
# RESULT
#   * exp_list -- experiment id list
#****
proc fetchRunningExperiments {} {
    catch { exec jls -n name | cut -d "=" -f 2 | cut -d "." -f 1 | sort | uniq } exp_list
    set exp_list [split $exp_list "
"]
    return $exp_list
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
    global execMode vroot_unionfs

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
	    if { [file exist $vroot] } {
		return 1
	    } else {
		if { $execMode == "batch" } {
		    puts "The root filesystem for virtual nodes ($vroot) is missing.
    Run 'imunes -p' to create the root filesystem."
		} else {
		    tk_dialog .dialog1 "IMUNES error" \
		    "The root filesystem for virtual nodes ($vroot) is missing.
    Run 'imunes -p' to create the root filesystem." \
		    info 0 Dismiss
		}
		return 0
	    }
	}
    }

    return 1

    catch { exec zfs list -t snapshot | awk {{print $1}} | sed "1 d" } out
    set snapshotList [ split $out {
}]
    foreach node_id $node_list {
	set snapshot [getNodeSnapshot $node_id]
	if { $snapshot == "" } {
	    set snapshot "vroot/vroot@clean"
	}
	if { [llength [lsearch -inline $snapshotList $snapshot]] == 0 } {
	    if { $execMode == "batch" } {
		if { $snapshot == "vroot/vroot@clean" } {
		    puts "The main snapshot for virtual nodes is missing.
Run 'make' or 'make vroot' to create the main ZFS snapshot."
		} else {
		    puts "Error: ZFS snapshot image \"$snapshot\" for node \"$node_id\" is missing."
		}
		return 0
	    } else {
		after idle { .dialog1.msg configure -wraplength 6i }
		if { $snapshot == "vroot/vroot@clean" } {
		    tk_dialog .dialog1 "IMUNES error" \
		    "The main snapshot for virtual nodes is missing.
Run 'make' or 'make vroot' to create the main ZFS snapshot." \
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
    global execMode

    if { [lindex [split [exec uname -r] "-"] 0] >= 9.0 } {
	return
    }

    set timeoutNeeded 0
    if { [catch { exec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT" } err] == 0 } {
	set timeoutNeeded 1
	break
    }

    if { $timeoutNeeded == 0 } {
	return
    }

    set sec 60
    if { $execMode == "batch" } {
        puts "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec). "
        puts "Please don't try killing the process."
    } else {
        set w .timewait
        catch { destroy $w }

        toplevel $w -takefocus 1
        wm transient $w .
        wm title $w "Please wait ..."
        message $w.msg -justify left -aspect 1200 \
         -text "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec).
Please don't try killing the process.
(countdown on status line)"
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
	while { [catch { exec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT" } err] == 0 } {
	    set spin 1
	    after 1000
	    set sec [expr $sec - 1]
	    if { $execMode == "batch" } {
		puts -nonewline "."
		flush stdout
	    } else {
		statline "~ $sec seconds ..."
		$w.p step -1
		update
	    }
	}
    }

    if { $execMode != "batch" } {
        destroy .timewait
    }

    statline ""
}

#****f* freebsd.tcl/execSetIfcQDisc
# NAME
#   execSetIfcQDisc -- in exec mode set interface queuing discipline
# SYNOPSIS
#   execSetIfcQDisc $eid $node_id $iface $qdisc
# FUNCTION
#   Sets the queuing discipline during the simulation.
#   New queuing discipline is defined in qdisc parameter.
#   Queueing discipline can be set to fifo, wfq or drr.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface -- interface name
#   qdisc -- queuing discipline
#****
proc execSetIfcQDisc { eid node_id iface qdisc } {
    set link_id [getIfcLink $node_id $iface]
    lassign [getLinkPeers $link_id] lnode1 lnode2
    set direction [linkDirection $node_id $iface]

    switch -exact $qdisc {
	FIFO { set qdisc fifo }
	WFQ { set qdisc wfq }
	DRR { set qdisc drr }
    }

    if { [getNodeType $lnode1] == "pseudo" } {
	set link_id [getLinkMirror $link_id]
    }

    pipesExec "jexec $eid ngctl msg $link_id: setcfg \"{ $direction={ $qdisc=1 } }\"" "hold"
}

#****f* freebsd.tcl/execSetIfcQDrop
# NAME
#   execSetIfcQDrop -- in exec mode set interface queue drop
# SYNOPSIS
#   execSetIfcQDrop $eid $node_id $iface $qdrop
# FUNCTION
#   Sets the queue dropping policy during the simulation.
#   New queue dropping policy is defined in qdrop parameter.
#   Queue dropping policy can be set to drop-head or drop-tail.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface -- interface name
#   qdrop -- queue dropping policy
#****
proc execSetIfcQDrop { eid node_id iface qdrop } {
    set link_id [getIfcLink $node_id $iface]
    lassign [getLinkPeers $link_id] lnode1 lnode2
    set direction [linkDirection $node_id $iface]

    switch -exact $qdrop {
	drop-head { set qdrop drophead }
	drop-tail { set qdrop droptail }
    }

    if { [getNodeType $lnode1] == "pseudo" } {
	set link_id [getLinkMirror $link_id]
    }

    pipesExec "jexec $eid ngctl msg $link_id: setcfg \"{ $direction={ $qdrop=1 } }\"" "hold"
}

#****f* freebsd.tcl/execSetIfcQLen
# NAME
#   execSetIfcQLen -- in exec mode set interface queue length
# SYNOPSIS
#   execSetIfcQLen $eid $node_id $iface $qlen
# FUNCTION
#   Sets the queue length during the simulation.
#   New queue length is defined in qlen parameter.
# INPUTS
#   eid -- experiment id
#   node_id -- node id
#   iface -- interface name
#   qlen -- new queue's length
#****
proc execSetIfcQLen { eid node_id iface qlen } {
    set link_id [getIfcLink $node_id $iface]
    lassign [getLinkPeers $link_id] lnode1 lnode2
    set direction [linkDirection $node_id $iface]

    if { $qlen == 0 } {
	set qlen -1
    }

    if { [getNodeType $lnode1] == "pseudo" } {
	set link_id [getLinkMirror $link_id]
    }

    pipesExec "jexec $eid ngctl msg $link_id: setcfg \"{ $direction={ $queuelen=$qlen } }\"" "hold"
}

#****f* freebsd.tcl/execSetLinkParams
# NAME
#   execSetLinkParams -- in exec mode set link parameters
# SYNOPSIS
#   execSetLinkParams $eid $link_id
# FUNCTION
#   Sets the link parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link_id -- link id
#****
proc execSetLinkParams { eid link_id } {
    global debug

    set node1_id [lindex [getLinkPeers $link_id] 0]
    set node2_id [lindex [getLinkPeers $link_id] 1]

    if { [getLinkMirror $link_id] != "" } {
	set mirror_link [getLinkMirror $link_id]
	if { [getNodeType $node1_id] == "pseudo" } {
	    set node1_id [lindex [getLinkPeers $mirror_link] 0]
	} else {
	    set node2_id [lindex [getLinkPeers $mirror_link] 0]
	}
    }

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

    pipesCreate
    pipesExec "jexec $eid ngctl msg $link_id: setcfg \
	\"{ bandwidth=$bandwidth delay=$delay \
	upstream={ BER=$ber duplicate=$dup } \
	downstream={ BER=$ber duplicate=$dup }}\""
    pipesClose
}

#****f* freebsd.tcl/execSetLinkJitter
# NAME
#   execSetLinkJitter -- in exec mode set link jitter
# SYNOPSIS
#   execSetLinkJitter $eid $link
# FUNCTION
#   Sets the link jitter parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link -- link id
#****
proc execSetLinkJitter { eid link } {
    set lnode1 [lindex [getLinkPeers $link] 0]
    set lnode2 [lindex [getLinkPeers $link] 1]

    set jitter_up [getLinkJitterUpstream $link]
    set jitter_mode_up [getLinkJitterModeUpstream $link]
    set jitter_hold_up [expr [getLinkJitterHoldUpstream $link] + 0]

    set jitter_down [getLinkJitterDownstream $link]
    set jitter_mode_down [getLinkJitterModeDownstream $link]
    set jitter_hold_down [expr [getLinkJitterHoldDownstream $link] + 0]

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
	set ngcmds "$ngcmds msg $link: setcfg {upstream={jitmode=-1}}\n"
	foreach val $jitter_up {
	    set ngcmds "$ngcmds msg $link: setcfg {upstream={addjitter=[expr round($val*1000)]}}\n"
	}
	set ngcmds "$ngcmds msg $link: setcfg {upstream={jitmode=$jit_mode_up}}\n"
	set ngcmds "$ngcmds msg $link: setcfg {upstream={jithold=[expr round($jitter_hold_up*1000)]}}\n"
    }

    if { $jitter_down != "" } {
	set ngcmds "$ngcmds msg $link: setcfg {downstream={jitmode=-1}}\n"
	foreach val $jitter_down {
	    set ngcmds "$ngcmds msg $link: setcfg {downstream={addjitter=[expr round($val*1000)]}}\n"
	}
	set ngcmds "$ngcmds msg $link: setcfg {downstream={jitmode=$jit_mode_down}}\n"
	set ngcmds "$ngcmds msg $link: setcfg {downstream={jithold=[expr round($jitter_hold_down*1000)]}}\n"
    }

    pipesExec "printf \"$ngcmds\" | ngctl -f -" "hold"
}

#****f* freebsd.tcl/execResetLinkJitter
# NAME
#   execResetLinkJitter -- in exec mode reset link jitter
# SYNOPSIS
#   execResetLinkJitter $eid $link
# FUNCTION
#   Resets the link jitter parameters to defaults during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   * eid -- experiment id
#   * link -- link id
#****
proc execResetLinkJitter { eid link } {
    set lnode1 [lindex [getLinkPeers $link] 0]
    set lnode2 [lindex [getLinkPeers $link] 1]

    exec jexec $eid ngctl msg $link: setcfg \
	"{upstream={jitmode=-1} downstream={jitmode=-1}}"
}

#****f* freebsd.tcl/vimageCleanup
# NAME
#   vimageCleanup -- vimage cleanup
# SYNOPSIS
#   vimageCleanup
# FUNCTION
#   Called in special circumstances only. It cleans all the imunes objects
#   from the kernel (vimages and netgraph nodes).
#****
proc vimageCleanup { eid } {
    global .c
    global execMode
    global vroot_unionfs vroot_linprocfs

    #check whether a jail with eid actually exists
    if { [catch { exec jls -v | grep "$eid *ACTIVE" }] } {
	statline "Experiment with eid $eid doesn't exist."

	return
    }

    if { $execMode != "batch" } {
	set nodeCount [llength [getFromRunning "node_list"]]
	set count [expr {$nodeCount}]
	set w .termWait
	catch { destroy $w }

	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Terminating experiment ..."
	message $w.msg -justify left -aspect 1200 \
	-text "Deleting virtual nodes and links."
	pack $w.msg

	ttk::progressbar $w.p -orient horizontal -length 250 \
	-mode determinate -maximum $count -value $count
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    statline "Terminating experiment with experiment id: $eid."

    set t_start [clock milliseconds]
    if { [catch { exec jexec $eid jls -v | fgrep ACTIVE | cut -c9-32 } res] \
	!= 0 } {
	set res ""
    }
    set vimages [join $res]
    set defindex [lsearch $vimages .]
    set vimages [lreplace $vimages $defindex $defindex]

    if { [lindex [split [exec uname -r] "-"] 0] < 9.0 } {
	# Kill all processes in all vimages
	statline "Terminating processes..."

	set step 0
	set allVimages [ llength $vimages ]
	foreach node_id $vimages {
	    if { $execMode != "batch" } {
		statline "Terminating processes in vimage $node_id"
	    }
	    incr step
	    displayBatchProgress $step $allVimages

	    [getNodeType $node_id].shutdown $eid $node_id
	}

	statline ""
	foreach vimage $vimages {
	    checkHangingTCPs $eid $vimage
	}
    }

    statline "Shutting down netgraph nodes..."

    pipesCreate

    # Detach / destroy / reassign interfaces pipe, eiface, iface, bridge
    set i 0
    catch "exec sh -c {jexec $eid ngctl t | grep eiface | awk '{print \$2}'}" maxi
    set res [catch "exec jexec $eid ngctl l"]
    while { $res } {
	#This should never, ever happen.
	if { $i > $maxi } {
	    statline ""
	#    statline "Couldn't terminate all ngeth interfaces. Skipping..."
	    break
	}
	if { [expr {$i % 240} == 0] } {
	    if { $execMode == "batch" } {
		puts -nonewline "."
		flush stdout
	    }
	    set res [catch "exec jexec $eid ngctl l"]
	}

	# Attempt to kill hubs & bridges
	set ngnode "n$i"
	if { $ngnode ni $vimages } {
	    pipesExec "jexec $eid ngctl shutdown $ngnode" "hold"
	}
	# Attempt to kill ngeth interfaces
	set ngnode "ngeth$i"
	pipesExec "jexec $eid ngctl shutdown $ngnode:" "hold"
	incr i

	pipesExec ""
    }
    pipesClose

    catch "exec jexec $eid ngctl l | tail -n +2 | grep -v socket" output

    set ngnodes [split $output "
"]

    pipesCreate
    set allNgnodes [llength $ngnodes]
    set step 0
    foreach ngline $ngnodes {
	incr step
	if { $execMode != "batch" } {
	    statline "Shutting down netgraph node $ngline"
	}
	displayBatchProgress $step $allNgnodes
	set ngnode [lindex [eval list $ngline] 1]

	pipesExec "jexec $eid ngctl shutdown $ngnode:"
    }
    pipesClose

    statline ""

    # Shut down all vimages
    if { $vroot_unionfs } {
	set VROOT_BASE /var/imunes
    } else {
	set VROOT_BASE /vroot
    }

    statline "Shutting down vimages..."

    set step 0
    set steps [expr {[llength $vimages]} ]

    pipesCreate
    foreach node_id $vimages {
	if { $execMode != "batch" } {
	    statline "Shutting down vimage $node_id"
	    $w.p step -1
	}

	incr step
	displayBatchProgress $step $steps

	pipesExec "jexec $eid.$node_id kill -9 -1 2> /dev/null" "hold"
	pipesExec "jexec $eid.$node_id tcpdrop -a 2> /dev/null" "hold"
	pipesExec "for iface in `jexec $eid.$node_id ifconfig -l`; do jexec $eid.$node_id ifconfig \$iface destroy; done" "hold"

	set VROOT_RUNTIME $VROOT_BASE/$eid/$node_id
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
	pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
	if { $vroot_unionfs } {
	    # 1st: unionfs RW overlay
	    pipesExec "umount -f $VROOT_RUNTIME" "hold"
	    # 2nd: nullfs RO loopback
	    pipesExec "umount -f $VROOT_RUNTIME" "hold"
	}
	if { $vroot_linprocfs } {
	    pipesExec "umount -f $VROOT_RUNTIME/compat/linux/proc" "hold"
	}
	pipesExec ""
    }
    pipesClose

    statline ""

    # remeber all vlan interfaces in the experiment to destroy them later
    set vlanlist ""
    catch { exec jexec $eid ifconfig -l } ifclist
    foreach ifc $ifclist {
	if { [string match "*.*" $ifc] } {
	    lappend vlanlist $ifc
	}
    }

    if { $vroot_unionfs } {
	# UNIONFS
	exec jail -r $eid
	exec rm -fr $VROOT_BASE/$eid &
    } else {
	# ZFS
	if { $execMode == "batch" } {
	    exec jail -r $eid
	    exec zfs destroy -fr vroot/$eid
	} else {
	    exec jail -r $eid &
	    exec zfs destroy -fr vroot/$eid &

	    catch { exec zfs list | grep -c "$eid" } output
	    set zfsCount [lindex [split $output] 0]

	    while { $zfsCount != 0 } {
		catch { exec zfs list | grep -c "$eid/" } output
		set zfsCount [lindex [split $output] 0]
		$w.p configure -value $zfsCount
		update

		after 200
	    }
	}
    }

    foreach ifc $vlanlist {
	catch { exec ifconfig $ifc destroy }
    }

    if { $execMode != "batch" } {
	destroy $w
    }

    statline "Cleanup completed in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."
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
    catch "exec pkill -f \"$regex\""
}

#****f* freebsd.tcl/getRunningNodeIfcList
# NAME
#   getRunningNodeIfcList -- get interfaces list from the node
# SYNOPSIS
#   getRunningNodeIfcList $node_id
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc getRunningNodeIfcList { node_id } {
    catch { exec jexec [getFromRunning "eid"].$node_id ifconfig } full
    set lines [split $full "\n"]

    return $lines
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
    set extifcs [exec ifconfig -l]
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
#   * ifname -- interface name
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node_id ifname } {
    global execMode

    # check if VLAN ID is already taken
    # this can be only done by trying to create it, as it's possible that the same
    # VLAN interface already exists in some other namespace
    set vlan [getEtherVlanTag $node_id]
    try {
	exec ifconfig $ifname.$vlan create
    } on ok {} {
	exec ifconfig $ifname.$vlan destroy
	return 0
    } on error err {
	set msg "Unable to create external interface '$ifname.$vlan':\n$err\n\nPlease\
	    verify that VLAN ID $vlan with parent interface $ifname is not already\
	    assigned to another VLAN interface, potentially in a different jail."
    }

    if { $execMode == "batch" } {
	puts $msg
    } else {
	after idle { .dialog1.msg configure -wraplength 4i }
	tk_dialog .dialog1 "IMUNES error" $msg \
	    info 0 Dismiss
    }

    return 1
}

#****f* freebsd.tcl/getVrootDir
# NAME
#   getVrootDir -- get virtual root directory
# SYNOPSIS
#   getVrootDir
# FUNCTION
#   Helper function that returns virtual root directory.
# RESULT
#   * vroot_dir -- virtual root directory
#****
proc getVrootDir {} {
    global vroot_unionfs

    if { $vroot_unionfs } {
	return "/var/imunes"
    } else {
	return "/vroot"
    }
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
	set VROOTDIR /var/imunes
	set VROOT_RUNTIME $VROOTDIR/$eid/$node_id
	set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node_id
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

	pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
	pipesExec "mkdir -p $VROOT_OVERLAY" "hold"
	pipesExec "mount_nullfs -o ro $VROOTDIR/vroot $VROOT_RUNTIME" "hold"
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
    global debug

    set node_dir [getNodeDir $node_id]

    set jail_cmd "jail -c name=[getFromRunning "eid"].$node_id path=$node_dir securelevel=1 \
	host.hostname=\"[getNodeName $node_id]\" vnet persist"

    if { $debug } {
	puts "Node $node_id -> '$jail_cmd'"
    }

    pipesExec "$jail_cmd" "hold"
}

proc isNodeStarted { node_id } {
    set jail_id "[getFromRunning "eid"].$node_id"

    try {
	exec jls -j $jail_id
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
    global ifc_dad_disable

    set eid [getFromRunning "eid"]
    set jail_id "$eid.$node_id"
    # Create a vimage
    # Create "physical" network interfaces
    foreach iface_id $ifaces {
	set iface_name $iface_id
	switch -exact [string trimright $iface_name 0123456789] {
	    e {
	    }
	    eth {
		# save newly created ngnodeX into a shell variable ifid and
		# rename the ng node to $node_id-$iface_name (unique to this experiment)
		set cmds "
		  ifid=\$(printf \"mkpeer . eiface $node_id-$iface_name ether \n
		  show .:$node_id-$iface_name\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
		set cmds "$cmds; jexec $eid ngctl name \$ifid: $node_id-$iface_name"
		set cmds "$cmds; jexec $eid ifconfig \$ifid name $node_id-$iface_name"

		pipesExec $cmds "hold"
		pipesExec "jexec $eid ifconfig $node_id-$iface_name vnet $node_id" "hold"
		pipesExec "jexec $jail_id ifconfig $node_id-$iface_name name $iface_name" "hold"

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
		# rename the ng node to $node_id-$iface_name (unique to this experiment)
		set cmds "
		  ifid=\$(printf \"mkpeer . eiface $node_id-$iface_name ether \n
		  show .:$node_id-$iface_name\" | jexec $eid ngctl -f - | head -n1 | cut -d' ' -f4)"
		set cmds "$cmds; jexec $eid ngctl name \$ifid: $node_id-$iface_name"
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
		pipesExec "ifconfig $iface_name vnet $jail_id" "hold"
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
	set iface_name $iface_id
	switch -exact [getLogIfcType $node_id $iface_id] {
	    vlan {
		# physical interfaces are created when creating links, so VLANs
		# must be created after links
	    }
	    lo {
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
    set jail_id "[getFromRunning "eid"].$node_id"

    try {
       exec jexec $jail_id rm /tmp/init > /dev/null
    } on error {} {
       return false
    }

    return true
}

#****f* freebsd.tcl/startIfcsNode
# NAME
#   startIfcsNode -- start interfaces on node
# SYNOPSIS
#   startIfcsNode $node_id
# FUNCTION
#  Starts all interfaces on the given node.
# INPUTS
#   * node_id -- node id
#****
proc startIfcsNode { node_id } {
    set jail_id "[getFromRunning "eid"].$node_id"

    foreach {iface_id iface_cfg} [concat [cfgGet "nodes" $node_id "ifaces"] [cfgGet "nodes" $node_id "ifaces"]] {
	set iface_name [dictGet $iface_cfg "name"]
	set mtu [dictGet $iface_cfg "mtu"]

	if { [dictGet $iface_cfg "type"] == "vlan" } {
	    set tag [dictGet $iface_cfg "vlan_tag"]
	    set dev [dictGet $iface_cfg "vlan_dev"]
	    if { $tag != "" && $dev != "" } {
		pipesExec "jexec $jail_id ifconfig $dev.$tag create name $iface_name" "hold"
	    }
	}

	if { [dictGetWithDefault "up" $iface_cfg "oper_state"] == "up" } {
	    pipesExec "jexec $jail_id ifconfig $iface_name mtu $mtu up" "hold"
	} else {
	    pipesExec "jexec $jail_id ifconfig $iface_name mtu $mtu" "hold"
	}

	if { [dictGetWithDefault "on" $iface_cfg "nat_state"] == "on" } {
	    pipesExec "jexec $jail_id sh -c 'echo \"map $iface_name 0/0 -> 0/32\" | ipnat -f -'" "hold"
	}
    }
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
    set jail_id "[getFromRunning "eid"].$node_id"

    if { [getCustomEnabled $node_id] == true } {
	set selected [getCustomConfigSelected $node_id]

	set bootcmd [getCustomConfigCommand $node_id $selected]
	set bootcfg [getCustomConfig $node_id $selected]
	if { [getAutoDefaultRoutesStatus $node_id] == "enabled" } {
	    foreach statrte [getDefaultIPv4routes $node_id] {
		lappend bootcfg [getIPv4RouteCmd $statrte]
	    }
	    foreach statrte [getDefaultIPv6routes $node_id] {
		lappend bootcfg [getIPv6RouteCmd $statrte]
	    }
	}
	set confFile "custom.conf"
    } else {
	set bootcfg [[getNodeType $node_id].generateConfig $node_id]
	set bootcmd [[getNodeType $node_id].bootcmd $node_id]
	set confFile "boot.conf"
    }

    generateHostsFile $node_id

    foreach ifc [allIfcList $node_id] {
	if { [getIfcOperState $node_id $ifc] == "down" } {
	    pipesExec "jexec $jail_id ifconfig $ifc down" "hold"
	}
    }

    set cfg [join $bootcfg "\n"]
    writeDataToNodeFile $node_id /$confFile $cfg
    set cmds "$bootcmd /$confFile >> /tout.log 2>> /terr.log ;"
    # renaming the file signals that we're done
    set cmds "$cmds mv /tout.log /out.log ;"
    set cmds "$cmds mv /terr.log /err.log"
    pipesExec "jexec $jail_id sh -c '$cmds'" "hold"
}

proc isNodeConfigured { node_id } {
    set jail_id "[getFromRunning "eid"].$node_id"

    if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
	return true
    }

    try {
	exec jexec $jail_id test -f /out.log > /dev/null
    } on error {} {
	return false
    }

    return true
}

proc isNodeError { node_id } {
    set jail_id "[getFromRunning "eid"].$node_id"

    if { [[getNodeType $node_id].virtlayer] == "NATIVE" } {
	return false
    }

    try {
	exec jexec $jail_id test -s /err.log > /dev/null
    } on error {} {
	return false
    }

    return true
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
	foreach ipv4 [getIfcIPv4addr $node_id $ifc] {
	    pipesExec "jexec $jail_id ifconfig $ifc $ipv4 -alias" "hold"
	}
	foreach ipv6 [getIfcIPv6addr $node_id $ifc] {
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
    set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
    pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
    if { $vroot_unionfs } {
	# 1st: unionfs RW overlay
	pipesExec "umount -f $VROOT_RUNTIME" "hold"
	# 2nd: nullfs RO loopback
	pipesExec "umount -f $VROOT_RUNTIME" "hold"
	pipesExec "rmdir $VROOT_RUNTIME" "hold"
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

    catch { exec kldload nullfs }
    catch { exec kldload unionfs }

    catch { exec kldload ng_eiface }
    catch { exec kldload ng_pipe }
    catch { exec kldload ng_socket }
    catch { exec kldload if_tun }
    catch { exec kldload vlan }
    catch { exec kldload ipsec }
    catch { exec kldload pf }
#   catch { exec kldload ng_iface }
#   catch { exec kldload ng_cisco }

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
	exec zfs create vroot/[getFromRunning "eid"]
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

    catch { exec devfs rule showsets } devcheck
    if { $force == 1 || $devfs_number ni $devcheck } {
	# Prepare a devfs ruleset for L3 vnodes
	exec devfs ruleset $devfs_number
	exec devfs rule delset
	exec devfs rule add hide
	exec devfs rule add path null unhide
	exec devfs rule add path zero unhide
	exec devfs rule add path random unhide
	exec devfs rule add path urandom unhide
	exec devfs rule add path ipl unhide
	exec devfs rule add path ipnat unhide
	exec devfs rule add path pf unhide
	exec devfs rule add path crypto unhide
	exec devfs rule add path ptyp* unhide
	exec devfs rule add path ptyq* unhide
	exec devfs rule add path ptyr* unhide
	exec devfs rule add path ptys* unhide
	exec devfs rule add path ptyp* unhide
	exec devfs rule add path ptyq* unhide
	exec devfs rule add path ptyr* unhide
	exec devfs rule add path ptys* unhide
	exec devfs rule add path ttyp* unhide
	exec devfs rule add path ttyq* unhide
	exec devfs rule add path ttyr* unhide
	exec devfs rule add path ttys* unhide
	exec devfs rule add path ttyp* unhide
	exec devfs rule add path ttyq* unhide
	exec devfs rule add path ttyr* unhide
	exec devfs rule add path ttys* unhide
	exec devfs rule add path ptmx unhide
	exec devfs rule add path pts unhide
	exec devfs rule add path pts/* unhide
	exec devfs rule add path fd unhide
	exec devfs rule add path fd/* unhide
	exec devfs rule add path stdin unhide
	exec devfs rule add path stdout unhide
	exec devfs rule add path stderr unhide
	exec devfs rule add path mem unhide
	exec devfs rule add path kmem unhide
	exec devfs rule add path bpf* unhide
	exec devfs rule add path tun* unhide
	exec devfs ruleset 0
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
    exec jail -c name=[getFromRunning "eid"] vnet children.max=[llength [getFromRunning "node_list"]] persist
}

#****f* freebsd.tcl/createDirectLinkBetween
# NAME
#   createDirectLinkBetween -- create direct link between
# SYNOPSIS
#   createDirectLinkBetween $node1_id $node2_id $iface1_id $iface2_id
# FUNCTION
#   Creates direct link between two given nodes. Direct link connects the host
#   interface into the node, without ng_node between them.
# INPUTS
#   * node1_id -- node id of the first node
#   * node2_id -- node id of the second node
#   * iface1_id -- interface id on the first node
#   * iface2_id -- interface id on the second node
#****
proc createDirectLinkBetween { node1_id node2_id iface1_id iface2_id } {
    set eid [getFromRunning "eid"]

    set ngpeer1 \
	[lindex [[getNodeType $node1_id].nghook $eid $node1_id $iface1_id] 0]
    set ngpeer2 \
	[lindex [[getNodeType $node2_id].nghook $eid $node2_id $iface2_id] 0]
    set nghook1 \
	[lindex [[getNodeType $node1_id].nghook $eid $node1_id $iface1_id] 1]
    set nghook2 \
	[lindex [[getNodeType $node2_id].nghook $eid $node2_id $iface2_id] 1]

    pipesExec "jexec $eid ngctl connect $ngpeer1: $ngpeer2: $nghook1 $nghook2" "hold"
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
    global linkJitterConfiguration debug

    set eid [getFromRunning "eid"]
    set bandwidth [expr [getLinkBandwidth $link_id] + 0]
    set delay [expr [getLinkDelay $link_id] + 0]
    set ber [expr [getLinkBER $link_id] + 0]
    set loss [expr [getLinkLoss $link_id] + 0]
    set dup [expr [getLinkDup $link_id] + 0]
    # Link parameters
    set ngcmds "msg $link_id: setcfg {bandwidth=$bandwidth delay=$delay upstream={BER=$ber duplicate=$dup} downstream={BER=$ber duplicate=$dup}}"

    pipesExec "printf \"$ngcmds\" | jexec $eid ngctl -f -" "hold"

    # FIXME: remove this to interface configuration?
    # Queues
    foreach node_id "$node1_id $node2_id" ifc "$iface1_id $iface2_id" {
	if { [getNodeType $node1_id] != "rj45" && [getNodeType $node2_id] != "rj45" } {
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

proc destroyDirectLinkBetween { eid node1_id node2_id } {
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
proc destroyLinkBetween { eid node1_id node2_id link_id } {
    pipesExec "jexec $eid ngctl msg $link_id: shutdown" "hold"
}

#****f* freebsd.tcl/destroyNodeIfaces
# NAME
#   destroyNodeIfaces -- destroy virtual node interfaces
# SYNOPSIS
#   destroyNodeIfaces $eid $vimages
# FUNCTION
#   Destroys all virtual node interfaces.
# INPUTS
#   * eid -- experiment id
#   * vimages -- list of virtual nodes
#****
proc destroyNodeIfaces { eid node_id ifcs } {
    if { [getNodeType $node_id] in "ext extnat" } {
	pipesExec "jexec $eid ngctl rmnode $eid-$node_id:" "hold"
	return
    }

    foreach ifc $ifcs {
	pipesExec "jexec $eid ngctl rmnode $node_id-$ifc:" "hold"
    }
}

#****f* freebsd.tcl/removeExperimentContainer
# NAME
#   removeExperimentContainer -- remove experiment container
# SYNOPSIS
#   removeExperimentContainer $eid $widget
# FUNCTION
#   Removes the root jail of the given experiment.
# INPUTS
#   * eid -- experiment id
#   * widget -- status widget
#****
proc removeExperimentContainer { eid widget } {
    # Remove the main vimage which contained all other nodes, hopefully we
    # cleaned everything.
    catch "exec jexec $eid kill -9 -1 2> /dev/null"
    exec jail -r $eid
}

proc removeExperimentFiles { eid widget } {
    global vroot_unionfs execMode

    set VROOT_BASE [getVrootDir]

    # Remove the main vimage which contained all other nodes, hopefully we
    # cleaned everything.
    if { $vroot_unionfs } {
	# UNIONFS
	catch "exec rm -fr $VROOT_BASE/$eid"
    } else {
	# ZFS
	if { $execMode == "batch" } {
	    exec jail -r $eid
	    exec zfs destroy -fr vroot/$eid
	} else {
	    exec jail -r $eid &
	    exec zfs destroy -fr vroot/$eid &

	    catch { exec zfs list | grep -c "$eid" } output
	    set zfsCount [lindex [split $output] 0]

	    while { $zfsCount != 0 } {
		catch { exec zfs list | grep -c "$eid/" } output

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
    switch -exact [getNodeType $node_id] {
	lanswitch {
	    set ngtype bridge
	}
	hub {
	    set ngtype hub
	}
    }

    # create an ng node and make it persistent in the same command
    # bridge demands hookname 'linkX'
    set ngcmds "mkpeer $ngtype link0 link0\n"
    set ngcmds "$ngcmds msg .link0 setpersistent\n"
    set ngcmds "$ngcmds name .link0 $node_id"
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
    return [lindex [exec sysctl kern.smp.cpus] 1]
}

#****f* freebsd.tcl/captureExtIfc
# NAME
#   captureExtIfc -- capture external interface
# SYNOPSIS
#   captureExtIfc $eid $node_id
# FUNCTION
#   Captures the external interface given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc captureExtIfc { eid node_id } {
    global execMode

    set ifname [getNodeName $node_id]
    if { [getEtherVlanEnabled $node_id] } {
	set vlan [getEtherVlanTag $node_id]
	try {
	    exec ifconfig $ifname.$vlan create
	} on error err {
	    set msg "Error: VLAN $vlan on external interface $ifname can't be\
		created.\n($err)"

	    if { $execMode == "batch" } {
		puts $msg
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

    captureExtIfcByName $eid $ifname
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
proc captureExtIfcByName { eid ifname } {
    pipesExec "ifconfig $ifname vnet $eid" "hold"
    pipesExec "jexec $eid ifconfig $ifname up promisc" "hold"
}

#****f* freebsd.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interface
# SYNOPSIS
#   releaseExtIfc $eid $node_id
# FUNCTION
#   Releases the external interface captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc releaseExtIfc { eid node_id } {
    set ifname [getNodeName $node_id]
    if { [getEtherVlanEnabled $node_id] } {
	set vlan [getEtherVlanTag $node_id]
	set ifname $ifname.$vlan
	catch { exec ifconfig $ifname -vnet $eid destroy }

	return
    }

    releaseExtIfcByName $eid $ifname
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
proc releaseExtIfcByName { eid ifname } {
    pipesExec "ifconfig $ifname -vnet $eid" "hold"
    pipesExec "ifconfig $ifname up -promisc" "hold"
}

#****f* freebsd.tcl/enableIPforwarding
# NAME
#   enableIPforwarding -- enable IP forwarding
# SYNOPSIS
#   enableIPforwarding $eid $node_id
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc enableIPforwarding { eid node_id } {
    global ipFastForwarding
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
    catch { exec ifconfig -l } ifcs
    foreach ignore "lo* ipfw* tun*" {
	set ifcs [ lsearch -all -inline -not $ifcs $ignore ]
    }
    return "$ifcs"
}

proc getIPv4IfcCmd { ifc addr primary } {
    if { $primary } {
	return "ifconfig $ifc inet $addr"
    }
    return "ifconfig $ifc inet add $addr"
}

proc getIPv6IfcCmd { ifc addr primary } {
    if { $primary } {
	return "ifconfig $ifc inet6 $addr"
    }
    return "ifconfig $ifc inet6 add $addr"
}

proc getIPv4RouteCmd { statrte } {
    return "route -q add -inet $statrte"
}

proc getIPv6RouteCmd { statrte } {
    return "route -q add -inet6 $statrte"
}

proc checkSysPrerequisites {} {

    # XXX
    # check for all comands that we use:
    # jail, jexec, jls, ngctl
}

proc ipsecFilesToNode { node_id local_cert ipsecret_file } {
    global ipsecConf ipsecSecrets

    if { $local_cert != "" } {
	set trimmed_local_cert [lindex [split $local_cert /] end]
	set fileId [open $trimmed_local_cert "r"]
	set trimmed_local_cert_data [read $fileId]
	writeDataToNodeFile $node_id /usr/local/etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
	close $fileId
    }

    if { $ipsecret_file != "" } {
	set trimmed_local_key [lindex [split $ipsecret_file /] end]
	set fileId [open $trimmed_local_key "r"]
	set trimmed_local_key_data "# /etc/ipsec.secrets - strongSwan IPsec secrets file\n"
	set trimmed_local_key_data "$trimmed_local_key_data[read $fileId]\n"
	set trimmed_local_key_data "$trimmed_local_key_data: RSA $trimmed_local_key"
	writeDataToNodeFile $node_id /usr/local/etc/ipsec.d/private/$trimmed_local_key $trimmed_local_key_data
	close $fileId
    }

    writeDataToNodeFile $node_id /usr/local/etc/ipsec.conf $ipsecConf
    writeDataToNodeFile $node_id /usr/local/etc/ipsec.secrets $ipsecSecrets
}

proc sshServiceStartCmds {} {
    return {"service sshd onestart"}
}

proc sshServiceStopCmds {} {
    return {"service sshd onestop"}
}

proc inetdServiceRestartCmds {} {
    return "service inetd onerestart"
}

# XXX NAT64 procedures
proc createStartTunIfc { eid node_id } {
    # create and start tun interface and return its name
    catch { exec jexec $eid.$node_id ifconfig tun create } tun
    exec jexec $eid.$node_id ifconfig $tun up

    return $tun
}

proc prepareTaygaConf { eid node_id data datadir } {
    exec jexec $eid.$node_id mkdir -p $datadir
    writeDataToNodeFile $node_id "/usr/local/etc/tayga.conf" $data
}

proc taygaShutdown { eid node_id } {
    catch "exec jexec $eid.$node_id killall -9 tayga"
    exec jexec $eid.$node_id rm -rf /var/db/tayga
}

proc taygaDestroy { eid node_id } {
    global nat64ifc_$eid.$node_id
    catch { exec jexec $eid.$node_id ifconfig [set nat64ifc_$eid.$node_id] destroy }
}

proc startExternalConnection { eid node_id } {
    set cmds ""
    set ifc [lindex [ifcList $node_id] 0]
    set outifc "$eid-$node_id"

    set ether [getIfcMACaddr $node_id $ifc]
    if { $ether != "" } {
	autoMACaddr $node_id $ifc
	set ether [getIfcMACaddr $node_id $ifc]
    }
    set cmds "ifconfig $outifc link $ether"

    set ipv4 [getIfcIPv4addr $node_id $ifc]
    if { $ipv4 != "" } {
	set cmds "ifconfig $outifc $ipv4"
    }

    set ipv6 [getIfcIPv6addr $node_id $ifc]
    if { $ipv6 != "" } {
	set cmds "$cmds\n ifconfig $outifc inet6 $ipv6"
    }

    set cmds "$cmds\n ifconfig $outifc up"

    pipesExec "$cmds" "hold"
}

proc stopExternalConnection { eid node_id } {
    pipesExec "ifconfig $eid-$node_id down" "hold"
}

proc setupExtNat { eid node_id ifc } {
    set extIfc [getNodeName $node_id]
    set extIp [getIfcIPv4addrs $node_id $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "echo 'map $extIfc $subnet -> 0/32' | ipnat -f -"

    pipesExec "$cmds" "hold"
}

proc unsetupExtNat { eid node_id ifc } {
    set extIfc [getNodeName $node_id]
    set extIp [getIfcIPv4addrs $node_id $ifc]
    set prefixLen [lindex [split $extIp "/"] 1]
    set subnet "[ip::prefix $extIp]/$prefixLen"

    set cmds "echo 'map $extIfc $subnet -> 0/32' | ipnat -f - -pr"

    pipesExec "$cmds" "hold"
}
