#****f* freebsd.tcl/moveFileFromNode
# NAME
#   moveFileFromNode -- copy file from virtual node
# SYNOPSIS
#   moveFileFromNode $node $path $ext_path
# FUNCTION
#   Moves file from virtual node to a specified external path.
# INPUTS
#   * node -- virtual node id
#   * path -- path to file in node
#   * ext_path -- external path
#****
proc moveFileFromNode { node path ext_path } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_dir [getVrootDir]/$eid/$node
    catch {exec mv $node_dir$path $ext_path}
}

#****f* freebsd.tcl/writeDataToNodeFile
# NAME
#   writeDataToNodeFile -- write data to virtual node
# SYNOPSIS
#   writeDataToNodeFile $node $path $data
# FUNCTION
#   Writes data to a file on the specified virtual node.
# INPUTS
#   * node -- virtual node id
#   * path -- path to file in node
#   * data -- data to write
#****
proc writeDataToNodeFile { node path data } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    set node_dir [getVrootDir]/$eid/$node
    writeDataToFile $node_dir/$path $data
}

#****f* freebsd.tcl/execCmdNode
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
    upvar 0 ::cf::[set ::curcfg]::eid eid
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
#   checkForApplications $node $app_list
# FUNCTION
#   Checks whether a list of applications exist on the virtual node by using
#   the which command.
# INPUTS
#   * node -- virtual node id
#   * app_list -- list of applications
# RESULT
#   * returns 0 if the applications exist, otherwise it returns 1.
#****
proc checkForApplications { node app_list } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    foreach app $app_list {
	set status [ catch { exec jexec $eid.$node which $app } err ]
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
#   startWiresharkOnNodeIfc $node $ifc
# FUNCTION
#   Start Wireshark on a virtual node on the specified interface.
# INPUTS
#   * node -- virtual node id
#   * ifc -- virtual node interface
#****
proc startWiresharkOnNodeIfc { node ifc } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    if {[checkForExternalApps "startxcmd"] == 0 && \
	[checkForApplications $node "wireshark"] == 0} {
	startXappOnNode $node "wireshark -ki $ifc"
    } else {
	exec jexec $eid.$node tcpdump -s 0 -U -w - -i $ifc 2>/dev/null |\
	    wireshark -o "gui.window_title:$ifc@[getNodeName $node] ($eid)" -k -i - &
    }
}

#****f* freebsd.tcl/captureOnExtIfc
# NAME
#   captureOnExtIfc -- start wireshark on an interface
# SYNOPSIS
#   captureOnExtIfc $node $command
# FUNCTION
#   Start tcpdump or Wireshark on the specified external interface.
# INPUTS
#   * node -- node id
#   * command -- tcpdump or wireshark
#****
proc captureOnExtIfc { node command } {
    set ifc [lindex [ifcList $node] 0]
    if { "$ifc" == "" } {
	return
    }

    upvar 0 ::cf::[set ::curcfg]::eid eid

    if { $command == "tcpdump" } {
	exec xterm -T "Capturing $eid-$node" -e "tcpdump -ni $eid-$node" 2> /dev/null &
    } else {
	exec $command -o "gui.window_title:[getNodeName $node] ($eid)" -k -i $eid-$node 2> /dev/null &
    }
}
#****f* freebsd.tcl/startXappOnNode
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
    global debug
    if {[checkForExternalApps "socat"] != 0 } {
	puts "To run X applications on the node, install socat on your host."
	return
    }

    set logfile "/dev/null"
    if {$debug} {
	set logfile "/tmp/startxcmd_$eid\_$node.log"
    }

    eval exec startxcmd [getNodeName $node]@$eid $app > $logfile 2>> $logfile &
}

#****f* freebsd.tcl/startTcpdumpOnNodeIfc
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

#****f* freebsd.tcl/existingShells
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

#****f* freebsd.tcl/spawnShell
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
    catch {exec jls -n name | cut -d "=" -f 2 | cut -d "." -f 1 | sort | uniq} exp_list
    set exp_list [split $exp_list "
"]
    return $exp_list
}

#****f* freebsd.tcl/createIfc
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
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    set vroot "/var/imunes/vroot"

    if {$vroot_unionfs} {
	if { [file exist $vroot] } {
	    return 1
	} else {
	    if {$execMode == "batch"} {
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

#****f* freebsd.tcl/timeoutPatch
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

#****f* freebsd.tcl/execSetIfcQDisc
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

#****f* freebsd.tcl/execSetIfcQDrop
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

#****f* freebsd.tcl/execSetIfcQLen
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

#****f* freebsd.tcl/execSetLinkParams
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
    global debug

    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]

    if { [getLinkMirror $link] != "" } {
	set mirror_link [getLinkMirror $link]
	if { [nodeType $lnode1] == "pseudo" } {
	    set lnode1 [lindex [linkPeers $mirror_link] 0]
	} else {
	    set lnode2 [lindex [linkPeers $mirror_link] 0]
	}
    }

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

    catch {exec jexec $eid ngctl msg $lname: setcfg \
	"{ bandwidth=$bandwidth delay=$delay \
	upstream={ BER=$ber duplicate=$dup } \
	downstream={ BER=$ber duplicate=$dup } }"} err
    if { $debug && $err != "" } {
	puts $err
    }
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
    set lnode1 [lindex [linkPeers $link] 0]
    set lnode2 [lindex [linkPeers $link] 1]
    set lname $lnode1-$lnode2

    exec jexec $eid ngctl msg $lname: setcfg \
	"{upstream={jitmode=-1} downstream={jitmode=-1}}"
}

#****f* freebsd.tcl/l3node.nghook
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
    switch -exact [string trim $ifc 0123456789] {
	wlan -
	ext -
	eth {
	    return [list $ifc@$node_id ether]
	}
	ser {
	    return [list hdlc$ifnum@$node_id downstream]
	}
    }
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
    if {[catch {exec jls -v | grep "$eid *ACTIVE"}]} {
	statline "Experiment with eid $eid doesn't exist."
	return
    }

    if {$execMode != "batch"} {
	upvar 0 ::cf::[set ::curcfg]::node_list node_list
	set nodeCount [llength $node_list]
	set count [expr {$nodeCount}]
	set w .termWait
	catch {destroy $w}
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
    if {[catch {exec jexec $eid jls -v | fgrep ACTIVE | cut -c9-32} res] \
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
	foreach node $vimages {
	    if {$execMode != "batch"} {
		statline "Terminating processes in vimage $node"
	    }
	    incr step
	    displayBatchProgress $step $allVimages

	    [typemodel $node].shutdown $eid $node
	}

	statline ""
	timeoutPatch $eid $vimages
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
	if {[expr {$i%240} == 0]} {
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
    if {$vroot_unionfs} {
	set VROOT_BASE /var/imunes
    } else {
	set VROOT_BASE /vroot
    }

    statline "Shutting down vimages..."

    set step 0
    set steps [expr {[llength $vimages]} ]

    pipesCreate
    foreach node $vimages {
	if {$execMode != "batch"} {
	    statline "Shutting down vimage $node"
	    $w.p step -1
	}

	incr step
	displayBatchProgress $step $steps

	pipesExec "jexec $eid.$node kill -9 -1 2> /dev/null" "hold"
	pipesExec "jexec $eid.$node tcpdrop -a 2> /dev/null" "hold"
	pipesExec "for iface in `jexec $eid.$node ifconfig -l`; do jexec $eid.$node ifconfig \$iface destroy; done" "hold"

	set VROOT_RUNTIME $VROOT_BASE/$eid/$node
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
	pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
	if {$vroot_unionfs} {
	    # 1st: unionfs RW overlay
	    pipesExec "umount -f $VROOT_RUNTIME" "hold"
	    # 2nd: nullfs RO loopback
	    pipesExec "umount -f $VROOT_RUNTIME" "hold"
	}
	if {$vroot_linprocfs} {
	    pipesExec "umount -f $VROOT_RUNTIME/compat/linux/proc" "hold"
	}
	pipesExec ""
    }
    pipesClose

    statline ""

    # remeber all vlan interfaces in the experiment to destroy them later
    set vlanlist ""
    catch {exec jexec $eid ifconfig -l} ifclist
    foreach ifc $ifclist {
	if { [string match "*.*" $ifc]} {
	    lappend vlanlist $ifc
	}
    }

    if {$vroot_unionfs} {
	# UNIONFS
	exec jail -r $eid
	exec rm -fr $VROOT_BASE/$eid &
    } else {
	# ZFS
	if {$execMode == "batch"} {
	    exec jail -r $eid
	    exec zfs destroy -fr vroot/$eid
	} else {
	    exec jail -r $eid &
	    exec zfs destroy -fr vroot/$eid &

	    catch {exec zfs list | grep -c "$eid"} output
	    set zfsCount [lindex [split $output] 0]

	    while {$zfsCount != 0} {
		catch {exec zfs list | grep -c "$eid/"} output
		set zfsCount [lindex [split $output] 0]
		$w.p configure -value $zfsCount
		update
		after 200
	    }
	}
    }

    foreach ifc $vlanlist {
	catch {exec ifconfig $ifc destroy}
    }

    if {$execMode != "batch"} {
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
#   getRunningNodeIfcList $node
# FUNCTION
#   Returns the list of all network interfaces for the given node.
# INPUTS
#   * node -- node id
# RESULT
#   * list -- list in the form of {netgraph_node_name hook}
#****
proc getRunningNodeIfcList { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    catch {exec jexec $eid.$node ifconfig} full
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
#   getHostIfcVlanExists $node $name
# FUNCTION
#   Returns 1 if VLAN interface with the name $name for the given node cannot
#   be created.
# INPUTS
#   * node -- node id
#   * name -- interface name
# RESULT
#   * check -- 1 if interface exists, 0 otherwise
#****
proc getHostIfcVlanExists { node name } {
    global execMode

    # check if the VLAN is available
    set ifname [getNodeName $node]
    set vlan [lindex [split [getNodeName $node] .] 1]
    # if the VLAN is available then it can be created
    if { [catch {exec ifconfig $ifname create} err] } {
	set msg "Error: external interface $name can't be\
	    created.\nVLAN $vlan is already in use. \n($err)"
	if { $execMode == "batch" } {
	    puts $msg
	} else {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" $msg \
		info 0 Dismiss
	}
	return 1
    } else {
	# destroy it, if it was created
	catch {exec ifconfig $ifname destroy}
	return 0
    }
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

    if {$vroot_unionfs} {
	return "/var/imunes"
    } else {
	return "/vroot"
    }
}

#****f* freebsd.tcl/dumpNgnodesToFile
# NAME
#   dumpNgnodesToFile -- dump ngnodemap list to file
# SYNOPSIS
#   dumpNgnodesToFile $path
# FUNCTION
#   Saves the list of all the ngnodes to $path.
# INPUTS
#   * path -- absolute path of the file
#****
proc dumpNgnodesToFile { path } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    writeDataToFile $path [array get ngnodemap]
}

#****f* freebsd.tcl/readNgnodesFromFile
# NAME
#   readNgnodesFromFile -- read ngnodes list from file
# SYNOPSIS
#   readNgnodesFromFile $eid
# FUNCTION
#   Sets the global array ngnodemap to the content of the running config file
#   for the given eid.
# INPUTS
#   * exp -- experiment id
#****
proc readNgnodesFromFile { exp } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap
    global runtimeDir

#    set fileId [open  r]
#    array set ngnodemap [gets $fileId]
#    close $fileId
    array set ngnodemap [readDataFromFile $runtimeDir/$exp/ngnodemap]
}

#****f* freebsd.tcl/prepareFilesystemForNode
# NAME
#   prepareFilesystemForNode -- prepare node filesystem
# SYNOPSIS
#   prepareFilesystemForNode $node
# FUNCTION
#   Prepares the node virtual filesystem.
# INPUTS
#   * node -- node id
#****
proc prepareFilesystemForNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global vroot_unionfs vroot_linprocfs devfs_number

    # Prepare a copy-on-write filesystem root
    if {$vroot_unionfs} {
	# UNIONFS
	set VROOTDIR /var/imunes
	set VROOT_RUNTIME $VROOTDIR/$eid/$node
	set VROOT_OVERLAY $VROOTDIR/$eid/upper/$node
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
	pipesExec "mkdir -p $VROOT_RUNTIME" "hold"
	pipesExec "mkdir -p $VROOT_OVERLAY" "hold"
	pipesExec "mount_nullfs -o ro $VROOTDIR/vroot $VROOT_RUNTIME" "hold"
	pipesExec "mount_unionfs -o noatime $VROOT_OVERLAY $VROOT_RUNTIME" "hold"
    } else {
	# ZFS
	set VROOT_ZFS vroot/$eid/$node
	set VROOT_RUNTIME /$VROOT_ZFS
	set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev

	set snapshot [getNodeSnapshot $node]
	if {$snapshot == ""} {
	    set snapshot "vroot/vroot@clean"
	}
	pipesExec "zfs clone $snapshot $VROOT_ZFS" "hold"
    }

    if {$vroot_linprocfs} {
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
#   createNodeContainer $node
# FUNCTION
#   Creates a jail (container) for the given node.
# INPUTS
#   * node -- node id
#****
proc createNodeContainer { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_dir [getVrootDir]/$eid/$node

    pipesExec "jail -c name=$eid.$node path=$node_dir securelevel=1 \
	host.hostname=\"[getNodeName $node]\" vnet persist" "hold"
}

proc createNodeContainerN { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_dir [getVrootDir]/$eid/$node

    pipesExec "jail -c name=$eid.$node path=$node_dir securelevel=1 \
	host.hostname=\"[getNodeName $node]\" vnet persist" "hold"
}

#****f* freebsd.tcl/createNodePhysIfcs
# NAME
#   createNodePhysIfcs -- create node physical interfaces
# SYNOPSIS
#   createNodePhysIfcs $node
# FUNCTION
#   Creates physical interfaces for the given node.
# INPUTS
#   * node -- node id
#****
proc createNodePhysIfcs { node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global ifc_dad_disable

    set node_id "$eid.$node"
    # Create a vimage
    # Create "physical" network interfaces
    foreach ifc [ifcList $node] {
	switch -exact [string range $ifc 0 2] {
	    eth {
		set ifid [createIfc $eid eiface ether]
		pipesExec "jexec $eid ifconfig $ifid vnet $node" "hold"
		pipesExec "jexec $node_id ifconfig $ifid name $ifc" "hold"

		# XXX ng renaming is automatic in FBSD 8.4 and 9.2, remove this!
		pipesExec "jexec $node_id ngctl name [set ifid]: $ifc" "hold"

#		set peer [peerByIfc $node $ifc]
		set ether [getIfcMACaddr $node $ifc]
                if {$ether == ""} {
                    autoMACaddr $node $ifc
                }
                set ether [getIfcMACaddr $node $ifc]
		global ifc_dad_disable
		if {$ifc_dad_disable} {
		    pipesExec "jexec $node_id sysctl net.inet6.ip6.dad_count=0" "hold"
		}
		pipesExec "jexec $node_id ifconfig $ifc link $ether" "hold"
		set ngnodemap($ifc@$node_id) $ifid
	    }
	    ext {
		set ifid [createIfc $eid eiface ether]
		set outifc "$eid-$node"
		pipesExec "ifconfig $ifid -vnet $eid" "hold"
		pipesExec "ifconfig $ifid name $outifc" "hold"

		# XXX ng renaming is automatic in FBSD 8.4 and 9.2, remove this!
		pipesExec "ngctl name [set ifid]: $outifc" "hold"

		set ether [getIfcMACaddr $node $ifc]
                if {$ether == ""} {
                    autoMACaddr $node $ifc
                }
                set ether [getIfcMACaddr $node $ifc]
		pipesExec "ifconfig $outifc link $ether" "hold"
		set ngnodemap($ifc@$node_id) $ifid
	    }
	    ser {
#		set ifnum [string range $ifc 3 end]
#		set ifid [createIfc $eid iface inet]
#		pipesExec "jexec $eid ngctl mkpeer $ifid: cisco inet inet" "hold"
#		pipesExec "jexec $eid ngctl connect $ifid: $ifid:inet inet6 inet6" "hold"
#		pipesExec "jexec $eid ngctl msg $ifid: broadcast" "hold"
#		pipesExec "jexec $eid ngctl name $ifid:inet hdlc$ifnum\@$node" "hold"
#		pipesExec "jexec $eid ifconfig $ifid vnet $node" "hold"
#		pipesExec "jexec $node_id ifconfig $ifid name $ifc" "hold"
#		set ngnodemap(hdlc$ifnum@$node_id) hdlc$ifnum\@$node"
	    }
	}
    }
}

#****f* freebsd.tcl/createNodeLogIfcs
# NAME
#   createNodeLogIfcs -- create node logical interfaces
# SYNOPSIS
#   createNodeLogIfcs $node
# FUNCTION
#   Creates logical interfaces for the given node.
# INPUTS
#   * node -- node id
#****
proc createNodeLogIfcs { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"

    foreach ifc [logIfcList $node] {
	switch -exact [getLogIfcType $node $ifc] {
	    vlan {
		set tag [getIfcVlanTag $node $ifc]
		set dev [getIfcVlanDev $node $ifc]
		if {$tag != "" && $dev != ""} {
		    pipesExec "jexec $node_id ifconfig $ifc create" "hold"
		    pipesExec "jexec $node_id ifconfig $ifc vlan $tag vlandev $dev" "hold"
		}
	    }
	    lo {
		if {$ifc != "lo0"} {
		    pipesExec "jexec $node_id ifconfig $ifc create" "hold"
		}
	    }
	}
    }
}

#****f* freebsd.tcl/configureICMPoptions
# NAME
#   configureICMPoptions -- configure ICMP options
# SYNOPSIS
#   configureICMPoptions $node
# FUNCTION
#  Configures the necessary ICMP sysctls in the given node. 
# INPUTS
#   * node -- node id
#****
proc configureICMPoptions { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"

    pipesExec "jexec $node_id sysctl net.inet.icmp.bmcastecho=1" "hold"
    pipesExec "jexec $node_id sysctl net.inet.icmp.icmplim=0" "hold"

    # Enable more fragments per packet for IPv4
    pipesExec "jexec $node_id sysctl net.inet.ip.maxfragsperpacket=64000" "hold"
}

#****f* freebsd.tcl/startIfcsNode
# NAME
#   startIfcsNode -- start interfaces on node
# SYNOPSIS
#   startIfcsNode $node
# FUNCTION
#  Starts all interfaces on the given node.
# INPUTS
#   * node -- node id
#****
proc startIfcsNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node_id "$eid.$node"
    set cmds ""
    foreach ifc [allIfcList $node] {
	set mtu [getIfcMTU $node $ifc]
	if {[getIfcOperState $node $ifc] == "up"} {
	    set cmds "$cmds\n jexec $node_id ifconfig $ifc mtu $mtu up"
	} else {
	    set cmds "$cmds\n jexec $node_id ifconfig $ifc mtu $mtu"
	}
    }
    exec sh << $cmds
}

#****f* freebsd.tcl/runConfOnNode
# NAME
#   runConfOnNode -- run configuration script on node
# SYNOPSIS
#   runConfOnNode $node
# FUNCTION
#   Run startup configuration file on the given node.
# INPUTS
#   * node -- node id
#****
proc runConfOnNode { node } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global vroot_unionfs
    global viewcustomid vroot_unionfs
    global execMode

    set node_dir [getVrootDir]/$eid/$node
    set node_id "$eid.$node"

    if { [getCustomEnabled $node] == true } {
	set selected [getCustomConfigSelected $node]

	set bootcmd [getCustomConfigCommand $node $selected]
	set bootcfg [getCustomConfig $node $selected]
	set confFile "custom.conf"
    } else {
	set bootcfg [[typemodel $node].cfggen $node]
	set bootcmd [[typemodel $node].bootcmd $node]
	set confFile "boot.conf"
    }

    set cmds ""

    writeDataToFile $node_dir/$confFile [join $bootcfg "\n"]
    if {[typemodel $node] in "click_l2 click_l3 router.xorp"} {
	# click has no daemon mode, run in backgorund
	# xorp in daemon mode is too slow, run in background
	set cmds "\njexec $node_id $bootcmd $confFile > $node_dir/out.log 2>&1 &"
    } else {
	set cmds "\njexec $node_id $bootcmd $confFile > $node_dir/out.log 2>&1"
    }

    foreach ifc [allIfcList $node] {
	if {[getIfcOperState $node $ifc] == "down"} {
	    set cmds "$cmds\njexec $node_id ifconfig $ifc down"
	}
    }

    generateHostsFile $node

    catch {exec sh << $cmds} err
    if { $err != "" } {
	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES warning" \
		"There was a problem with configuring the node [getNodeName $node] ($node_id).\nCheck its /$confFile and /out.log files." \
	    info 0 Dismiss
	} else {
	    puts "IMUNES warning"
	    puts "\nThere was a problem with configuring the node [getNodeName $node] ($node_id).\nCheck its /$confFile and /out.log files."
	}
    }

}

#****f* freebsd.tcl/killAllNodeProcesses
# NAME
#   killAllNodeProcesses -- kill all node processes
# SYNOPSIS
#   killAllNodeProcesses $eid $node
# FUNCTION
#   Kills all processes in the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc killAllNodeProcesses { eid node } {
    set node_id "$eid.$node"

    catch "exec jexec $node_id kill -9 -1 2> /dev/null"
    catch "exec jexec $node_id tcpdrop -a 2> /dev/null"
}

#****f* freebsd.tcl/removeNodeIfcIPaddrs
# NAME
#   removeNodeIfcIPaddrs -- remove node iterfaces' IP addresses
# SYNOPSIS
#   removeNodeIfcIPaddrs $eid $node
# FUNCTION
#   Remove all IPv4 and IPv6 addresses from interfaces on the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc removeNodeIfcIPaddrs { eid node } {
    set node_id "$eid.$node"

    foreach ifc [ifcList $node] {
	foreach ipv4 [getIfcIPv4addr $node $ifc] {
	    catch "exec jexec $node_id ifconfig $ifc $ipv4 -alias"
	}
	foreach ipv6 [getIfcIPv6addr $node $ifc] {
	    catch "exec jexec $node_id ifconfig $ifc inet6 $ipv6 -alias"
	}
    }
}

#****f* freebsd.tcl/destroyNodeVirtIfcs
# NAME
#   destroyNodeVirtIfcs -- destroy node virtual interfaces
# SYNOPSIS
#   destroyNodeVirtIfcs $eid $node
# FUNCTION
#   Destroy any virtual interfaces (tun, vlan, gif, ..) before removing the #
#   jail. This is to avoid possible kernel panics.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc destroyNodeVirtIfcs { eid node } {
    set node_id $eid.$node

    pipesExec "for iface in `jexec $node_id ifconfig -l`; do jexec $node_id ifconfig \$iface destroy; done" "hold"
}

#****f* freebsd.tcl/removeNodeContainer
# NAME
#   removeNodeContainer -- remove node container
# SYNOPSIS
#   removeNodeContainer $eid $node
# FUNCTION
#   Removes the jail (container) of the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc removeNodeContainer { eid node } {
    set node_id $eid.$node

    pipesExec "jail -r $node_id" "hold"
}

#****f* freebsd.tcl/removeNodeFS
# NAME
#   removeNodeFS -- remove node filesystem
# SYNOPSIS
#   removeNodeFS $eid $node
# FUNCTION
#   Removes the filesystem of the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc removeNodeFS { eid node } {
    global vroot_unionfs vroot_linprocfs

    set node_id $eid.$node

    set VROOTDIR [getVrootDir]
    set VROOT_RUNTIME $VROOTDIR/$eid/$node
    set VROOT_RUNTIME_DEV $VROOT_RUNTIME/dev
    pipesExec "umount -f $VROOT_RUNTIME_DEV" "hold"
    if {$vroot_unionfs} {
	# 1st: unionfs RW overlay
	pipesExec "umount -f $VROOT_RUNTIME" "hold"
	# 2nd: nullfs RO loopback
	pipesExec "umount -f $VROOT_RUNTIME" "hold"
	pipesExec "rmdir $VROOT_RUNTIME" "hold"
    }

    if {$vroot_linprocfs} {
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

    catch {exec kldload nullfs}
    catch {exec kldload unionfs}

    catch {exec kldload ng_eiface}
    catch {exec kldload ng_pipe}
    catch {exec kldload ng_socket}
    catch {exec kldload if_tun}
    catch {exec kldload vlan}
#   catch {exec kldload ng_iface}
#   catch {exec kldload ng_cisco}

    foreach module $all_modules_list {
	if {[info procs $module.prepareSystem] == "$module.prepareSystem"} {
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
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global vroot_unionfs

    if {$vroot_unionfs} {
	# UNIONFS - anything to do here?
    } else {
	exec zfs create vroot/$eid
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

#****f* freebsd.tcl/createExperimentContainer
# NAME
#   createExperimentContainer -- create experiment container
# SYNOPSIS
#   createExperimentContainer
# FUNCTION
#   Creates a root jail (container) for the current experiment.
#****
proc createExperimentContainer {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::eid eid

    # Create top-level vimage
    exec jail -c name=$eid vnet children.max=[llength $node_list] persist
}

#****f* freebsd.tcl/createLinkBetween
# NAME
#   createLinkBetween -- create link between
# SYNOPSIS
#   createLinkBetween $lnode1 $lnode2 $ifname1 $ifname2
# FUNCTION
#   Creates link between two given nodes.
# INPUTS
#   * lnode1 -- node id of the first node
#   * lnode2 -- node id of the second node
#   * iname1 -- interface name on the first node
#   * iname2 -- interface name on the second node
#****
proc createLinkBetween { lnode1 lnode2 ifname1 ifname2 } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global debug

    set lname $lnode1-$lnode2

    set peer1 \
	[lindex [[typemodel $lnode1].nghook $eid $lnode1 $ifname1] 0]
    set peer2 \
	[lindex [[typemodel $lnode2].nghook $eid $lnode2 $ifname2] 0]
    set ngpeer1 $ngnodemap($peer1)
    set ngpeer2 $ngnodemap($peer2)
    set nghook1 \
	[lindex [[typemodel $lnode1].nghook $eid $lnode1 $ifname1] 1]
    set nghook2 \
	[lindex [[typemodel $lnode2].nghook $eid $lnode2 $ifname2] 1]

    set cmds ""

    # Special-case WLAN nodes: no need for ng_pipe there
    if {[nodeType $lnode1] == "wlan" || [nodeType $lnode2] == "wlan"} {
	catch {exec jexec $eid ngctl connect $ngpeer1: $ngpeer2: $nghook1 $nghook2} err
	if { $debug && $err != "" } {
	    puts $err
	}
	return
    }

    set cmds "$cmds\n mkpeer $ngpeer1: pipe $nghook1 upper"
    set cmds "$cmds\n name $ngpeer1:$nghook1 $lname"
    set cmds "$cmds\n connect $lname: $ngpeer2: lower $nghook2"

    # Ethernet frame has a 14-byte header - this is a temp. hack!!!
    set cmds "$cmds\n msg $lname: setcfg {header_offset=14}"
    catch {exec jexec $eid ngctl -f - << $cmds} err
    if { $debug && $err != "" } {
	puts $err
    }
}

#****f* freebsd.tcl/configureLinkBetween
# NAME
#   configureLinkBetween -- configure link between
# SYNOPSIS
#   configureLinkBetween $lnode1 $lnode2 $ifname1 $ifname2 $link
# FUNCTION
#   Configures link between two given nodes.
# INPUTS
#   * lnode1 -- node id of the first node
#   * lnode2 -- node id of the second node
#   * iname1 -- interface name on the first node
#   * iname2 -- interface name on the second node
#   * link -- link name
#****
proc configureLinkBetween { lnode1 lnode2 ifname1 ifname2 link } {
    upvar 0 ::cf::[set ::curcfg]::eid eid
    global linkJitterConfiguration debug

    set lname $lnode1-$lnode2

    set bandwidth [expr [getLinkBandwidth $link] + 0]
    set delay [expr [getLinkDelay $link] + 0]
    set ber [expr [getLinkBER $link] + 0]
    set dup [expr [getLinkDup $link] + 0]
    # Link parameters
    set cmds "msg $lname: setcfg {bandwidth=$bandwidth delay=$delay upstream={BER=$ber duplicate=$dup} downstream={BER=$ber duplicate=$dup}}"

    catch {exec jexec $eid ngctl -f - << $cmds} err
    if { $debug && $err != "" } {
	puts $err
    }

    # Queues
    foreach node [list $lnode1 $lnode2] {
	if {$node == $lnode1} {
	    set ifc $ifname1
	} else {
	    set ifc $ifname2
	}

	if {[nodeType $lnode1] != "rj45" && [nodeType $lnode2] != "rj45"} {
	    set qdisc [getIfcQDisc $node $ifc]
	    if {$qdisc ne "FIFO"} {
		execSetIfcQDisc $eid $node $ifc $qdisc
	    }
	    set qdrop [getIfcQDrop $node $ifc]
	    if {$qdrop ne "drop-tail"} {
		execSetIfcQDrop $eid $node $ifc $qdrop
	    }
	    set qlen [getIfcQLen $node $ifc]
	    if {$qlen ne 50} {
		execSetIfcQLen $eid $node $ifc $qlen
	    }
	}
    }

    if  { $linkJitterConfiguration } {
	execSetLinkJitter $eid $link
    }
}

#****f* freebsd.tcl/destroyLinkBetween
# NAME
#   destroyLinkBetween -- destroy link between
# SYNOPSIS
#   destroyLinkBetween $eid $lnode1 $lnode2
# FUNCTION
#   Destroys link between two given nodes.
# INPUTS
#   * eid -- experiment id
#   * lnode1 -- node id of the first node
#   * lnode2 -- node id of the second node
#****
proc destroyLinkBetween { eid lnode1 lnode2 } {
    pipesExec "jexec $eid ngctl msg $lnode1-$lnode2: shutdown"
}

#dummy procedure
proc destroyNetgraphNode { eid node } {
}

#****f* freebsd.tcl/destroyNetgraphNodes
# NAME
#   destroyNetgraphNodes -- destroy netgraph nodes
# SYNOPSIS
#   destroyNetgraphNodes $eid $ngraphs $widget
# FUNCTION
#   Destroys all netgraph nodes.
# INPUTS
#   * eid -- experiment id
#   * ngraphs -- list of ngraphs nodes
#   * widget -- status widget
#****
proc destroyNetgraphNodes { eid ngraphs widget } {
    global execMode

    # destroying netgraph nodes
    if { $ngraphs != "" } {
	statline "Shutting down netgraph nodes..."
	set i 0
	foreach node $ngraphs {
	    incr i
	    # statline "Shutting down netgraph node $node ([typemodel $node])"
	    [typemodel $node].destroy $eid $node
	    if {$execMode != "batch"} {
		$widget.p step -1
	    }
	    displayBatchProgress $i [ llength $ngraphs ]
	}
	statline ""
    }
}

#****f* freebsd.tcl/destroyVirtNodeIfcs
# NAME
#   destroyVirtNodeIfcs -- destroy virtual node interfaces
# SYNOPSIS
#   destroyVirtNodeIfcs $eid $vimages
# FUNCTION
#   Destroys all virtual node interfaces.
# INPUTS
#   * eid -- experiment id
#   * vimages -- list of virtual nodes
#****
proc destroyVirtNodeIfcs { eid vimages } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    # destroying virtual interfaces
    statline "Destroying virtual interfaces..."
    set i 0
    pipesCreate
    foreach node $vimages {
	incr i
	foreach ifc [ifcList $node] {
	    set ngnode $ngnodemap($ifc@$eid.$node)
	    pipesExec "jexec $eid ngctl shutdown $ngnode:"
	}
	displayBatchProgress $i [ llength $vimages ]
    }
    pipesClose
    statline ""
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
    global vroot_unionfs execMode

    set VROOT_BASE [getVrootDir]

    # Remove the main vimage which contained all other nodes, hopefully we
    # cleaned everything.
    if {$vroot_unionfs} {
	# UNIONFS
	catch "exec jexec $eid kill -9 -1 2> /dev/null"
	exec jail -r $eid
	catch "exec rm -fr $VROOT_BASE/$eid &"
    } else {
	# ZFS
	if {$execMode == "batch"} {
	    exec jail -r $eid
	    exec zfs destroy -fr vroot/$eid
	} else {
	    exec jail -r $eid &
	    exec zfs destroy -fr vroot/$eid &

	    catch {exec zfs list | grep -c "$eid"} output
	    set zfsCount [lindex [split $output] 0]

	    while {$zfsCount != 0} {
		catch {exec zfs list | grep -c "$eid/"} output
		set zfsCount [lindex [split $output] 0]
		$widget.p configure -value $zfsCount
		update
		after 200
	    }
	}
    }
}


#****f* freebsd.tcl/l2node.instantiate
# NAME
#   l2node.instantiate -- instantiate
# SYNOPSIS
#   l2node.instantiate $eid $node
# FUNCTION
#   Procedure l2node.instantiate creates a new netgraph node of the appropriate type.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node (type of the node is either lanswitch or hub)
#****
proc l2node.instantiate { eid node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    switch -exact [nodeType $node] {
	lanswitch {
	    set ngtype bridge
	}
	hub {
	    set ngtype hub
	}
    }

    set t [exec printf "mkpeer $ngtype link0 link0\nmsg .link0 setpersistent\nshow ." | jexec $eid ngctl -f -]
    set tlen [string length $t]
    set id [string range $t [expr $tlen - 31] [expr $tlen - 24]]
    catch {exec jexec $eid ngctl name \[$id\]: $node}
    set ngnodemap($eid\.$node) $node
}

#****f* freebsd.tcl/l2node.destroy
# NAME
#   l2node.destroy -- destroy
# SYNOPSIS
#   l2node.destroy $eid $node
# FUNCTION
#   Destroys a l2node (netgraph) node by sending a shutdown
#   message.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node
#****
proc l2node.destroy { eid node } {
    catch { nexec jexec $eid ngctl msg $node: shutdown }
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
#   captureExtIfc -- capture external interfaces
# SYNOPSIS
#   captureExtIfc $eid $node
# FUNCTION
#   Captures the external interfaces given by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc captureExtIfc { eid node } {
    upvar 0 ::cf::[set ::curcfg]::ngnodemap ngnodemap

    set ifname [getNodeName $node]
    if { [getEtherVlanEnabled $node] && [getEtherVlanTag $node] != "" } {
	exec ifconfig $ifname create
	exec ifconfig [lindex [split $ifname .] 0] up promisc
    }
    set ngifname [string map {. _} $ifname]
    set ngnodemap($ifname) $ngifname
    nexec ifconfig $ifname vnet $eid
    nexec jexec $eid ifconfig $ifname up promisc
}

#****f* freebsd.tcl/releaseExtIfc
# NAME
#   releaseExtIfc -- release external interfaces
# SYNOPSIS
#   releaseExtIfc $eid $node
# FUNCTION
#   Releases the external interfaces captured by the given rj45 node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc releaseExtIfc { eid node } {
    set ifname [getNodeName $node]
    catch {nexec ifconfig $ifname -vnet $eid}
    catch {nexec ifconfig $ifname up -promisc}
    if { [getEtherVlanEnabled $node] && [getEtherVlanTag $node] != "" } {
	catch {exec ifconfig $ifname destroy}
    }
}

#****f* freebsd.tcl/enableIPforwarding
# NAME
#   enableIPforwarding -- enable IP forwarding
# SYNOPSIS
#   enableIPforwarding $eid $node
# FUNCTION
#   Enables IPv4 and IPv6 forwarding on the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc enableIPforwarding { eid node } {
    global ipFastForwarding
    pipesExec "jexec $eid\.$node sysctl net.inet.ip.forwarding=1" "hold"
    if {$ipFastForwarding} {
	pipesExec "jexec $eid\.$node sysctl net.inet.ip.fastforwarding=1" "hold"
    }
    pipesExec "jexec $eid\.$node sysctl net.inet6.ip6.forwarding=1" "hold"
}

#****f* freebsd.tcl/configDefaultLoIfc
# NAME
#   configDefaultLoIfc -- configure default logical interface
# SYNOPSIS
#   configDefaultLoIfc $eid $node
# FUNCTION
#   Configures the default logical interface address for the given node.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc configDefaultLoIfc { eid node } {
    pipesExec "jexec $eid\.$node ifconfig lo0 127.0.0.1/8" "hold"
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
proc getExtIfcs { } {
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

proc ipsecFilesToNode { node local_cert ipsecret_file } {
    global ipsecConf ipsecSecrets

    if { $local_cert != "" } {
	set trimmed_local_cert [lindex [split $local_cert /] end]
	set fileId [open $trimmed_local_cert "r"]
	set trimmed_local_cert_data [read $fileId]
	writeDataToNodeFile $node /usr/local/etc/ipsec.d/certs/$trimmed_local_cert $trimmed_local_cert_data
	close $fileId
    }

    if { $ipsecret_file != "" } {
	set trimmed_local_key [lindex [split $ipsecret_file /] end]
	set fileId [open $trimmed_local_key "r"]
	set trimmed_local_key_data "# /etc/ipsec.secrets - strongSwan IPsec secrets file\n"
	set trimmed_local_key_data "$trimmed_local_key_data[read $fileId]\n"
	set trimmed_local_key_data "$trimmed_local_key_data: RSA $trimmed_local_key"
	writeDataToNodeFile $node /usr/local/etc/ipsec.d/private/$trimmed_local_key $trimmed_local_key_data
	close $fileId
    }

    writeDataToNodeFile $node /usr/local/etc/ipsec.conf $ipsecConf
    writeDataToNodeFile $node /usr/local/etc/ipsec.secrets $ipsecSecrets
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
proc createStartTunIfc { eid node } {
    # create and start tun interface and return its name
    catch {exec jexec $eid.$node ifconfig tun create} tun
    exec jexec $eid.$node ifconfig $tun up

    return $tun
}

proc prepareTaygaConf { eid node data datadir } {
    exec jexec $eid.$node mkdir -p $datadir
    writeDataToNodeFile $node "/usr/local/etc/tayga.conf" $data
}

proc taygaShutdown { eid node } {
    catch "exec jexec $eid.$node killall -9 tayga"
    exec jexec $eid.$node rm -rf /var/db/tayga
}

proc taygaDestroy { eid node } {
    global nat64ifc_$eid.$node
    catch {exec jexec $eid.$node ifconfig [set nat64ifc_$eid.$node] destroy}
}

# XXX External connection procedures
proc extInstantiate { node } {
    createNodePhysIfcs $node
}

proc startExternalIfc { eid node } {
    set cmds ""
    set ifc [lindex [ifcList $node] 0]
    set outifc "$eid-$node"

    set ipv4 [getIfcIPv4addr $node $ifc]
    if {$ipv4 == ""} {
	autoIPv4addr $node $ifc
    }
    set ipv4 [getIfcIPv4addr $node $ifc]
    set cmds "ifconfig $outifc $ipv4"

    set ipv6 [getIfcIPv6addr $node $ifc]
    if {$ipv6 == ""} {
	autoIPv6addr $node $ifc
    }
    set ipv6 [getIfcIPv6addr $node $ifc]
    set cmds "$cmds\n ifconfig $outifc inet6 $ipv6"

    set cmds "$cmds\n ifconfig $outifc up"

    exec sh << $cmds &
}

proc stopExternalIfc { eid node } {
    exec ifconfig $eid-$node down
}
