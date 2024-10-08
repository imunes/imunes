#
# Copyright 2004-2013 University of Zagreb.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# This work was supported in part by the Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

#****f* exec.tcl/deleteExperimentFiles
# NAME
#   deleteExperimentFiles -- delete experiment files
# SYNOPSIS
#   deleteExperimentFiles $eid
# FUNCTION
#   Deletes experiment files for the specified experiment.
# INPUTS
#   * eid -- experiment id
#****
proc deleteExperimentFiles { eid } {
    global runtimeDir
    set folderName "$runtimeDir/$eid"
    file delete -force $folderName
}

#****f* exec.tcl/l3node.shutdown
# NAME
#   l3node.shutdown -- layer 3 node shutdown
# SYNOPSIS
#   l3node.shutdown $eid $node
# FUNCTION
#   Shutdowns a layer 3 node (pc, host or router).
#   Simulates the shutdown proces of a node, kills all the services and
#   deletes ip addresses of all interfaces.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.shutdown { eid node } {
    killExtProcess "wireshark.*[getNodeName $node].*\\($eid\\)"
    killAllNodeProcesses $eid $node
    removeNodeIfcIPaddrs $eid $node
}

proc l3node.destroyIfcs { eid node ifcs } {
    destroyNodeIfcs $eid $node $ifcs
}

proc l2node.destroyIfcs { eid node ifcs } {
    destroyNodeIfcs $eid $node $ifcs
}

#****f* exec.tcl/l3node.destroy
# NAME
#   l3node.destroy -- layer 3 node destroy
# SYNOPSIS
#   l3node.destroy $eid $node
# FUNCTION
#   Destroys a layer 3 node (pc, host or router).
#   Destroys all the interfaces of the node by sending a shutdown message to
#   netgraph nodes and on the end destroys the vimage itself.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc l3node.destroy { eid node } {
    destroyNodeVirtIfcs $eid $node
    removeNodeContainer $eid $node
    destroyNamespace $eid-$node
    removeNodeFS $eid $node
}

proc checkTerminate {} {}

proc terminateL2L3Nodes { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node].shutdown] != "" } {
	    try {
		[getNodeType $node].shutdown $eid $node
	    } on error err {
		return -code error "Error in '[getNodeType $node].shutdown $eid $node': $err"
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    statline "Shutting down node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc releaseExternalIfcs { eid extifcs extifcsCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $extifcs {
	displayBatchProgress $batchStep $extifcsCount

	try {
	    [getNodeType $node].destroy $eid $node
	} on error err {
	    return -code error "Error in '[getNodeType $node].destroy $eid $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    statline "Destroying external connection [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $extifcsCount > 0 } {
	displayBatchProgress $batchStep $extifcsCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc destroyLinks { eid links linkCount w } {
    global progressbarCount execMode

    set batchStep 0
    set skipLinks ""
    foreach link $links {
	displayBatchProgress $batchStep $linkCount

	if { $link in $skipLinks } {
	    continue
	}

	set lnode1 [lindex [getLinkPeers $link] 0]
	set lnode2 [lindex [getLinkPeers $link] 1]

	set msg "Destroying link $link"
	set mirror_link [getLinkMirror $link]
	if { $mirror_link != "" } {
	    lappend skipLinks $mirror_link

	    set msg "Destroying link $link/$mirror_link"

	    set lnode2 [lindex [getLinkPeers $mirror_link] 0]
	}

	try {
	    if { [getLinkDirect $link] } {
		destroyDirectLinkBetween $eid $lnode1 $lnode2
	    } else {
		destroyLinkBetween $eid $lnode1 $lnode2 $link
	    }
	} on error err {
	    return -code error "Error in 'destroyLinkBetween $eid $lnode1 $lnode2 $link': $err"
	}

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    statline $msg
	    $w.p configure -value $progressbarCount
	    update
	}
    }
    pipesExec ""

    if { $linkCount > 0 } {
	displayBatchProgress $batchStep $linkCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc destroyL2Nodes { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [getNodeType $node].destroy $eid $node
	} on error err {
	    return -code error "Error in '[getNodeType $node].destroy $eid $node': $err"
	}

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    statline "Destroying L2 node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc destroyL3Nodes { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	try {
	    [getNodeType $node].destroy $eid $node
	} on error err {
	    return -code error "Error in '[getNodeType $node].destroy $eid $node': $err"
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    statline "Destroying L3 node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc finishTerminating { status msg w } {
    global progressbarCount execMode

    catch { pipesClose }
    if { $execMode == "batch" } {
	puts $msg
    } else {
	catch { destroy $w }
	set progressbarCount 0
	if { ! $status } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$msg \nCleanup the experiment and report the bug!" info 0 Dismiss
	}
    }
}

#****f* exec.tcl/terminateAllNodes
# NAME
#   terminateAllNodes -- shutdown and destroy all nodes in experiment
# SYNOPSIS
#   terminateAllNodes
# FUNCTION
#
#****
proc terminateAllNodes { eid } {
    global progressbarCount execMode

    set node_list [getFromRunning "node_list"]
    set link_list [getFromRunning "link_list"]
    set nodeCount [llength $node_list]
    set linkCount [llength $link_list]

    set t_start [clock milliseconds]

    try {
	checkTerminate
    } on error err {
	statline "ERROR in 'checkTerminate': '$err'"
	if { $execMode != "batch" } {
	    after idle {.dialog1.msg configure -wraplength 4i}
	    tk_dialog .dialog1 "IMUNES error" \
		"$err \nCleanup the experiment and report the bug!" info 0 Dismiss
	}
	return
    }

    statline "Preparing for termination..."
    set extifcs {}
    set l2nodes {}
    set l3nodes {}
    set allNodes {}
    set pseudoNodesCount 0
    foreach node $node_list {
	if { [getNodeType $node] != "pseudo" } {
	    if { [[getNodeType $node].virtlayer] == "NETGRAPH" } {
		if { [getNodeType $node] == "rj45" } {
		    lappend extifcs $node
		} elseif { [getNodeType $node] == "extnat" } {
		    lappend l3nodes $node
		} else {
		    lappend l2nodes $node
		}
	    } else {
		lappend l3nodes $node
	    }
	} else {
	    incr pseudoNodesCount
	}
    }
    set l2nodeCount [llength $l2nodes]
    set l3nodeCount [llength $l3nodes]
    set allNodes [concat $l2nodes $l3nodes]
    set allNodeCount [llength $allNodes]
    set extifcsCount [llength $extifcs]
    incr linkCount [expr -$pseudoNodesCount/2]
    set maxProgressbasCount [expr {1*$allNodeCount + $extifcsCount + $linkCount + $l2nodeCount + 3*$l3nodeCount}]
    set progressbarCount $maxProgressbasCount

    set w ""
    if { $execMode != "batch" } {
	set w .startup
	catch { destroy $w }

	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Terminating experiment $eid..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Deleting virtual nodes and links."
	pack $w.msg
	update

	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum $maxProgressbasCount -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    try {
	statline "Stopping services for NODESTOP hook..."
	services stop "NODESTOP"

	statline "Stopping all nodes..."
	pipesCreate
	terminateL2L3Nodes $eid $allNodes $allNodeCount $w
	statline "Waiting for processes on $allNodeCount node(s) to shutdown..."
	pipesClose

	statline "Releasing external interfaces..."
	pipesCreate
	releaseExternalIfcs $eid $extifcs $extifcsCount $w
	statline "Waiting for $extifcsCount external interface(s) to be released..."
	pipesClose

	statline "Stopping services for LINKDEST hook..."
	services stop "LINKDEST"

	statline "Destroying links..."
	pipesCreate
	destroyLinks $eid $link_list $linkCount $w
	statline "Waiting for $linkCount link(s) to be destroyed..."
	pipesClose

	statline "Destroying physical interfaces on L3 nodes..."
	pipesCreate
	destroyNodesIfcs $eid $l3nodes $l3nodeCount $w
	statline "Waiting for physical interfaces on $l3nodeCount L3 node(s) to be destroyed..."
	pipesClose

	statline "Destroying L2 nodes..."
	pipesCreate
	destroyL2Nodes $eid $l2nodes $l2nodeCount $w
	statline "Waiting for $l2nodeCount L2 node(s) to be destroyed..."
	pipesClose

	statline "Checking for hanging TCP connections on L3 node(s)..."
	pipesCreate
	timeoutPatch $eid $l3nodes $l3nodeCount $w
	statline "Waiting for hanging TCP connections on $l3nodeCount L3 node(s)..."
	pipesClose

	statline "Stopping services for NODEDEST hook..."
	services stop "NODEDEST"

	statline "Destroying L3 nodes..."
	pipesCreate
	destroyL3Nodes $eid $l3nodes $l3nodeCount $w
	statline "Waiting for $l3nodeCount L3 node(s) to be destroyed..."
	pipesClose

	statline "Removing experiment top-level container/netns..."
	pipesCreate
	removeExperimentContainer $eid $w
	pipesClose

	statline "Removing experiment files..."
	removeExperimentFiles $eid $w
	deleteExperimentFiles $eid
    } on error err {
	finishTerminating 0 "$err" $w
	return
    }

    finishTerminating 1 "" $w

    statline "Cleanup completed in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."

    if { $execMode == "batch" } {
	puts "Terminated experiment ID = $eid"
    }
}

proc timeoutPatch { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodeCount
	foreach node $nodes_left {
	    checkHangingTCPs $eid $node

	    incr batchStep
	    incr progressbarCount -1

	    set name [getNodeName $node]
	    if { $execMode != "batch" } {
		statline "Node $name stopped"
		$w.p configure -value $progressbarCount
		update
	    }
	    displayBatchProgress $batchStep $nodeCount

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc destroyNodesIfcs { eid nodes nodeCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodeCount

	if { [info procs [getNodeType $node].destroyIfcs] != "" } {
	    set ifcs [ifcList $node]
	    try {
		[getNodeType $node].destroyIfcs $eid $node $ifcs
	    } on error err {
		return -code error "Error in '[getNodeType $node].destroyIfcs $eid $node $ifcs': $err"
	    }
	}

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    statline "Destroying physical interfaces on node [getNodeName $node]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodeCount > 0 } {
	displayBatchProgress $batchStep $nodeCount
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

#****f* exec.tcl/stopNodeFromMenu
# NAME
#   stopNodeFromMenu -- stop node from button3menu
# SYNOPSIS
#   stopNodeFromMenu $node
# FUNCTION
#   Invokes the [typmodel $node].shutdown procedure, along with services shutdown.
# INPUTS
#   * node -- node id
#****
proc stopNodeFromMenu { node } {
    global progressbarCount execMode

    set progressbarCount 1
    set w ""
    if { $execMode != "batch" } {
	set w .startup
	catch { destroy $w }

	toplevel $w -takefocus 1
	wm transient $w .
	wm title $w "Stopping node $node..."
	message $w.msg -justify left -aspect 1200 \
	    -text "Deleting virtual nodes and links."
	pack $w.msg
	update

	ttk::progressbar $w.p -orient horizontal -length 250 \
	    -mode determinate -maximum 1 -value $progressbarCount
	pack $w.p
	update

	grab $w
	wm protocol $w WM_DELETE_WINDOW {
	}
    }

    pipesCreate
    services stop "NODESTOP" $node
    try {
	terminateL2L3Nodes [getFromRunning "eid"] $node 1 $w
    } on error err {
	finishTerminating 0 "$err" $w
	return
    }
    services stop "LINKDEST" $node
    services stop "NODEDEST"
    pipesClose

    finishTerminating 1 "" $w
}
