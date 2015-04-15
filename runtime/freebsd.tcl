#****f* exec.tcl/execCmdNode
# NAME
#   execCmdNode -- execute command on virtual node
# SYNOPSIS
#   execCmdNode $node $cmd
# FUNCTION
#   Executes a command on a virtual node and returns the output.
# INPUTS
#   * node -- virtual node id
#   * cmd -- command to execute
# RESULT
#   * returns the execution output
#****
proc execCmdNode { node cmd } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    catch {eval [concat "nexec jexec " $eid.$node $cmd] } output
    return $output
}

#****f* exec.tcl/checkForApplications
# NAME
#   checkForApplications -- check whether applications exist
# SYNOPSIS
#   checkForApplications $node $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the which command.
# INPUTS
#   * node -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the application exists, otherwise it returns 1.
#****
proc checkForApplications { node app_list } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    foreach app $app_list {
	set exists [ catch { exec jexec $eid.$node which $app } err ]
	if { $exists } {
	    return 1
	}
    }
    return 0
}

#****f* exec.tcl/startWiresharkOnNodeIfc
# NAME
#   startWiresharkOnNodeIfc -- start wireshark on an interface
# SYNOPSIS
#   startWiresharkOnNodeIfc $node $ifc
# FUNCTION
#   Start Wireshark on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * ifc -- virtual node interface
#****
proc startWiresharkOnNodeIfc { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    if {[file exists /usr/local/bin/startxcmd] == 1 && \
	[checkForApplications $node "wireshark"] == 0} {
	exec startxcmd [getNodeName $node]@$eid wireshark -ki $ifc > /dev/null 2>\&1 &
    } else {
	exec jexec $eid.$node tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
	    wireshark -o "gui.window_title:$ifc@[getNodeName $node] ($eid)" -k -i - &
    }
}

#****f* exec.tcl/startXappOnNode
# NAME
#   startXappOnNode -- start X application in a virtual node
# SYNOPSIS
#   startXappOnNode $node $app
# FUNCTION
#   Start X application on virtual node
# INPUTS
#   * node -- virtual node id
#   * app -- application to start
#****
proc startXappOnNode { node app } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    eval exec startxcmd [getNodeName $node]@$eid $app > /dev/null 2>&1 &
}

#****f* exec.tcl/startTcpdumpOnNodeIfc
# NAME
#   startTcpdumpOnNodeIfc -- start tcpdump on an interface
# SYNOPSIS
#   startTcpdumpOnNodeIfc $node $ifc
# FUNCTION
#   Start tcpdump in xterm on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * ifc -- virtual node interface
#****
proc startTcpdumpOnNodeIfc { node ifc } {
    if {[checkForApplications $node "tcpdump"] == 0} {
	spawnShell $node "tcpdump -ni $ifc"
    }
}

#****f* exec.tcl/existingShells
# NAME
#   existingShells -- check which shells exist in a node
# SYNOPSIS
#   existingShells $shells $node
# FUNCTION
#   This procedure checks which of the provided shells are available
#   in a running node.
# INPUTS
#   * shells -- list of shells.
#   * node -- node id of the node for which the check is performed.
#****
proc existingShells { shells node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set cmd "jexec $eid.$node which $shells"

    set err [catch {eval exec $cmd} res]
    if  { $err } {
	return ""
    }

    return $res
}

#****f* exec.tcl/spawnShell
# NAME
#   spawnShell -- spawn shell
# SYNOPSIS
#   spawnShell $node $cmd
# FUNCTION
#   This procedure spawns a new shell for a specified node.
#   The shell is specified in cmd parameter.
# INPUTS
#   * node -- node id of the node for which the shell is spawned.
#   * cmd -- the path to the shell.
#****
proc spawnShell { node cmd } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id $eid\.$node

    nexec xterm -sb -rightbar \
	-T "IMUNES: [getNodeName $node] (console) [lindex [split $cmd /] end]" \
	-e "jexec $node_id $cmd" &
}

#****f* exec.tcl/fetchRunningExperiments
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
    catch {exec jls -n name | cut -d "=" -f 2 | cut -d "." -f 1 | sort | uniq} exp_list
    set exp_list [split $exp_list "
"]
    return $exp_list
}

#****f* exec.tcl/createIfc
# NAME
#   createIfc -- create interface
# SYNOPSIS
#   set name [createIfc $eid $type $hook]
# FUNCTION
#   Creates a new netgraph interface, of the type $type.
#   Returns the name of the newly created interface.
# INPUTS
#   * eid -- experiment id
#   * type -- new interface type. In imunes are used only eiface or iface
#     types. Additional specification on this types can be found in manual
#     pages for netgraph nodes.
#   * hook -- parameter specific for every netgraph node. For iface hook hook
#     is inet, and for eiface type the hook is ether.
# RESULT
#   * name -- the name of the new interface
#****
proc createIfc { eid type hook } {
    catch { exec printf "mkpeer $type $hook $hook \n show .$hook" | jexec $eid ngctl -f - } nglist
    return [lindex $nglist 1]
}

#****f* exec.tcl/allSnapshotsAvailable
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
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    set vroot "/var/imunes/vroot"

    if {$vroot_unionfs} {
	if { [file exist $vroot] } {
	    return 1
	} else {
	    if {$execMode == "batch"} {
		puts "The root filesystem for virtual nodes ($vroot) is missing.
Run 'make' or 'make vroot' to create the root filesystem."
	    } else {
		tk_dialog .dialog1 "IMUNES error" \
		"The root filesystem for virtual nodes ($vroot) is missing.
Run 'make' or 'make vroot' to create the root filesystem." \
		info 0 Dismiss
	    }
	    return 0
	}
    }

    catch { exec zfs list -t snapshot | awk {{print $1}} | sed "1 d" } out
    set snapshotList [ split $out {
}]
    foreach node $node_list {
	set snapshot [getNodeSnapshot $node]
	if { $snapshot == "" } {
	    set snapshot "vroot/vroot@clean"
	}
	if { [llength [lsearch -inline $snapshotList $snapshot]] == 0} {
	    if {$execMode == "batch"} {
		if { $snapshot == "vroot/vroot@clean" } {
		    puts "The main snapshot for virtual nodes is missing.
Run 'make' or 'make vroot' to create the main ZFS snapshot."
		} else {
		    puts "Error: ZFS snapshot image \"$snapshot\" for node \"$node\" is missing."
		}
		return 0
	    } else {
		after idle {.dialog1.msg configure -wraplength 6i}
		if { $snapshot == "vroot/vroot@clean" } {
		    tk_dialog .dialog1 "IMUNES error" \
		    "The main snapshot for virtual nodes is missing.
Run 'make' or 'make vroot' to create the main ZFS snapshot." \
		    info 0 Dismiss
		    return 0
		} else {
		    tk_dialog .dialog1 "IMUNES error" \
		    "Error: ZFS snapshot image \"$snapshot\" for node \"$node\" is missing." \
		    info 0 Dismiss
		    return 0
		}
	    }
	}
    }
    return 1
}

#****f* exec.tcl/timeoutPatch
# NAME
#   timeoutPatch -- timeout patch
# SYNOPSIS
#   timeoutPatch $eid $vimages
# FUNCTION
#   Timeout patch that is applied for hanging TCP connections. We need to wait
#   for TCP connections to close regularly because we can't terminate them in
#   FreeBSD 8. In FreeBSD that should be possible with the tcpdrop command.
# INPUTS
#   * eid -- experiment ID
#   * vimages -- list of current vimages
#****
proc timeoutPatch { eid vimages } {
    global execMode
    set vrti 1
    set sec 60

    if { [lindex [split [exec uname -r] "-"] 0] >= 9.0 } {
	return
    }

    set timeoutNeeded 0
    foreach vimage $vimages {
	if { [catch {exec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT"} odg] == 0} {
	    set timeoutNeeded 1
	    break
	}
    }

    if { $timeoutNeeded == 0 } {
	return
    }

    if { $execMode == "batch" } {
        puts "We must wait for TIME_WAIT expiration on virtual nodes (up to 60 sec). "
        puts "Please don't try killing the process."
    } else {
        set w .timewait
        catch {destroy $w}
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

    while { $vrti == 1 } {
        set vrti 0
        foreach vimage $vimages {
            # puts "vimage $vimage...\n"
            while { [catch {exec jexec $eid.$vimage netstat -an -f inet | fgrep "WAIT"} odg] == 0} {
                set vrti 1
                # puts "vimage $vimage: \n$odg\n"
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
    }
    if { $execMode != "batch" } {
        destroy .timewait
    }
    statline ""
}

#****f* exec.tcl/execSetIfcQDisc
# NAME
#   execSetIfcQDisc -- in exec mode set interface queuing discipline
# SYNOPSIS
#   execSetIfcQDisc $eid $node $ifc $qdisc
# FUNCTION
#   Sets the queuing discipline during the simulation.
#   New queuing discipline is defined in qdisc parameter.
#   Queueing discipline can be set to fifo, wfq or drr.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qdisc -- queuing discipline
#****
proc execSetIfcQDisc { eid node ifc qdisc } {
    set target [linkByIfc $node $ifc]
    set peers [linkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [nodeType $lnode2] == "pseudo" } {
	set mirror_link [getLinkMirror [lindex $target 0]]
	set lnode2 [lindex [linkPeers $mirror_link] 0]
    }
    switch -exact $qdisc {
	FIFO { set qdisc fifo }
	WFQ { set qdisc wfq }
	DRR { set qdisc drr }
    }
    set ngnode "$lnode1-$lnode2"
    if { [catch { exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdisc=1 } }" }] } {
	set ngnode "$lnode2-$lnode1"
	exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdisc=1 } }"
    }
}

#****f* exec.tcl/execSetIfcQDrop
# NAME
#   execSetIfcQDrop -- in exec mode set interface queue drop
# SYNOPSIS
#   execSetIfcQDrop $eid $node $ifc $qdrop
# FUNCTION
#   Sets the queue dropping policy during the simulation.
#   New queue dropping policy is defined in qdrop parameter.
#   Queue dropping policy can be set to drop-head or drop-tail.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qdrop -- queue dropping policy
#****
proc execSetIfcQDrop { eid node ifc qdrop } {
    set target [linkByIfc $node $ifc]
    set peers [linkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [nodeType $lnode2] == "pseudo" } {
	set mirror_link [getLinkMirror [lindex $target 0]]
	set lnode2 [lindex [linkPeers $mirror_link] 0]
    }
    switch -exact $qdrop {
	drop-head { set qdrop drophead }
	drop-tail { set qdrop droptail }
    }
    set ngnode "$lnode1-$lnode2"
    if { [catch { exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdrop=1 } }" }] } {
	# XXX dir should be reversed!
	set ngnode "$lnode2-$lnode1"
	exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ $qdrop=1 } }"
    }
}

#****f* exec.tcl/execSetIfcQLen
# NAME
#   execSetIfcQLen -- in exec mode set interface queue length
# SYNOPSIS
#   execSetIfcQDrop $eid $node $ifc $qlen
# FUNCTION
#   Sets the queue length during the simulation.
#   New queue length is defined in qlen parameter.
# INPUTS
#   eid -- experiment id
#   node -- node id
#   ifc -- interface name
#   qlen -- new queue's length
#****
proc execSetIfcQLen { eid node ifc qlen } {
    set target [linkByIfc $node $ifc]
    set peers [linkPeers [lindex $target 0]]
    set dir [lindex $target 1]
    set lnode1 [lindex $peers 0]
    set lnode2 [lindex $peers 1]
    if { [nodeType $lnode2] == "pseudo" } {
	set mirror_link [getLinkMirror [lindex $target 0]]
	set lnode2 [lindex [linkPeers $mirror_link] 0]
    }
    set ngnode "$lnode1-$lnode2"
    if { $qlen == 0 } {
	set qlen -1
    }
    if { [catch { exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ queuelen=$qlen } }" }] } {
	set ngnode "$lnode2-$lnode1"
	exec jexec $eid ngctl msg $ngnode: setcfg "{ $dir={ queuelen=$qlen } }"
    }
}

#****f* exec.tcl/execSetLinkParams
# NAME
#   execSetLinkParams -- in exec mode set link parameters
# SYNOPSIS
#   execSetLinkParams $eid $link
# FUNCTION
#   Sets the link parameters during the simulation.
#   All the parameters are set at the same time.
# INPUTS
#   eid -- experiment id
#   link -- link id
#****
proc execSetLinkParams { eid link } {
    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set lname $lnode1-$lnode2

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set dup [expr [getLinkDup $link] + 0]

    if { $bandwidth == 0 } {
	set bandwidth -1
    }
    if { $delay == 0 } {
	set delay -1
    }
    if { $ber == 0 } {
	set ber -1
    }
    if { $dup == 0 } {
	set dup -1
    }

    exec jexec $eid ngctl msg $lname: setcfg \
	"{ bandwidth=$bandwidth delay=$delay \
	upstream={ BER=$ber duplicate=$dup } \
	downstream={ BER=$ber duplicate=$dup } }"
}

#****f* exec.tcl/execSetLinkJitter
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
    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set lname $lnode1-$lnode2

    set jitter_up [getLinkJitterUpstream $link]
    set jitter_mode_up [getLinkJitterModeUpstream $link]
    set jitter_hold_up [expr [getLinkJitterHoldUpstream $link] + 0]

    set jitter_down [getLinkJitterDownstream $link]
    set jitter_mode_down [getLinkJitterModeDownstream $link]
    set jitter_hold_down [expr [getLinkJitterHoldDownstream $link] + 0]

    if {$jitter_mode_up in {"sequential" ""}} {
	set jit_mode_up 1
    } else {
	set jit_mode_up 2
    }

    if {$jitter_mode_down in {"sequential" ""}} {
	set jit_mode_down 1
    } else {
	set jit_mode_down 2
    }

    set exec_pipe [open "| jexec $eid ngctl -f -" r+]

    if {$jitter_up != ""} {
	puts $exec_pipe "msg $lname: setcfg {upstream={jitmode=-1}}"
	foreach val $jitter_up {
	    puts $exec_pipe "msg $lname: setcfg {upstream={addjitter=[expr round($val*1000)]}}"
	}
	puts $exec_pipe "msg $lname: setcfg {upstream={jitmode=$jit_mode_up}}"
	puts $exec_pipe "msg $lname: setcfg {upstream={jithold=[expr round($jitter_hold_up*1000)]}}"
    }

    if {$jitter_down != ""} {
	puts $exec_pipe "msg $lname: setcfg {downstream={jitmode=-1}}"
	foreach val $jitter_down {
	    puts $exec_pipe "msg $lname: setcfg {downstream={addjitter=[expr round($val*1000)]}}"
	}
	puts $exec_pipe "msg $lname: setcfg {downstream={jitmode=$jit_mode_down}}"
	puts $exec_pipe "msg $lname: setcfg {downstream={jithold=[expr round($jitter_hold_down*1000)]}}"
    }

    close $exec_pipe
}

#****f* exec.tcl/execResetLinkJitter
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
    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set lname $lnode1-$lnode2

    exec jexec $eid ngctl msg $lname: setcfg \
	"{upstream={jitmode=-1} downstream={jitmode=-1}}"
}

#****f* exec.tcl/l3node.nghook
# NAME
#   l3node.nghook -- layer 3 node netgraph hook
# SYNOPSIS
#   l3node.nghook $eid $node $ifc
# FUNCTION
#   Returns the netgraph node name and the hook name for a given experiment
#   id, node id, and interface name.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc l3node.nghook { eid node ifc } {
    set ifnum [string range $ifc 3 end]
    set node_id "$eid\.$node"
    switch -exact [string range $ifc 0 2] {
	eth {
	    return [list $ifc@$node_id ether]
	}
	ser {
	    return [list hdlc$ifnum@$node_id downstream]
	}
    }
}

# XXX - comment procedure
proc prepareDevfs {} {
    global devfs_number

    catch {exec devfs rule showsets} devcheck
    if { $devfs_number ni $devcheck } {
	# Prepare a devfs ruleset for L3 vnodes
	exec devfs ruleset $devfs_number
	exec devfs rule delset
	exec devfs rule add hide
	exec devfs rule add path null unhide
	exec devfs rule add path zero unhide
	exec devfs rule add path random unhide
	exec devfs rule add path urandom unhide
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


