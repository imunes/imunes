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

#****f* exec.tcl/terminate_deleteExperimentFiles
# NAME
#   terminate_deleteExperimentFiles -- delete experiment files
# SYNOPSIS
#   terminate_deleteExperimentFiles $eid
# FUNCTION
#   Deletes experiment files for the specified experiment.
# INPUTS
#   * eid -- experiment id
#****
proc terminate_deleteExperimentFiles { eid } {
    global runtimeDir

    set folderName "$runtimeDir/$eid"
    file delete -force $folderName
}

proc checkTerminate {} {}

proc terminate_nodesShutdown { eid nodes nodes_count w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $nodes {
	displayBatchProgress $batchStep $nodes_count

	if { [info procs [getNodeType $node].nodeShutdown] != "" && [getFromRunning "${node}_running"] in "true delete" } {
	    try {
		[getNodeType $node].nodeShutdown $eid $node
	    } on error err {
		return -code error "Error in '[getNodeType $node].nodeShutdown $eid $node': $err"
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

    if { $nodes_count > 0 } {
	displayBatchProgress $batchStep $nodes_count
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc terminate_releaseExternalIfaces { eid extifcs extifcsCount w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node $extifcs {
	displayBatchProgress $batchStep $extifcsCount

	try {
	    [getNodeType $node].nodeDestroy $eid $node
	} on error err {
	    return -code error "Error in '[getNodeType $node].nodeDestroy $eid $node': $err"
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

proc linksDestroy { eid links links_count w } {
    global progressbarCount execMode

    set batchStep 0
    set skipLinks ""
    foreach link_id $links {
	displayBatchProgress $batchStep $links_count

	if { $link_id in $skipLinks } {
	    continue
	}

	set lnode1 [lindex [getLinkPeers $link_id] 0]
	set lnode2 [lindex [getLinkPeers $link_id] 1]

	set msg "Destroying link $link_id"
	set mirror_link [getLinkMirror $link_id]
	if { $mirror_link != "" } {
	    lappend skipLinks $mirror_link

	    set msg "Destroying link $link_id/$mirror_link"

	    set lnode2 [lindex [getLinkPeers $mirror_link] 0]
	}

	if { [getFromRunning "${link_id}_running"] == true } {
	    try {
		if { [getLinkDirect $link_id] } {
		    destroyDirectLinkBetween $eid $lnode1 $lnode2
		} else {
		    destroyLinkBetween $eid $lnode1 $lnode2 $link_id
		}
		setToRunning "${link_id}_running" false
	    } on error err {
		return -code error "Error in 'destroyLinkBetween $eid $lnode1 $lnode2 $link_id': $err"
	    }
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

    if { $links_count > 0 } {
	displayBatchProgress $batchStep $links_count
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc terminate_nodesDestroy { eid nodes nodes_count w } {
    global progressbarCount execMode

    set batchStep 0
    foreach node_id $nodes {
	displayBatchProgress $batchStep $nodes_count

	if { [getNodeType $node_id] != "pseudo" && [getFromRunning "${node_id}_running"] in "true delete" } {
	    try {
		[getNodeType $node_id].nodeDestroy $eid $node_id
	    } on error err {
		return -code error "Error in '[getNodeType $node_id].nodeDestroy $eid $node_id': $err"
	    }

	    if { [getFromRunning "${node_id}_running"] == "delete" } {
		unsetRunning "${node_id}_running"
	    } else {
		setToRunning "${node_id}_running" false
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    statline "Destroying node [getNodeName $node_id]"
	    $w.p configure -value $progressbarCount
	    update
	}
    }

    if { $nodes_count > 0 } {
	displayBatchProgress $batchStep $nodes_count
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc finishTerminating { status msg w } {
    global progressbarCount execMode

    foreach var "terminate_nodes destroy_nodes_ifaces terminate_links
	unconfigure_links unconfigure_nodes_ifaces unconfigure_nodes" {

	setToExecuteVars "$var" ""
    }

    catch { pipesClose }
    if { $execMode == "batch" } {
	puts $msg
    } else {
	catch { destroy $w }
	set progressbarCount 0
	if { ! $status } {
	    after idle { .dialog1.msg configure -wraplength 4i }
	    tk_dialog .dialog1 "IMUNES error" \
		"$msg \nCleanup the experiment and report the bug!" info 0 Dismiss
	}
    }
}

#****f* exec.tcl/undeployCfg
# NAME
#   undeployCfg -- shutdown and destroy all nodes in experiment
# SYNOPSIS
#   undeployCfg
# FUNCTION
#
#****
proc undeployCfg { { eid "" } { terminate 0 } } {
    global progressbarCount execMode skip_nodes

    if { ! $terminate } {
	if { ! [getFromRunning "cfg_deployed"] } {
	    return
	}

	if { ! [getFromRunning "auto_execution"] } {
	    if { $eid == "" } {
		set eid [getFromRunning "eid"]
	    }

	    createExperimentFiles $eid
	    createRunningVarsFile $eid

	    return
	}
    }

    foreach var "terminate_nodes destroy_nodes_ifaces terminate_links
	unconfigure_links unconfigure_nodes_ifaces unconfigure_nodes" {

	set $var ""
    }

    prepareTerminateVars

    if { "$terminate_nodes$destroy_nodes_ifaces$terminate_links$unconfigure_links$unconfigure_nodes_ifaces$unconfigure_nodes" == "" } {
	setToExecuteVars "terminate_cfg" ""

	return
    }

    set bkp_cfg ""
    set terminate_cfg [getFromExecuteVars "terminate_cfg"]
    if { $terminate_cfg != "" && $terminate_cfg != [cfgGet] } {
	upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

	set bkp_cfg [cfgGet]
	set dict_cfg $terminate_cfg
    }

    set skip_nodes {}
    set links_count [llength $terminate_links]

    set t_start [clock milliseconds]

    try {
	checkTerminate
    } on error err {
	statline "ERROR in 'checkTerminate': '$err'"
	if { $execMode != "batch" } {
	    after idle { .dialog1.msg configure -wraplength 4i }
	    tk_dialog .dialog1 "IMUNES error" \
		"$err \nCleanup the experiment and report the bug!" info 0 Dismiss
	}
	return
    }

    statline "Preparing for termination..."
    # TODO: fix this mess
    set extifcs {}
    set native_nodes {}
    set virtualized_nodes {}
    set all_nodes {}
    set pseudoNodesCount 0
    foreach node $terminate_nodes {
	set node_type [getNodeType $node]
	if { $node_type != "pseudo" } {
	    if { [$node_type.virtlayer] == "NATIVE" } {
		if { $node_type == "rj45" } {
		    lappend extifcs $node
		    lappend native_nodes $node
		} elseif { $node_type == "extnat" } {
		    lappend virtualized_nodes $node
		} else {
		    lappend native_nodes $node
		}
	    } else {
		lappend virtualized_nodes $node
	    }
	} else {
	    incr pseudoNodesCount
	}
    }
    set native_nodes_count [llength $native_nodes]
    set virtualized_nodes_count [llength $virtualized_nodes]
    set all_nodes [concat $native_nodes $virtualized_nodes]
    set all_nodes_count [llength $all_nodes]
    incr links_count [expr -$pseudoNodesCount/2]

    set destroy_nodes_ifaces_count 0
    set destroy_nodes_extifaces {}
    set destroy_nodes_extifaces_count 0
    if { $destroy_nodes_ifaces == "*" } {
	set destroy_nodes_ifaces ""
	foreach node_id $all_nodes {
	    if { $node_id ni $extifcs } {
		dict set destroy_nodes_ifaces $node_id "*"
		incr destroy_nodes_ifaces_count
	    } else {
		dict set destroy_nodes_extifaces $node_id "*"
		incr destroy_nodes_extifaces_count
	    }
	}
    } else {
	foreach {node_id ifaces} $destroy_nodes_ifaces {
	    if { $node_id ni $extifcs } {
		incr destroy_nodes_ifaces_count
	    } else {
		dict unset destroy_nodes_ifaces $node_id
		dict set destroy_nodes_extifaces $node_id $ifaces
		incr destroy_nodes_extifaces_count
	    }
	}
    }

    if { $unconfigure_nodes_ifaces == "*" } {
	set unconfigure_nodes_ifaces ""
	foreach node_id $all_nodes {
	    dict set unconfigure_nodes_ifaces $node_id "*"
	}
	set unconfigure_nodes_ifaces_count $all_nodes_count
    } else {
	set unconfigure_nodes_ifaces_count [llength [dict keys $unconfigure_nodes_ifaces]]
    }

    if { $unconfigure_nodes == "*" } {
	set unconfigure_nodes $all_nodes
    }
    set unconfigure_nodes_count [llength $unconfigure_nodes]

    set maxProgressbasCount [expr {1 + 1*$all_nodes_count + 1*$links_count + 1*$native_nodes_count + 2*$virtualized_nodes_count + 1*$unconfigure_nodes_ifaces_count + 1*$destroy_nodes_ifaces_count + 1*$destroy_nodes_extifaces_count + 1*$unconfigure_nodes_count}]
    set progressbarCount $maxProgressbasCount

    if { $eid == "" } {
	set eid [getFromRunning "eid"]
    }

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
	services stop "NODESTOP" "bkg" $unconfigure_nodes

	statline "Unconfiguring nodes..."
	pipesCreate
	terminate_nodesUnconfigure $eid $unconfigure_nodes $unconfigure_nodes_count $w
	statline "Waiting for unconfiguration of $unconfigure_nodes_count node(s)..."
	pipesClose

	statline "Stopping nodes..."
	pipesCreate
	terminate_nodesShutdown $eid $all_nodes $all_nodes_count $w
	statline "Waiting for processes on $all_nodes_count node(s) to shutdown..."
	pipesClose

	statline "Unconfiguring physical interfaces on nodes..."
	pipesCreate
	terminate_nodesIfacesUnconfigure $eid $unconfigure_nodes_ifaces $unconfigure_nodes_ifaces_count $w
	statline "Waiting for physical interfaces on $unconfigure_nodes_ifaces_count node(s) to be unconfigured..."
	pipesClose

	statline "Destroying physical interfaces on RJ45 nodes..."
	pipesCreate
	terminate_nodesIfacesDestroy $eid $destroy_nodes_extifaces $destroy_nodes_extifaces_count $w
	statline "Waiting for physical interfaces on $destroy_nodes_extifaces_count RJ45 node(s) to be destroyed..."
	pipesClose

	statline "Stopping services for LINKDEST hook..."
	services stop "LINKDEST" "bkg" $unconfigure_nodes

	statline "Destroying links..."
	pipesCreate
	linksDestroy $eid $terminate_links $links_count $w
	statline "Waiting for $links_count link(s) to be destroyed..."
	pipesClose

	statline "Destroying physical interfaces on nodes..."
	pipesCreate
	terminate_nodesIfacesDestroy $eid $destroy_nodes_ifaces $destroy_nodes_ifaces_count $w
	statline "Waiting for physical interfaces on $destroy_nodes_ifaces_count node(s) to be destroyed..."
	pipesClose

	statline "Destroying NATIVE nodes..."
	pipesCreate
	terminate_nodesDestroy $eid $native_nodes $native_nodes_count $w
	statline "Waiting for $native_nodes_count NATIVE node(s) to be destroyed..."
	pipesClose

	statline "Checking for hanging TCP connections on VIRTUALIZED node(s)..."
	pipesCreate
	timeoutPatch $eid $virtualized_nodes $virtualized_nodes_count $w
	statline "Waiting for hanging TCP connections on $virtualized_nodes_count VIRTUALIZED node(s)..."
	pipesClose

	statline "Stopping services for NODEDEST hook..."
	services stop "NODEDEST" "bkg" $virtualized_nodes

	statline "Destroying VIRTUALIZED nodes..."
	pipesCreate
	terminate_nodesDestroy $eid $virtualized_nodes $virtualized_nodes_count $w
	statline "Waiting for $virtualized_nodes_count VIRTUALIZED node(s) to be destroyed..."
	pipesClose

	if { $terminate } {
	    statline "Removing experiment top-level container/netns..."
	    pipesCreate
	    terminate_removeExperimentContainer $eid
	    pipesClose

	    statline "Removing experiment files..."
	    terminate_removeExperimentFiles $eid
	    terminate_deleteExperimentFiles $eid
	}
    } on error err {
	finishTerminating 0 "$err" $w
	return
    }

    finishTerminating 1 "" $w

    if { ! $terminate } {
	createExperimentFiles $eid
	createRunningVarsFile $eid
    }

    statline "Cleanup completed in [expr ([clock milliseconds] - $t_start)/1000.0] seconds."

    if { $bkp_cfg != "" } {
	upvar 0 ::cf::[set ::curcfg]::dict_cfg dict_cfg

	set dict_cfg $bkp_cfg
	setToExecuteVars "terminate_cfg" ""
    }

    if { $execMode == "batch" } {
	puts "Terminated experiment ID = $eid"
    }
}

proc timeoutPatch { eid nodes nodes_count w } {
    global progressbarCount execMode

    set batchStep 0
    set nodes_left $nodes
    while { [llength $nodes_left] > 0 } {
	displayBatchProgress $batchStep $nodes_count
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
	    displayBatchProgress $batchStep $nodes_count

	    set nodes_left [removeFromList $nodes_left $node]
	}
    }

    if { $nodes_count > 0 } {
	displayBatchProgress $batchStep $nodes_count
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc terminate_nodesUnconfigure { eid nodes nodes_count w } {
    global progressbarCount execMode

    set batchStep 0
    set subnet_gws {}
    set nodes_l2data [dict create]
    foreach node_id $nodes {
	displayBatchProgress $batchStep $nodes_count

	if { [info procs [getNodeType $node_id].nodeUnconfigure] != "" && [getFromRunning "${node_id}_running"] in "true delete" } {
	    try {
		[getNodeType $node_id].nodeUnconfigure $eid $node_id
	    } on error err {
		return -code error "Error in '[getNodeType $node_id].nodeUnconfigure $eid $node_id': $err"
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    $w.p configure -value $progressbarCount
	    statline "Unconfiguring node [getNodeName $node_id]"
	    update
	}
    }

    if { $nodes_count > 0 } {
	displayBatchProgress $batchStep $nodes_count
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc terminate_nodesIfacesUnconfigure { eid nodes_ifaces nodes_count w } {
    global progressbarCount execMode

    set batchStep 0
    set subnet_gws {}
    set nodes_l2data [dict create]
    dict for {node ifaces} $nodes_ifaces {
	if { $ifaces == "*" } {
	    set ifaces [allIfcList $node]
	}
	displayBatchProgress $batchStep $nodes_count

	if { [info procs [getNodeType $node].nodeIfacesUnconfigure] != "" && [getFromRunning "${node}_running"] in "true delete" } {
	    try {
		[getNodeType $node].nodeIfacesUnconfigure $eid $node $ifaces
	    } on error err {
		return -code error "Error in '[getNodeType $node].nodeIfacesUnconfigure $eid $node $ifaces': $err"
	    }
	}
	pipesExec ""

	incr batchStep
	incr progressbarCount -1

	if { $execMode != "batch" } {
	    $w.p configure -value $progressbarCount
	    statline "Unconfiguring interfaces on node [getNodeName $node]"
	    update
	}
    }

    if { $nodes_count > 0 } {
	displayBatchProgress $batchStep $nodes_count
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}

proc terminate_nodesIfacesDestroy { eid nodes_ifaces nodes_count w } {
    global progressbarCount execMode

    set batchStep 0
    dict for {node ifaces} $nodes_ifaces {
	displayBatchProgress $batchStep $nodes_count

	if { [info procs [getNodeType $node].nodeIfacesDestroy] != "" } {
	    if { $ifaces == "*" } {
		set ifaces [ifcList $node]
	    }

	    if { [getFromRunning "${node}_running"] in "true delete" } {
		try {
		    [getNodeType $node].nodeIfacesDestroy $eid $node $ifaces
		} on error err {
		    return -code error "Error in '[getNodeType $node].nodeIfacesDestroy $eid $node $ifaces': $err"
		}
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

    if { $nodes_count > 0 } {
	displayBatchProgress $batchStep $nodes_count
	if { $execMode == "batch" } {
	    statline ""
	}
    }
}
