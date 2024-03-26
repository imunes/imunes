#****f* editor.tcl/animateCursor
# NAME
#   animateCursor -- animate current cursor
# SYNOPSIS
#   animateCursor
# FUNCTION
#   Animates the cursor to show the status of the running script.
#****
proc animateCursor {} {
    global cursorState
    global clock_seconds

    if { [clock seconds] == $clock_seconds } {
	update
	return
    }
    set clock_seconds [clock seconds]
    if { $cursorState } {
	.panwin.f1.c config -cursor watch
	set cursorState 0
    } else {
	.panwin.f1.c config -cursor pirate
	set cursorState 1
    }
    update
}

#****f* editor.tcl/removeGUILink
# NAME
#   removeGUILink -- remove link from GUI
# SYNOPSIS
#   renoveGUILink $link_id $atomic
# FUNCTION
#   Removes link from GUI. It removes standard links as well as
#   split links and links connecting nodes on different canvases.
# INPUTS
#   * link_id -- the link id
#   * atomic -- defines if the remove was atomic action or a part 
#     of a composed, non-atomic action (relevant for updating log 
#     for undo).
#****
proc removeGUILink { link atomic } {
    global changed

    set nodes [linkPeers $link]
    set node1 [lindex $nodes 0]
    set node2 [lindex $nodes 1]
    if {[nodeType $node1] == "wlan" || [nodeType $node2] == "wlan"} {
	removeLink $link
	return
    }
    if { [nodeType $node1] == "pseudo" } {
	removeLink [getLinkMirror $link]
	removeLink $link
	removeNode [getNodeMirror $node1]
	removeNode $node1
	.panwin.f1.c delete $node1
    } elseif { [nodeType $node2] == "pseudo" } {
	removeLink [getLinkMirror $link]
	removeLink $link
	removeNode [getNodeMirror $node2]
	removeNode $node2
	.panwin.f1.c delete $node2
    } else {
	removeLink $link
    }
    .panwin.f1.c delete $link
    if { $atomic == "atomic" } {
	set changed 1
	updateUndoLog
    }
}

#****f* editor.tcl/removeGUINode
# NAME
#   removeGUINode -- remove node from GUI
# SYNOPSIS
#   renoveGUINode $node_id
# FUNCTION
#   Removes node from GUI. When removing a node from GUI the links
#   connected to that node are also removed.
# INPUTS
#   * node_id -- node id
#****
proc removeGUINode { node } {
    set type [nodeType $node]
    foreach ifc [ifcList $node] {
	set peer [peerByIfc $node $ifc]
	set link [linkByPeers $node $peer]
	set mirror [getLinkMirror $link]
	removeGUILink $link non-atomic
	if {$mirror != ""} {
	    removeGUILink $mirror non-atomic
	}
    }
    if { $type != "pseudo" } {
	removeNode $node
	.panwin.f1.c delete $node
    }
}

#****f* editor.tcl/splitGUILink
# NAME
#   splitGUILink -- splits a link
# SYNOPSIS
#   splitGUILink $link
# FUNCTION
#   Splits the link and draws new links and new pseudo nodes 
#   on the canvas.
# INPUTS
#   * link -- link id
#****
proc splitGUILink { link } {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global changed

    set peer_nodes [linkPeers $link]
    set new_nodes [splitLink $link pseudo]
    set orig_node1 [lindex $peer_nodes 0]
    set orig_node2 [lindex $peer_nodes 1]
    set new_node1 [lindex $new_nodes 0]
    set new_node2 [lindex $new_nodes 1]
    set new_link1 [linkByPeers $orig_node1 $new_node1]
    set new_link2 [linkByPeers $orig_node2 $new_node2]
    setLinkMirror $new_link1 $new_link2
    setLinkMirror $new_link2 $new_link1
    setNodeMirror $new_node1 $new_node2
    setNodeMirror $new_node2 $new_node1

    set x1 [lindex [getNodeCoords $orig_node1] 0]
    set y1 [lindex [getNodeCoords $orig_node1] 1]
    set x2 [lindex [getNodeCoords $orig_node2] 0]
    set y2 [lindex [getNodeCoords $orig_node2] 1]

    setNodeCoords $new_node1 \
	"[expr {($x1 + 0.4 * ($x2 - $x1)) / $zoom}] \
	[expr {($y1 + 0.4 * ($y2 - $y1)) / $zoom}]"
    setNodeCoords $new_node2 \
	"[expr {($x1 + 0.6 * ($x2 - $x1)) / $zoom}] \
	[expr {($y1 + 0.6 * ($y2 - $y1)) / $zoom}]"
    setNodeLabelCoords $new_node1 [getNodeCoords $new_node1]
    setNodeLabelCoords $new_node2 [getNodeCoords $new_node2]

    set changed 1
    updateUndoLog
    redrawAll
}

#****f* editor.tcl/selectNode
# NAME
#   selectNode -- select node 
# SYNOPSIS
#   selectNode $c $obj
# FUNCTION
#   Crates the selecting box around the specified canvas
#   object.
# INPUTS
#   * c -- tk canvas
#   * obj -- tk canvas object tag id
#****
proc selectNode { c obj } {
    if { $obj == "none" } {
	$c delete -withtags "selectmark"
	return
    }

    set node [lindex [$c gettags $obj] 1]

    if { $node == "" } {
	return
    }
    $c addtag selected withtag "node && $node"
    if { [nodeType $node] == "pseudo" } {
	set bbox [$c bbox "nodelabel && $node"]
    } elseif { [nodeType $node] == "rectangle" } {
	$c addtag selected withtag "rectangle && $node"
	set bbox [$c bbox "rectangle && $node"]
    } elseif { [nodeType $node] == "text" } {
	$c addtag selected withtag "text && $node"
	set bbox [$c bbox "text && $node"]
    } elseif { [nodeType $node] == "oval" } {
	$c addtag selected withtag "oval && $node"
	set bbox [$c bbox "oval && $node"]
    } elseif { [nodeType $node] == "freeform" } {
	$c addtag selected withtag "freeform && $node"
	set bbox [$c bbox "freeform && $node"]
    } else {
	set bbox [$c bbox "node && $node"]
    }
    if { $bbox == "" } {
	return
    }
    set bx1 [expr {[lindex $bbox 0] - 2}]
    set by1 [expr {[lindex $bbox 1] - 2}]
    set bx2 [expr {[lindex $bbox 2] + 1}]
    set by2 [expr {[lindex $bbox 3] + 1}]
    $c delete -withtags "selectmark && $node"
    $c create line $bx1 $by1 $bx2 $by1 $bx2 $by2 $bx1 $by2 $bx1 $by1 \
	-dash {6 4} -fill black -width 1 -tags "selectmark $node"
}

#****f* editor.tcl/selectAllObjects
# NAME
#   selectAllObjects -- select all objects on the canvas
# SYNOPSIS
#   selectAllObjects
# FUNCTION
#   Select all object on the canvas.
#****
proc selectAllObjects { } {
    foreach obj [.panwin.f1.c find withtag "node || text || oval || rectangle \
	|| freeform"] {
	selectNode .panwin.f1.c $obj
    }
}

#****f* editor.tcl/selectNodes
# NAME
#   selectNodes -- select nodes
# SYNOPSIS
#   selectNodes $nodelist
# FUNCTION
#   Select all nodes in a list.
# INPUTS
#   * nodelist -- list of nodes to select.
#****
proc selectNodes { nodelist } {
    foreach node $nodelist {
	selectNode .panwin.f1.c [.panwin.f1.c find withtag \
	    "(node || text || oval || rectangle || freeform) && $node"]
    }
}

#****f* editor.tcl/selectedNodes
# NAME
#   selectedNodes -- get selected nodes
# SYNOPSIS
#   selectedNodes
# FUNCTION
#   Gets selected nodes and returns them as a list.
# RESULT
#   * selected -- object list of selected nodes.
#****
proc selectedNodes {} {
    set selected {}
    foreach obj [.panwin.f1.c find withtag "node && selected"] {
	lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
    }
    foreach obj [.panwin.f1.c find withtag "oval && selected"] {
	lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
    }
    foreach obj [.panwin.f1.c find withtag "rectangle && selected"] {
	lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
    }
    foreach obj [.panwin.f1.c find withtag "text && selected"] {
	lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
    }
    foreach obj [.panwin.f1.c find withtag "freeform && selected"] {
	lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
    }
    return $selected
}

#****f* editor.tcl/selectedRealNodes
# NAME
#   selectedRealNodes -- get selected real nodes
# SYNOPSIS
#   selectedRealNodes
# FUNCTION
#   Gets selected real nodes and returns them as a list.
# RESULT
#   * selected -- object list of selected real nodes.
#****
proc selectedRealNodes {} {
    set selected {}
    foreach obj [.panwin.f1.c find withtag "node && selected"] {
	set node [lindex [.panwin.f1.c gettags $obj] 1]
	if { [getNodeMirror $node] != "" ||
	    [nodeType $node] == "rj45" } {
	    continue
	}
	lappend selected $node
    }
    return $selected
}

#****f* editor.tcl/selectAdjacent
# NAME
#   selectAdjacent -- select adjacent nodes
# SYNOPSIS
#   selectAdjacent
# FUNCTION
#   Finds all adjacent nodes and selects them.
#****
proc selectAdjacent {} {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas

    set selected [selectedNodes]
    set adjacent {}
    foreach node $selected {
	foreach ifc [ifcList $node] {
	    set peer [peerByIfc $node $ifc]
	    if { [getNodeMirror $peer] != "" } {
		return
	    }
	    if { [lsearch $adjacent $peer] < 0 } {
		lappend adjacent $peer
	    }
	}
    }
    selectNodes $adjacent
}

#****f* editor.tcl/button3link
# NAME
#   button3link 
# SYNOPSIS
#   button3link $c $x $y
# FUNCTION
#   This procedure is called when a right mouse button is 
#   clicked on the canvas. If there is a link on the place of
#   mouse click this procedure creates and configures a popup
#   menu. The options in the menu are:
#   * Configure -- configure the link
#   * Delete -- delete the link
#   * Split -- split the link
#   * Merge -- this option is active only if the link is previously
#   been split, by this action the link is merged.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate for popup menu
#   * y -- y coordinate for popup menu
#****
proc button3link { c x y } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode

    set link [lindex [$c gettags {link && current}] 1]
    if { $link == "" } {
	set link [lindex [$c gettags {linklabel && current}] 1]
	if { $link == "" } {
	    return
	}
    }

    .button3menu delete 0 end

    #
    # Configure link
    #
    .button3menu add command -label "Configure" \
	-command "linkConfigGUI $c $link"

    #
    # Clear link configuration 
    #
    .button3menu add command -label "Clear all settings" \
	-command "linkResetConfig $link"

    global linkJitterConfiguration
    if  { $linkJitterConfiguration } {
	#
	# Edit link jitter
	#
	.button3menu add command -label "Edit link jitter" \
	    -command "linkJitterConfigGUI $c $link"
	#
	# Reset link jitter
	#
	.button3menu add command -label "Clear link jitter" \
	    -command "linkJitterReset $link"
    }

    #
    # Delete link
    #
    if { $oper_mode != "exec" } {
	.button3menu add command -label "Delete" \
	    -command "removeGUILink $link atomic"
    } else {
	.button3menu add command -label "Delete" \
	    -state disabled
    }

    #
    # Split link
    #
    if { $oper_mode != "exec" && [getLinkMirror $link] == "" } {
	.button3menu add command -label "Split" \
	    -command "splitGUILink $link"
    } else {
	.button3menu add command -label "Split" \
	    -state disabled
    }

    #
    # Merge two pseudo nodes / links
    #
    if { $oper_mode != "exec" && [getLinkMirror $link] != "" &&
	[getNodeCanvas [getNodeMirror [lindex [linkPeers $link] 1]]] ==
	$curcanvas } {
	.button3menu add command -label "Merge" \
	    -command "mergeGUINode [lindex [linkPeers $link] 1]"
    } else {
	.button3menu add command -label "Merge" -state disabled
    }

    set x [winfo pointerx .]
    set y [winfo pointery .]
    tk_popup .button3menu $x $y
}

#****f* editor.tcl/movetoCanvas
# NAME
#   movetoCanvas -- move to canvas 
# SYNOPSIS
#   movetoCanvas $canvas
# FUNCTION
#   This procedure moves all the nodes selected in the GUI to
#   the specified canvas.
# INPUTS
#   * canvas -- canvas id.
#****
proc movetoCanvas { canvas } {
    global changed

    set selected_nodes [selectedNodes]
    foreach node $selected_nodes {
	setNodeCanvas $node $canvas
	set changed 1
    }
    foreach obj [.panwin.f1.c find withtag "linklabel"] {
	set link [lindex [.panwin.f1.c gettags $obj] 1]
	set link_peers [linkPeers $link]
	set peer1 [lindex $link_peers 0]
	set peer2 [lindex $link_peers 1]
	set peer1_in_selected [lsearch $selected_nodes $peer1]
	set peer2_in_selected [lsearch $selected_nodes $peer2]
	if { ($peer1_in_selected == -1 && $peer2_in_selected != -1) ||
	    ($peer1_in_selected != -1 && $peer2_in_selected == -1) } {
	    if { [nodeType $peer2] == "pseudo" } {
		setNodeCanvas $peer2 $canvas
		if { [getNodeCanvas [getNodeMirror $peer2]] == $canvas } {
		    mergeLink $link
		}
		continue
	    }
	    set new_nodes [splitLink $link pseudo]
	    set new_node1 [lindex $new_nodes 0]
	    set new_node2 [lindex $new_nodes 1]
	    setNodeMirror $new_node1 $new_node2
	    setNodeMirror $new_node2 $new_node1
	    setNodeName $new_node1 $peer2
	    setNodeName $new_node2 $peer1
	    set link1 [linkByPeers $peer1 $new_node1]
	    set link2 [linkByPeers $peer2 $new_node2]
	    setLinkMirror $link1 $link2
	    setLinkMirror $link2 $link1
	}
    }
    updateUndoLog
    redrawAll
}

#****f* editor.tcl/mergeGUINode
# NAME
#   mergeGUINode -- merge GUI node
# SYNOPSIS
#   mergeGUINode $node
# FUNCTION
#   This procedure removes the specified pseudo node as well
#   as it's mirror copy. Also this procedure removes the
#   pseudo links and reestablish the original link between
#   the non-pseudo nodes.
# INPUTS
#   * node -- node id of a pseudo node.
#****
proc mergeGUINode { node } {
    set link [lindex [linkByIfc $node [ifcList $node]] 0]
    mergeLink $link
    redrawAll
}

#****f* editor.tcl/button3node
# NAME
#   button3node
# SYNOPSIS
#   button3node $c $x $y
# FUNCTION
#   This procedure is called when a right mouse button is 
#   clicked on the canvas. If there is a node on the place of
#   mouse click this procedure creates and configures a popup
#   menu. The options in the menu are:
#   * Configure -- configure the node
#   * Create link to -- create a link to any available node,
#   it can be on the same canvas or on a different canvas.
#   * Move to -- move to some other canvas
#   * Merge -- this option is available only for pseudo nodes
#   that have mirror nodes on the same canvas (Pseudo nodes
#   created by splitting a link).
#   * Delete -- delete the node
#   * Shell window -- specifies the shell window to open in 
#   exec mode. This option is available only to nodes on a 
#   network layer
#   * Wireshark -- opens a Wireshark program for the specified 
#   node and the specified interface. This option is available 
#   only for network layer nodes in exec mode.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate for popup menu
#   * y -- y coordinate for popup menu
#****
proc button3node { c x y } {
    global isOSlinux
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::eid eid

    set node [lindex [$c gettags {node && current}] 1]

    if { $node == "" } {
	set node [lindex [$c gettags {nodelabel && current}] 1]
	if { $node == "" } {
	    return
	}
    }

    set type [nodeType $node]
    set mirror_node [getNodeMirror $node]

    if { [$c gettags "node && $node && selected"] == "" } {
	$c dtag node selected
	$c delete -withtags selectmark
	selectNode $c [$c find withtag "current"]
    }

    .button3menu delete 0 end

    #
    # Select adjacent
    #
    if { $type != "pseudo" } {
	.button3menu add command -label "Select adjacent" \
	    -command "selectAdjacent"
    } else {
	.button3menu add command -label "Select adjacent" \
	    -command "selectAdjacent" -state disabled
    }

    #
    # Configure node
    #
    if { $type != "pseudo" } {
	.button3menu add command -label "Configure" \
	    -command "nodeConfigGUI $c $node"
    } else {
	.button3menu add command -label "Configure" \
	    -command "nodeConfigGUI $c $node" -state disabled
    }
    
    #
    # Transform
    #
    .button3menu.transform delete 0 end
    if { $oper_mode == "exec" || $type == "pseudo" || $type == "ext" || [[typemodel $node].layer] != "NETWORK" } {
#	.button3menu add cascade -label "Transform to" \
#	    -menu .button3menu.transform -state disabled
    } else {
	.button3menu add cascade -label "Transform to" \
	    -menu .button3menu.transform
	.button3menu.transform add command -label "Router" \
	    -command "transformNodes \"[selectedRealNodes]\" router"
	.button3menu.transform add command -label "PC" \
	    -command "transformNodes \"[selectedRealNodes]\" pc"
	.button3menu.transform add command -label "Host" \
	    -command "transformNodes \"[selectedRealNodes]\" host"
    }

    #
    # Node icon preferences
    #   
    .button3menu.icon delete 0 end
    if { $oper_mode == "exec" || $type == "pseudo" } {
#	.button3menu add cascade -label "Node icon" \
#	    -menu .button3menu.icon -state disabled
    } else {
	.button3menu add cascade -label "Node icon" \
	    -menu .button3menu.icon
	.button3menu.icon add command -label "Change node icons" \
	    -command "changeIconPopup"
	.button3menu.icon add command -label "Set default icons" \
	    -command "setDefaultIcon"
    }

    #
    # Create a new link - can be between different canvases
    #
    .button3menu.connect delete 0 end
    if { $oper_mode == "exec" || $type == "pseudo" } {
#	.button3menu add cascade -label "Create link to" \
#	    -menu .button3menu.connect -state disabled
    } else {
	.button3menu add cascade -label "Create link to" \
	    -menu .button3menu.connect
    }
    destroy .button3menu.connect.selected
    menu .button3menu.connect.selected -tearoff 0
    .button3menu.connect add cascade -label "Selected" \
	-menu .button3menu.connect.selected
    .button3menu.connect.selected add command \
	-label "Chain" -command "P \[selectedRealNodes\]"
    .button3menu.connect.selected add command \
	-label "Star" \
	-command "Kb $node \[lsearch -all -inline -not -exact \
	\[selectedRealNodes\] $node\]"
    .button3menu.connect.selected add command \
	-label "Cycle" -command "C \[selectedRealNodes\]"
    .button3menu.connect.selected add command \
	-label "Clique" -command "K \[selectedRealNodes\]"
    .button3menu.connect.selected add command \
	-label "Random" -command "R \[selectedRealNodes\] \
	\[expr \[llength \[selectedRealNodes\]\] - 1\]"
    .button3menu.connect add separator
    foreach canvas $canvas_list {
	destroy .button3menu.connect.$canvas
	menu .button3menu.connect.$canvas -tearoff 0
	.button3menu.connect add cascade -label [getCanvasName $canvas] \
	    -menu .button3menu.connect.$canvas
    }
    foreach peer_node $node_list {
	set canvas [getNodeCanvas $peer_node]
	if { $type != "rj45" &&
	    [lsearch {pseudo rj45} [nodeType $peer_node]] < 0 &&
	    [ifcByLogicalPeer $node $peer_node] == "" } {
	    .button3menu.connect.$canvas add command \
		-label [getNodeName $peer_node] \
		-command "connectWithNode \"[selectedRealNodes]\" $peer_node"
	} elseif { [nodeType $peer_node] != "pseudo" } {
	    .button3menu.connect.$canvas add command \
		-label [getNodeName $peer_node] \
		-state disabled
	}
    }

    #
    # Move to another canvas
    #
    .button3menu.moveto delete 0 end
    if { $oper_mode == "exec" || $type == "pseudo" } {
#	.button3menu add cascade -label "Move to" \
#	    -menu .button3menu.moveto -state disabled
    } else {
	.button3menu add cascade -label "Move to" \
	    -menu .button3menu.moveto
	.button3menu.moveto add command -label "Canvas:" -state disabled
	foreach canvas $canvas_list {
	    if { $canvas != $curcanvas } {
		.button3menu.moveto add command \
		    -label [getCanvasName $canvas] \
		    -command "movetoCanvas $canvas"
	    } else {
		.button3menu.moveto add command \
		    -label [getCanvasName $canvas] -state disabled
	    }
	}
    }

    #
    # Merge two pseudo nodes / links
    #
    if { $oper_mode != "exec" && $type == "pseudo" && \
	[getNodeCanvas $mirror_node] == $curcanvas } {
	.button3menu add command -label "Merge" \
	    -command "mergeGUINode $node"
    } else {
#	.button3menu add command -label "Merge" -state disabled
    }

    #
    # Delete selection
    #
    if { $oper_mode != "exec" } {
	.button3menu add command -label "Delete" -command deleteSelection
    } else {
#	.button3menu add command -label "Delete" -state disabled
    }

    if { $type != "pseudo" } {
	.button3menu add separator
    }

    #
    # Start & stop node
    #
    if {$oper_mode == "exec" && [info procs [typemodel $node].start] != "" \
	&& [info procs [typemodel $node].shutdown] != ""} {
	.button3menu add command -label Start \
	    -command "startNodeFromMenu $node"
	.button3menu add command -label Stop \
	    -command "stopNodeFromMenu $node" 
	.button3menu add command -label Restart \
	    -command "stopNodeFromMenu $node; \
	     startNodeFromMenu $node" 
    } else {
#	.button3menu add command -label Start \
#	    -command "[typemodel $node].start $eid $node" -state disabled
#	.button3menu add command -label Stop \
#	    -command "[typemodel $node].shutdown $eid $node" -state disabled 
    }

    #
    # Services menu
    #
    .button3menu.services delete 0 end
    if {$oper_mode == "exec" && [[typemodel $node].virtlayer] == "VIMAGE" && $type != "ext" || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "NAMESPACE") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "DYNAMIPS") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "WIFIAP") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "WIFISTA")} {
	global all_services_list
	.button3menu add cascade -label "Services" \
	    -menu .button3menu.services
	foreach service $all_services_list {
	    set m .button3menu.services.$service
	    if { ! [winfo exists $m] } {
		menu $m -tearoff 0
	    } else {
		$m delete 0 end
	    }
	    .button3menu.services add cascade -label $service \
		-menu $m
	    foreach action { "Start" "Stop" "Restart" } {
		$m add command -label $action \
		    -command "$service.[string tolower $action] $node"
	    }
	}
    }

    #
    # Node settings
    #   
    .button3menu.sett delete 0 end
    if { $type != "pseudo" } {
	if { $type == "ext" && $oper_mode == "exec" } {
	.button3menu add cascade -label "Settings" \
	    -menu .button3menu.sett -state disabled
	} else {
	    .button3menu add cascade -label "Settings" \
		-menu .button3menu.sett
	}
    } else {
	#.button3menu add cascade -label "Settings" \
	    #-menu .button3menu.sett -state disabled
    }
    if { $oper_mode == "exec" } {
	.button3menu.sett add command -label "Import Running Configuration" \
	    -command "fetchNodeConfiguration"
    } else {
#        .button3menu.sett add command -label "Fetch Node Configurations" \
#	    -state disabled
	.button3menu.sett add command -label "Remove IPv4 addresses" \
	    -command "removeIPv4nodes"
        .button3menu.sett add command -label "Remove IPv6 addresses" \
	    -command "removeIPv6nodes"
    } 

    #
    # IPv4 autorenumber
    #
    if { $oper_mode == "exec" || [[typemodel $node].layer] == "LINK" \
	|| $type == "pseudo" } {
#	.button3menu add command -label "IPv4 autorenumber" \
#	    -state disabled
    } else {
	.button3menu add command -label "IPv4 autorenumber" \
	    -command { 
		global IPv4autoAssign
		set IPv4autoAssign 1
		changeAddressRange 
		set IPv4autoAssign 0
	    }
    }

    #
    # IPv6 autorenumber
    #
    if { $oper_mode == "exec" || [[typemodel $node].layer] == "LINK" \
	|| $type == "pseudo" } {
#	.button3menu add command -label "IPv6 autorenumber" \
#	    -state disabled
    } else {
	.button3menu add command -label "IPv6 autorenumber" \
	    -command {
		global IPv6autoAssign
		set IPv6autoAssign 1
		changeAddressRange6 
		set IPv6autoAssign 0
	    }
    }


    #
    # Shell selection
    #
    .button3menu.shell delete 0 end
    if {$type != "ext" && $oper_mode == "exec" && [[typemodel $node].virtlayer] == "VIMAGE" || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "NAMESPACE") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "DYNAMIPS") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "WIFIAP") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "WIFISTA")} {
	.button3menu add separator
	.button3menu add cascade -label "Shell window" \
	    -menu .button3menu.shell

	foreach cmd [existingShells [[typemodel $node].shellcmds] $node] {

	    .button3menu.shell add command -label "[lindex [split $cmd /] end]" \
		-command "spawnShell $node $cmd"

	}
    } else {
#	.button3menu add cascade -label "Shell window" \
#	    -menu .button3menu.shell -state disabled
    }

    .button3menu.wireshark delete 0 end
    .button3menu.tcpdump delete 0 end
    if {$oper_mode == "exec" && $type == "ext" } {
	.button3menu add separator
	#
	# Wireshark
	#
        set wiresharkComm ""
        foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
            if {[checkForExternalApps $wireshark] == 0} {
                set wiresharkComm $wireshark
                break
            }
        }
        if { $wiresharkComm != "" } {
	    .button3menu add command -label "Wireshark" \
		-command "captureOnExtIfc $node $wiresharkComm"
	}

	#
	# tcpdump
	#
	if {[checkForExternalApps "tcpdump"] == 0} {
	    .button3menu add command -label "tcpdump" \
		-command "captureOnExtIfc $node tcpdump"
	}

    #Modification for openvswitch 
    } elseif { $oper_mode == "exec" && [[typemodel $node].virtlayer] == "NETGRAPH" } {

       .button3menu add separator
        # 
	# Advanced Conf
	#
	.button3menu add cascade -label "Advanced Conf." \
	    -menu .button3menu.shell

	set cmd "/bin/bash"

	    .button3menu.shell add command -label "[lindex [split $cmd /] end]" \
		-command "spawnShell $node $cmd"

	
        # 
	# Wireshark
	#
	.button3menu add cascade -label "Wireshark" \
	    -menu .button3menu.wireshark
	if { [llength [allIfcList $node]] == 0 } {
	    .button3menu.wireshark add command -label "No interfaces available." 
	} else {
	    foreach ifc [allIfcList $node] {
		set tmpifc $ifc
		if { $isOSlinux } {
		    if { $ifc == "lo0" } {
			set tmpifc lo
		    }
		}
		set label "$tmpifc"
		if { [getIfcIPv4addr $node $ifc] != "" } {
		    set label "$label ([getIfcIPv4addr $node $ifc])"
		}
		if { [getIfcIPv6addr $node $ifc] != "" } {
		    set label "$label ([getIfcIPv6addr $node $ifc])"
		}
		.button3menu.wireshark add command -label $label \
		    -command "startWiresharkOnNodeIfc $node $tmpifc"
	    }
	}
    
    } elseif {$oper_mode == "exec" && [[typemodel $node].virtlayer] == "VIMAGE"  || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "NAMESPACE") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "DYNAMIPS") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "WIFIAP") || ($oper_mode == "exec" && [[typemodel $node].virtlayer] == "WIFISTA")} {
	# 
	# Wireshark
	#
	.button3menu add cascade -label "Wireshark" \
	    -menu .button3menu.wireshark
	if { [llength [allIfcList $node]] == 0 && [[typemodel $node].virtlayer] != "WIFISTA"} {
	    .button3menu.wireshark add command -label "No interfaces available." 
	} else {
        #Modification for wifi

        if {[[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA"} {

        set tmpifc [split $node "n"]
        set tmpifc [lindex $tmpifc 1]
		set label "wlan$tmpifc"
		
		.button3menu.wireshark add command -label $label \
		    -command "startWiresharkOnNodeIfc $node $label"
		set label "hwsim0" 

		.button3menu.wireshark add command -label "w_channels" \
		    -command "startWiresharkOnNodeIfc $node $label"
	 
        } else {
	    foreach ifc [allIfcList $node] {
		set tmpifc $ifc
		if { $isOSlinux } {
		    if { $ifc == "lo0" } {
			set tmpifc lo
		    }
		}
		set label "$tmpifc"
		if { [getIfcIPv4addr $node $ifc] != "" } {
		    set label "$label ([getIfcIPv4addr $node $ifc])"
		}
		if { [getIfcIPv6addr $node $ifc] != "" } {
		    set label "$label ([getIfcIPv6addr $node $ifc])"
		}
		.button3menu.wireshark add command -label $label \
		    -command "startWiresharkOnNodeIfc $node $tmpifc"
	    }
	}
	}
	#
	# tcpdump
	#6
	.button3menu add cascade -label "tcpdump" \
	    -menu .button3menu.tcpdump
        #Modification for wifi
	if { [llength [allIfcList $node]] == 0 && [[typemodel $node].virtlayer] != "WIFISTA"} {
	    .button3menu.tcpdump add command -label "No interfaces available." 
	} elseif {[[typemodel $node].virtlayer] == "WIFIAP" || [[typemodel $node].virtlayer] == "WIFISTA"} {

        set tmpifc [split $node "n"]
        set tmpifc [lindex $tmpifc 1]
		set label "wlan$tmpifc"
		
		.button3menu.tcpdump add command -label $label \
		    -command "startTcpdumpOnNodeIfc $node $label"
		set label "hwsim0" 

		.button3menu.tcpdump add command -label "w_channels" \
		    -command "startTcpdumpOnNodeIfc $node $label"
 
   } else {
	    foreach ifc [allIfcList $node] {
		set tmpifc $ifc
		if { $isOSlinux } {
		    if { $ifc == "lo0" } {
			set tmpifc lo
		    }
		}
		set label "$tmpifc"
		if { [getIfcIPv4addr $node $ifc] != "" } {
		    set label "$label ([getIfcIPv4addr $node $ifc])"
		}
		if { [getIfcIPv6addr $node $ifc] != "" } {
		    set label "$label ([getIfcIPv6addr $node $ifc])"
		}
		.button3menu.tcpdump add command -label $label \
		    -command "startTcpdumpOnNodeIfc $node $tmpifc"
	    }
	}


      
	#
	# Firefox
	#
	if {[checkForExternalApps "startxcmd"] == 0 && \
	    [checkForApplications $node "firefox"] == 0} {
	    .button3menu add command -label "Web Browser" \
		-command "startXappOnNode $node \"firefox -no-remote -setDefaultBrowser about:blank\""
	} else {
	    .button3menu add command -label "Web Browser" \
		-state disabled
	}
	#
	# Sylpheed mail client
	#
	if {[checkForExternalApps "startxcmd"] == 0 && \
	    [checkForApplications $node "sylpheed"] == 0} {
	    .button3menu add command -label "Mail client" \
		-command "startXappOnNode $node \"G_FILENAME_ENCODING=UTF-8 sylpheed\""
	} else {
	    .button3menu add command -label "Mail client" \
		-state disabled
	}
    } else {
#	.button3menu add cascade -label "Wireshark" \
#	    -menu .button3menu.wireshark -state disabled
#	.button3menu add command -label "Web Browser" \
#	    -state disabled
    }

    #
    # Finally post the popup menu on current pointer position
    #
    set x [winfo pointerx .]
    set y [winfo pointery .]
    tk_popup .button3menu $x $y
}

#****f* editor.tcl/button1
# NAME
#   button1 -- button1 clicked
# SYNOPSIS
#   button1 $c $x $y $button
# FUNCTION
#   This procedure is called when a left mouse button is 
#   clicked on the canvas. This procedure selects a new
#   node or creates a new node, depending on the selected 
#   tool.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#   * button -- the keyboard button that is pressed.
#****
proc button1 { c x y button } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global activetool newlink curobj changed def_router_model
    global router pc host lanswitch frswitch rj45 hub
    global oval rectangle text freeform newtext
    global lastX lastY
    global background selectbox
    global defLinkColor defLinkWidth
    global resizemode resizeobj

    set x [$c canvasx $x]
    set y [$c canvasy $y]

    set lastX $x
    set lastY $y

    set curobj [$c find withtag current]
    set curtype [lindex [$c gettags current] 0]
    if { $curtype == "node" || $curtype == "oval" ||
	 $curtype == "rectangle" || $curtype == "text" ||
	 $curtype == "freeform" || ( $curtype == "nodelabel" &&
	 [nodeType [lindex [$c gettags $curobj] 1]] == "pseudo") } {
	set node [lindex [$c gettags current] 1]
	set wasselected \
	    [expr {[lsearch [$c find withtag "selected"] \
	    [$c find withtag "(node || text || freeform || rectangle || oval) && $node"]] > -1}]
	if { $button == "ctrl" } {
	    if { $wasselected } {
		$c dtag $node selected
		$c delete -withtags "selectmark && $node"
	    }
	} elseif { !$wasselected } {
	    foreach node_type { "node" "text" "oval" "rectangle" "freeform"} {
		$c dtag $node_type selected
	    }
	    $c delete -withtags selectmark
	}
	if { $activetool == "select" && !$wasselected} {
	    selectNode $c $curobj
	}
    } elseif { $curtype == "selectmark" } {

	set t1 [$c gettags current]
	set o1 [lindex $t1 1]
	set type1 [nodeType $o1]
    
	if {$type1== "oval" || $type1== "rectangle"} { 
	    set resizeobj $o1
	    set bbox1 [$c bbox $o1]
	    set x1 [lindex $bbox1 0]
	    set y1 [lindex $bbox1 1]
	    set x2 [lindex $bbox1 2]
	    set y2 [lindex $bbox1 3]
	    set l 0 ;# left
	    set r 0 ;# right
	    set u 0 ;# up
	    set d 0 ;# down

	    if { $x < [expr $x1+($x2-$x1)/8.0]} { set l 1 }
	    if { $x > [expr $x2-($x2-$x1)/8.0]} { set r 1 }
	    if { $y < [expr $y1+($y2-$y1)/8.0]} { set u 1 }
	    if { $y > [expr $y2-($y2-$y1)/8.0]} { set d 1 }

	    if {$l==1} {
		if {$u==1} { 
		    set resizemode lu
		} elseif {$d==1} { 
		    set resizemode ld
		} else { 
		    set resizemode l
		} 
	    } elseif {$r==1} {
		if {$u==1} { 
		    set resizemode ru
		} elseif {$d==1} { 
		    set resizemode rd
		} else { 
		    set resizemode r
		} 
	    } elseif {$u==1} { 
		set resizemode u
	    } elseif {$d==1} {
		set resizemode d
	    } else {
		set resizemode false
	    }
	}

    } elseif { $button != "ctrl" || $activetool != "select" } {
	foreach node_type { "node" "text" "oval" "rectangle" "freeform"} {
	    $c dtag $node_type selected
	}
	$c delete -withtags selectmark
    }
    #determine whether we can create nodes on the current object
    set isObjectDrawable 0
    foreach type {background grid rectangle oval freeform text} {
	if { $type in [.panwin.f1.c gettags $curobj] } {
	    set isObjectDrawable 1
	    break
	}
    }
    if { $isObjectDrawable } {
	if { $activetool ni {select link oval rectangle text freeform} } {
	    # adding a new node
	    set node [newNode $activetool]
	    setNodeCanvas $node $curcanvas
	    setNodeCoords $node "[expr {$x / $zoom}] [expr {$y / $zoom}]"
	    # To calculate label distance we take into account the normal icon
	    # height
	    global $activetool\_iconheight
	    set dy [expr [set $activetool\_iconheight]/2 + 11]
	    setNodeLabelCoords $node "[expr {$x / $zoom}] \
		[expr {$y / $zoom + $dy}]"
	    drawNode $node
	    selectNode $c [$c find withtag "node && $node"]
	    set changed 1
	} elseif { $activetool == "select" \
	    && $curtype != "node" && $curtype != "nodelabel"} {
	    $c config -cursor cross
	    set lastX $x
	    set lastY $y
	    if {$selectbox != ""} {
		# We actually shouldn't get here!
		$c delete $selectbox
		set selectbox ""
	    }
	} elseif { $activetool == "oval" || $activetool == "rectangle" } {
	    $c config -cursor cross
	    set lastX $x
	    set lastY $y
	} elseif { $activetool == "text" } {
	    $c config -cursor xterm
	    set lastX $x
	    set lastY $y
	    set newtext [$c create text $lastX $lastY -text "" \
		-anchor w -justify left -tags "newtext"]
	}
    } else {
	if {$curtype in {node nodelabel text oval rectangle freeform}} {
	    $c config -cursor fleur
	}
	if {$activetool == "link" && $curtype == "node"} {
	    $c config -cursor cross
	    set lastX [lindex [$c coords $curobj] 0]
	    set lastY [lindex [$c coords $curobj] 1]
	    set newlink [$c create line $lastX $lastY $x $y \
		-fill $defLinkColor -width $defLinkWidth \
		-tags "link"]
	}
    }

    raiseAll $c
}

#****f* editor.tcl/button1-motion
# NAME
#   button1-motion -- button1 moved
# SYNOPSIS
#   button1-motion $c $x $y 
# FUNCTION
#   This procedure is called when a left mouse button is 
#   pressed and the mouse is moved around the canvas. 
#   This procedure creates new select box, moves the 
#   selected nodes or draws a new link.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button1-motion { c x y } {
    global activetool newlink changed
    global lastX lastY sizex sizey selectbox background
    global newoval newrect newtext newfree resizemode
    set x [$c canvasx $x]
    set y [$c canvasy $y]
    set curobj [$c find withtag current]
    set curtype [lindex [$c gettags current] 0]
    if {$activetool == "link" && $newlink != ""} {
	#creating a new link
	$c coords $newlink $lastX $lastY $x $y
    } elseif { $activetool == "select" && $curtype == "nodelabel" \
	&& [nodeType [lindex [$c gettags $curobj] 1]] != "pseudo" } {
	$c move $curobj [expr {$x - $lastX}] [expr {$y - $lastY}]
	set changed 1
	set lastX $x
	set lastY $y
    } elseif { $activetool == "select" && $curobj == "" && $curtype == "" } {
	return
    } elseif { $activetool == "select" && 
	( $curobj == $selectbox || $curtype == "background" ||
	$curtype == "grid" || ($curobj ni [$c find withtag "selected"] &&
	$curtype != "selectmark") && [nodeType [lindex [$c gettags $curobj] 1]] != "pseudo")  } {
	#forming the selectbox and resizing
	if {$selectbox == ""} {
	    set err [catch {
		set selectbox [$c create line \
		    $lastX $lastY $x $lastY $x $y $lastX $y $lastX $lastY \
		    -dash {10 4} -fill black -width 1 -tags "selectbox"]
		} error]
	    if { $err != 0 } {
		return
	    }
	    $c raise $selectbox "background || link || linklabel || interface"
	} else {
	    set err [catch {
		$c coords $selectbox \
		    $lastX $lastY $x $lastY $x $y $lastX $y $lastX $lastY
		} error]
	    if { $err != 0 } {
		return
	    }
	}
    # actually we should check if curobj==bkgImage
    } elseif { $activetool == "oval" && ( $curobj == $newoval \
	|| $curobj == $background || $curtype == "background" \
	|| $curtype == "grid")} {
	# Draw a new oval
	if {$newoval == ""} {
	    set newoval [$c create oval $lastX $lastY $x $y \
			-outline blue \
			-dash {10 4} -width 1 -tags "newoval"]
	    $c raise $newoval "background || link || linklabel || interface"
	} else {
	    $c coords $newoval \
		$lastX $lastY $x $y
	}
    } elseif { $activetool == "rectangle" && ( $curobj == $newrect \
	|| $curobj == $background || $curtype == "background" \
	|| $curtype == "oval" || $curtype == "grid")} {
	# Draw a new rectangle
	if {$newrect == ""} {
	    set newrect [$c create rectangle $lastX $lastY $x $y \
		-outline blue \
		-dash {10 4} -width 1 -tags "newrect"]
	    $c raise $newrect "oval || background || link || linklabel || interface"
	} else {
	    $c coords $newrect $lastX $lastY $x $y
	}
    } elseif { $activetool == "freeform" && ( $curobj == $newfree \
	|| $curobj == $background || $curtype == "background" \
	|| $curtype == "oval" || $curtype == "rectangle"  \
	|| $curtype == "grid")} {
	# Draw a new freeform
	if {$newfree == ""} {
	    set newfree [$c create line $lastX $lastY $x $y \
		-fill blue -width 2 -tags "newfree"]
	    $c raise $newfree "oval || rectangle || background || link || linklabel || interface"
	} else {
	    xpos $newfree $x $y 2 blue
	}		
    } elseif { $curtype == "selectmark" } {
	foreach o [$c find withtag "selected"] { 
	    set node [lindex [$c gettags $o] 1]
	    set tagovi [$c gettags $o]
	    set koord [getNodeCoords $node]

	    set oldX1 [lindex $koord 0]
	    set oldY1 [lindex $koord 1]
	    set oldX2 [lindex $koord 2]
	    set oldY2 [lindex $koord 3]
	    switch -exact -- $resizemode {
		lu {
		    set oldX1 $x
		    set oldY1 $y
		}
		ld {
		    set oldX1 $x
		    set oldY2 $y
		}
		l {
		    set oldX1 $x
		}
		ru {
		    set oldX2 $x
		    set oldY1 $y
		}
		rd {
		    set oldX2 $x
		    set oldY2 $y
		}
		r {
		    set oldX2 $x
		}
		u {
		    set oldY1 $y
		}
		d {
		    set oldY2 $y
		}
	    }
	    if {$selectbox == ""} {
		set err [catch {
		    set selectbox [$c create line \
			$oldX1 $oldY1 $oldX2 $oldY1 $oldX2 $oldY2 $oldX1 $oldY2 $oldX1 $oldY1 \
			-dash {10 4} -fill black -width 1 -tags "selectbox"]
		    } error]
		if { $err != 0 } {
		    return
		}
		$c raise $selectbox "background || link || linklabel || interface"
	    } else {
		set err [catch {
		    $c coords $selectbox \
			$oldX1 $oldY1 $oldX2 $oldY1 $oldX2 $oldY2 $oldX1 $oldY2 $oldX1 $oldY1
		    } error]
		if { $err != 0 } {
		    return
		}
	    }
	}
    } else {
	foreach img [$c find withtag "selected"] {
	    $c move $img [expr {$x - $lastX}] [expr {$y - $lastY}]

	    set node [lindex [$c gettags $img] 1]

	    foreach elem { "selectmark" "nodelabel" "link"} {
		set obj [$c find withtag "$elem && $node"]
		$c move $obj [expr {$x - $lastX}] [expr {$y - $lastY}]
		if { $elem == "link" } {
		    $c addtag need_redraw withtag "link && $node"
		}
	    }
	}
	foreach link [$c find withtag "link && need_redraw"] {
	    redrawLink [lindex [$c gettags $link] 1]
	}
	$c dtag link need_redraw
	set changed 1
	set lastX $x
	set lastY $y
    }
}

#****f* editor.tcl/button1-release
# NAME
#   button1-release -- button1 released
# SYNOPSIS
#   button1-release $c $x $y 
# FUNCTION
#   This procedure is called when a left mouse button is 
#   released. 
#   The result of this function depends on the actions
#   during the button1-motion procedure.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button1-release { c x y } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
    upvar 0 ::cf::[set ::curcfg]::undolog undolog
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global activetool newlink curobj grid
    global changed selectbox
    global lastX lastY sizex sizey
    global autorearrange_enabled
    global resizemode resizeobj

    set redrawNeeded 0

    set outofbounds 0
	
    set x [$c canvasx $x]
    set y [$c canvasy $y]

    $c config -cursor left_ptr
    # if the link tool is active and we are creating a new link
    if {$activetool == "link" && $newlink != ""} {
	$c delete $newlink
	set newlink ""
	set destobj ""
	# find the node that is under the cursor
	foreach obj [$c find overlapping $x $y $x $y] {
	    if {[lindex [$c gettags $obj] 0] == "node"} {
		set destobj $obj
		break
	    }
	}
	# if there is an object beneath the cursor and an object was
	# selected by the button1 procedure create a link between nodes
	if {$destobj != "" && $curobj != "" && $destobj != $curobj} {
	    set lnode1 [lindex [$c gettags $destobj] 1]
	    set lnode2 [lindex [$c gettags $curobj] 1]
	    if { [ifcByLogicalPeer $lnode1 $lnode2] == "" } {
		set link [newLink $lnode1 $lnode2]
		if { $link != "" } {
		    drawLink $link
		    redrawLink $link
		    updateLinkLabel $link
		    set changed 1
		}
	    }
	}
    } elseif {$activetool == "rectangle" || $activetool == "oval" \
	|| $activetool == "text" || $activetool =="freeform"} {
	popupAnnotationDialog $c 0 "false" 
    }

    if { $changed == 1 } {
	set regular true
	# selects the node whose label was moved
	if { [lindex [$c gettags $curobj] 0] == "nodelabel" } {
	    set node [lindex [$c gettags $curobj] 1]
	    selectNode $c [$c find withtag "node && $node"]
	}
	set selected {}
	foreach img [$c find withtag "selected"] {
	    set node [lindex [$c gettags $img] 1]
	    lappend selected $node
	    set coords [$c coords $img]
	    set x [expr {[lindex $coords 0] / $zoom}]
	    set y [expr {[lindex $coords 1] / $zoom}]
	    
	    # only nodes are snapped to grid, annotations are not
	    if { $autorearrange_enabled == 0 && \
		[$c find withtag "node && $node"] != "" } {
		set dx [expr {(int($x / $grid + 0.5) * $grid - $x) * $zoom}]
		set dy [expr {(int($y / $grid + 0.5) * $grid - $y) * $zoom}]
		$c move $img $dx $dy
		set coords [$c coords $img]
		set x [expr {[lindex $coords 0] / $zoom}]
		set y [expr {[lindex $coords 1] / $zoom}]
		setNodeCoords $node "$x $y"
		#moving the nodelabel assigned to the moving node
		$c move "nodelabel && $node" $dx $dy
		set coords [$c coords "nodelabel && $node"]
		set x [expr {[lindex $coords 0] / $zoom}]
		set y [expr {[lindex $coords 1] / $zoom}]
		setNodeLabelCoords $node "$x $y"
		if {$x < 0 || $y < 0 || $x > $sizex || $y > $sizey} {
		    set regular false
		}
	    } else {
		set dx 0
		set dy 0
	    }
	    # only nodes (annotations can not) can set the regular flag
#	    if {$x < 0 || $y < 0 || $x > $sizex || $y > $sizey} {
#		set regular false
#	    } 
	    if { [lindex [$c gettags $node] 0] == "oval"} {
		set coordinates [$c coords [lindex [$c gettags $node] 1]]
		set x1 [expr {[lindex $coordinates 0] / $zoom}]
		set y1 [expr {[lindex $coordinates 1] / $zoom}]
		set x2 [expr {[lindex $coordinates 2] / $zoom}]
		set y2 [expr {[lindex $coordinates 3] / $zoom}]
		if {$x1<0} {
		    set x2 [expr {$x2-$x1}]
		    set x1 0
		    set outofbounds 1
		}
		if {$y1<0} {
		    set y2 [expr {$y2-$y1}]
		    set y1 0
		    set outofbounds 1
		}
		if {$x2>$sizex} {
		    set x1 [expr {$x1-($x2-$sizex)}]
		    set x2 $sizex
		    set outofbounds 1
		}
		if {$y2>$sizey} {
		    set y1 [expr {$y1-($y2-$sizey)}]
		    set y2 $sizey
		    set outofbounds 1
		}
		setNodeCoords $node "$x1 $y1 $x2 $y2"
	    }
	    if {[lindex [$c gettags $node] 0] == "rectangle" } {
		set coordinates [$c coords [lindex [$c gettags $node] 1]]
		set x1 [expr {[lindex $coordinates 0] / $zoom}]
		set y1 [expr {[lindex $coordinates 1] / $zoom}]
		set x2 [expr {[lindex $coordinates 6] / $zoom}]
		set y2 [expr {[lindex $coordinates 13] / $zoom}]
		if {$x1<0} {
		    set x2 [expr {$x2-$x1}]
		    set x1 0
		    set outofbounds 1
		}
		if {$y1<0} {
		    set y2 [expr {$y2-$y1}]
		    set y1 0
		    set outofbounds 1
		}
		if {$x2>$sizex} {
		    set x1 [expr {$x1-($x2-$sizex)}]
		    set x2 $sizex
		    set outofbounds 1
		}
		if {$y2>$sizey} {
		    set y1 [expr {$y1-($y2-$sizey)}]
		    set y2 $sizey
		    set outofbounds 1
		}
		setNodeCoords $node "$x1 $y1 $x2 $y2"
	    }
	    if { [lindex [$c gettags $node] 0] == "freeform"} {
		set bbox [$c bbox "selectmark && $node"]
		set x1 [expr {[lindex $bbox 0] / $zoom}]
		set y1 [expr {[lindex $bbox 1] / $zoom}]
		set x2 [expr {[lindex $bbox 2] / $zoom}]
		set y2 [expr {[lindex $bbox 3] / $zoom}]
		set shiftx 0	
		set shifty 0	

		if {$x1<0} {
		    set shiftx -$x1
		    set outofbounds 1
		}
		if {$y1<0} {
		    set shifty -$y1
		    set outofbounds 1
		}
		if {$x2>$sizex} {
		    set shiftx [expr $sizex-$x2]
		    set outofbounds 1
		}
		if {$y2>$sizey} {
		    set shifty [expr $sizey-$y2]
		    set outofbounds 1
		}

		set coordinates [$c coords [lindex [$c gettags $node] 1]]
                set l [expr {[llength $coordinates]-1}]
                set newcoords {}
                set i 0

		while {$i<=$l} {
                    set f1 [expr {[lindex $coords $i] * $zoom}]
                    set g1 [expr {[lindex $coords $i+1] * $zoom}]
                    set xx1 [expr $f1+$shiftx]
                    set yy1 [expr $g1+$shifty]

                    lappend newcoords $xx1 $yy1
                    set i [expr {$i+2}]
                }
                setNodeCoords $node $newcoords
	    }
	    if { [lindex [$c gettags $node] 0] == "text"} {
		set bbox [$c bbox "selectmark && $node"]
		set coordinates [$c coords [lindex [$c gettags $node] 1]]
		set x1 [expr [lindex $coordinates 0]]
		set y1 [expr [lindex $coordinates 1]]
		set width [expr [lindex $bbox 2] - [lindex $bbox 0]]
		set height [expr [lindex $bbox 3] - [lindex $bbox 1]]
		if {[lindex $bbox 0]<0} {
		    set x1 5
		    set outofbounds 1
		}
		if {[lindex $bbox 1]<0} {
		    set y1 [expr $height/2]
		    set outofbounds 1
		}
		if {[lindex $bbox 2]>$sizex} {
		    set x1 [expr $sizex-$width+5]
		    set outofbounds 1
		}
		if {[lindex $bbox 3]>$sizey} {
		    set y1 [expr {$sizey-$height/2}]
		    set outofbounds 1
		}
		setNodeCoords $node "$x1 $y1"
	    }

	    $c move "selectmark && $node" $dx $dy
	    $c addtag need_redraw withtag "link && $node"
	    set changed 1
	} ;# end of: foreach img selected

	if {$outofbounds} {
	    redrawAll
	    if {$activetool == "select" } {
		selectNodes $selected
	    }
	}


	if {$regular == "true"} {
	    foreach link [$c find withtag "link && need_redraw"] {
		redrawLink [lindex [$c gettags $link] 1]
                updateLinkLabel [lindex [$c gettags $link] 1]
	    }
	} else {
	    .panwin.f1.c config -cursor watch
	    loadCfg $undolog($undolevel)
	    redrawAll
	    if {$activetool == "select" } {
		selectNodes $selected
	    }
	    set changed 0
	}
	$c dtag link need_redraw

    # $changed!=1
    } elseif {$activetool == "select" } { 
	if {$selectbox == ""} {
	    set x1 $x
	    set y1 $y
	    set autorearrange_enabled 0
	} else {
	    set coords [$c coords $selectbox]
	    set x [lindex $coords 0]
	    set y [lindex $coords 1]
	    set x1 [lindex $coords 4]
	    set y1 [lindex $coords 5]
	    $c delete $selectbox
	    set selectbox ""
	}

	if { $resizemode == "false" } {
	    set enclosed {}
	    catch {$c find enclosed $x $y $x1 $y1} enc_objs
	    foreach obj $enc_objs {
		set tags [$c gettags $obj]
		if {[lindex $tags 0] == "node" && [lsearch $tags selected] == -1} {
		    lappend enclosed $obj
		}
		if {[lindex $tags 0] == "oval" && [lsearch $tags selected] == -1} {
		    lappend enclosed $obj
		}
		if {[lindex $tags 0] == "rectangle" && [lsearch $tags selected] == -1} {
		    lappend enclosed $obj
		}
		if {[lindex $tags 0] == "text" && [lsearch $tags selected] == -1} {
		    lappend enclosed $obj
		}
		if {[lindex $tags 0] == "freeform" && [lsearch $tags selected] == -1} {
		    lappend enclosed $obj
		}
	    }
	    foreach obj $enclosed {
		selectNode $c $obj
	    }
	} else {
	    setNodeCoords $resizeobj "$x $y $x1 $y1"
	    set redrawNeeded 1
	    set resizemode false
	}
    }

    if { $redrawNeeded } {
	set redrawNeeded 0
	redrawAll
    } else {
	raiseAll $c
    }
    update
    updateUndoLog
}

#****f* editor.tcl/button3background
# NAME
#   button3background -- button3 background
# SYNOPSIS
#   button3background $c $x $y
# FUNCTION
#   Popup menu for right click on canvas background.
# INPUTS
#   * c -- tk canvas
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button3background { c x y } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    global showBkgImage changed

    .button3menu delete 0 end

    #
    # Show canvas background
    #
    .button3menu add checkbutton -label "Show background" \
    -underline 5 -variable showBkgImage \
    -command { redrawAll }
    
    .button3menu add separator
    #
    # Change canvas background
    #
    .button3menu add command -label "Change background" \
	    -command "changeBkgPopup"
	    
    #
    # Remove canvas background
    #
    .button3menu add command -label "Remove background" \
	    -command "removeCanvasBkg $curcanvas;
		      if {\"[getCanvasBkg $curcanvas]\" !=\"\"} {
			  removeImageReference [getCanvasBkg $curcanvas] $curcanvas
		      }
		      redrawAll;
		      set changed 1;
		      updateUndoLog"
	    
    
    .button3menu.canvases delete 0 end
    
    set m .button3menu.canvases

    set mode normal
    if {[llength $canvas_list] == 1 } {
	set mode disabled
    }
    .button3menu add cascade -label "Set background from:" -menu $m -underline 0 -state $mode
    foreach c $canvas_list {
	set canv_name [getCanvasName $c]
	set canv_bkg [getCanvasBkg $c]
	set curcanvsize [getCanvasSize $curcanvas]
	set othercanvsize [getCanvasSize $c]
	if {$curcanvas != $c && $curcanvsize == $othercanvsize} {
	    $m add command -label "$canv_name" \
	    -command "setCanvasBkg $curcanvas $canv_bkg;
		      setImageReference $canv_bkg $curcanvas
		      redrawAll;
		      set changed 1;
		      updateUndoLog"
	}
    }

    #
    # Finally post the popup menu on current pointer position
    #
    set x [winfo pointerx .]
    set y [winfo pointery .]
    tk_popup .button3menu $x $y
}

#****f* editor.tcl/setDefaultIcon
# NAME
#   setDefaultIcon -- set default icon
# SYNOPSIS
#   setDefaultIcon
# FUNCTION
#   Sets all selected nodes icons to default icons.
#****
proc setDefaultIcon {} {
    global changed
    set nodelist [selectedNodes]

    foreach node $nodelist {
	set icon [getCustomIcon $node]
	removeCustomIcon $node
	removeImageReference $icon $node
    }
    redrawAll
    set changed 1
    updateUndoLog
}

#****f* editor.tcl/nodeEnter
# NAME
#   nodeEnter -- node enter
# SYNOPSIS
#   nodeEnter $c
# FUNCTION
#   This procedure prints the node id, node name and 
#   node model (if exists), as well as all the interfaces
#   of the node in the status line. 
#   Information is presented for the node above which is
#   the mouse pointer.  
# INPUTS
#   * c -- tk canvas
#****
proc nodeEnter { c } {
    global activetool
    
    set node [lindex [$c gettags current] 1]
    set err [catch {nodeType $node} error] 
    if { $err != 0 } {
	return
    }

    set type [nodeType $node]
    set name [getNodeName $node]
    set model [getNodeModel $node]
    if { $model != "" } {
	set line "{$node} $name ($model):"
    } else {
	set line "{$node} $name:"
    }
    if { $type != "rj45" } {
	foreach ifc [ifcList $node] {
	    set line "$line $ifc:[getIfcIPv4addr $node $ifc]"
	}
    }
    .bottom.textbox config -text "$line"

    showCfg $c $node
    showRoute $c $node
}

#****f* editor.tcl/linkEnter
# NAME
#   linkEnter -- link enter
# SYNOPSIS
#   linkEnter $c
# FUNCTION
#   This procedure prints the link id, link bandwidth
#   and link delay in the status line.
#   Information is presented for the link above which is
#   the mouse pointer.  
# INPUTS
#   * c -- tk canvas
#****
proc linkEnter {c} {
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    global activetool

    set link [lindex [$c gettags current] 1]
    if { [lsearch $link_list $link] == -1 } {
	return
    }
    set line "$link: [getLinkBandwidthString $link] [getLinkDelayString $link]"
    .bottom.textbox config -text "$line"
}

#****f* editor.tcl/anyLeave
# NAME
#   anyLeave
# SYNOPSIS
#   anyLeave $c
# FUNCTION
#   This procedure clears the status line.
# INPUTS
#   * c -- tk canvas
#****
proc anyLeave {c} {
    global activetool

    .bottom.textbox config -text ""
    
    $c delete -withtag showCfgPopup
    $c delete -withtag route
}

#****f* editor.tcl/deleteSelection
# NAME
#   deleteSelection -- delete selection
# SYNOPSIS
#   deleteSelection
# FUNCTION
#   By calling this procedure all the selected nodes in imunes will 
#   be deleted.
#****
proc deleteSelection {} {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global changed
    global background 
    global viewid

    if { $oper_mode == "exec" } {
	return
    }

    catch {unset viewid}
    .panwin.f1.c config -cursor watch; update

    foreach lnode [selectedNodes] {
	if { $lnode != "" } {
	    removeGUINode $lnode
	}
	if { [isAnnotation $lnode] } {
	    deleteAnnotation $curcanvas [nodeType $lnode] $lnode
	}
	set changed 1
    }
    raiseAll .panwin.f1.c
    updateUndoLog
    .panwin.f1.c config -cursor left_ptr
    .bottom.textbox config -text ""
}

#****f* editor.tcl/removeIPv4nodes
# NAME
#   removeIPv4nodes -- remove ipv4 nodes
# SYNOPSIS
#   removeIPv4nodes
# FUNCTION
#   Sets all nodes' IPv4 addresses to empty strings.
#****
proc removeIPv4nodes {} {
    global changed
    set nodelist [selectedNodes]

    foreach node $nodelist {
	setStatIPv4routes $node "" 
	foreach ifc [ifcList $node] {
	    setIfcIPv4addr $node $ifc "" 
	}
    }
    redrawAll
    set changed 1
    updateUndoLog
}

#****f* editor.tcl/removeIPv6nodes
# NAME
#   removeIPv6nodes -- remove ipv6 nodes
# SYNOPSIS
#   removeIPv6nodes
# FUNCTION
#   Sets all nodes' IPv6 addresses to empty strings.
#****
proc removeIPv6nodes {} {
    global changed
    set nodelist [selectedNodes]

    foreach node $nodelist {
	setStatIPv6routes $node "" 
	foreach ifc [ifcList $node] {
	    setIfcIPv6addr $node $ifc "" 
	}
    }
    redrawAll
    set changed 1
    updateUndoLog
}

#****f* editor.tcl/changeAddressRange
# NAME
#   changeAddressRange -- change address range
# SYNOPSIS
#   changeAddressRange
# FUNCTION
#   Change address range for selected nodes.
#****
proc changeAddressRange {} {
    global changed changeAddrRange control changeAddressRange
    global copypaste_nodes copypaste_list

    set control 0
    set autorenumber 1
    set changeAddrRange 0
    set changeAddressRange 1

    if { $copypaste_nodes } {
	set selected_nodes $copypaste_list
	set copypaste_nodes 0
    } else {
	set selected_nodes [selectedNodes]
    }
    set link_nodes_selected ""
    set connected_link_layer_nodes ""
    set autorenumber_nodes ""

    #spremanje svih selektiranih link_layer cvorova u listu link_nodes_selected
    foreach node [lsort -dictionary $selected_nodes] {
	if { [[typemodel $node].layer] == "LINK" } {
	    lappend link_nodes_selected $node
	}
    }

    #spremanje svih medjusobno povezanih selektiranih link_layer cvorova kao jedan element liste connected_link_layer_nodes
    foreach link_node $link_nodes_selected {
	set lan_nodes [lsort -dictionary [listLANnodes $link_node {}]]
	if { [lsearch $connected_link_layer_nodes $lan_nodes] == -1 } {
	    lappend connected_link_layer_nodes $lan_nodes
	}
    }

    global autorenumbered_ifcs
    set autorenumbered_ifcs ""

    #dodijeljivanje adresa suceljima spojenima na link_layer cvorove
    foreach element $connected_link_layer_nodes {
	set counter 0
	foreach node $element {
	    set autorenumber_nodes ""
	    foreach ifc [ifcList $node] {
		set peer [peerByIfc $node $ifc]
		if { [[typemodel $peer].layer] != "LINK" && [lsearch $selected_nodes $peer] != -1 } {
		    set peer_ifc [ifcByPeer $peer $node]
		    lappend autorenumber_nodes "$peer $peer_ifc"
		}
	    }
	    foreach el $autorenumber_nodes {
		set n [lindex $el 0]
		set i [lindex $el 1]
		if { $counter == 0 } {
		    set changeAddrRange 1
		}
		autoIPv4addr $n $i
		lappend autorenumbered_ifcs "$n $i"
		incr counter
		set changed 1
		set changeAddrRange 0
	    }
	}
    }

    set autorenumber_nodes ""
    set autorenumber_ifcs ""

    #spremanje svih selektiranih cvorova koji nisu povezani s link_layer cvorom u listu autorenumber_nodes
    foreach node $selected_nodes {
	if { [[typemodel $node].layer] != "LINK" } {
	    foreach ifc [ifcList $node] {
		set peer [peerByIfc $node $ifc]
		if { [[typemodel $peer].layer] != "LINK" && [lsearch $selected_nodes $peer] != -1 } {
		    lappend autorenumber_ifcs "$node $ifc"
		    if { [lsearch $autorenumber_nodes $node] == -1 } {
			lappend autorenumber_nodes $node
		    }
		}
	    }
	}
    }

    #brisanje adresa selektiranih cvorova prije nove dodjele tako da ne bi
    #utjecalo na detekciju postojecih podmreza
    foreach el $autorenumber_ifcs {
	set node [lindex $el 0] 
	set ifc [lindex $el 1]
	setIfcIPv4addr $node $ifc ""
    }

    #dodijeljivanje adresa suceljima koja nisu spojena na link_layer cvorove
    foreach el $autorenumber_ifcs {
	set node [lindex $el 0] 
	set ifc [lindex $el 1]
	set peer [peerByIfc $node $ifc]
	if { [lsearch $autorenumber_nodes $node] < [lsearch $autorenumber_nodes $peer] } {
	    set changeAddrRange 1
	}
	autoIPv4addr $node $ifc
	set changed 1
	set changeAddrRange 0
    }

    set autorenumber 0
    set changeAddressRange 0
    
    foreach node $selected_nodes {
	foreach ifc [ifcList $node] {
	    autoIPv4defaultroute $node $ifc
	}
    }
    
    redrawAll
    updateUndoLog
}

#****f* editor.tcl/changeAddressRange6
# NAME
#   changeAddressRange6 -- change address range (ipv6)
# SYNOPSIS
#   changeAddressRange6
# FUNCTION
#   Change IPv6 address range for selected nodes.
#****
proc changeAddressRange6 {} {
    global changed changeAddrRange6 control changeAddressRange6
    global copypaste_nodes copypaste_list

    set control 0
    set autorenumber 1
    set changeAddrRange6 0
    set changeAddressRange6 1

    if { $copypaste_nodes } {
	set selected_nodes $copypaste_list
	set copypaste_nodes 0
    } else {
	set selected_nodes [selectedNodes]
    }
    set link_nodes_selected ""
    set connected_link_layer_nodes ""
    set autorenumber_nodes ""

    #spremanje svih selektiranih link_layer cvorova u listu link_nodes_selected
    foreach node [lsort -dictionary $selected_nodes] {
	if { [[typemodel $node].layer] == "LINK" } {
	    lappend link_nodes_selected $node
	}
    }

    #spremanje svih medjusobno povezanih selektiranih link_layer cvorova kao jedan element liste connected_link_layer_nodes
    foreach link_node $link_nodes_selected {
	set lan_nodes [lsort -dictionary [listLANnodes $link_node {}]]
	if { [lsearch $connected_link_layer_nodes $lan_nodes] == -1 } {
	    lappend connected_link_layer_nodes $lan_nodes
	}
    }

    global autorenumbered_ifcs6
    set autorenumbered_ifcs6 ""

    #dodijeljivanje adresa suceljima spojenima na link_layer cvorove
    foreach element $connected_link_layer_nodes {
	set counter 0
	foreach node $element {
	    set autorenumber_nodes ""
	    foreach ifc [ifcList $node] {
		set peer [peerByIfc $node $ifc]
		if { [[typemodel $peer].layer] != "LINK" && [lsearch $selected_nodes $peer] != -1 } {
		    set peer_ifc [ifcByPeer $peer $node]
		    lappend autorenumber_nodes "$peer $peer_ifc"
		}
	    }
	    foreach el $autorenumber_nodes {
		set n [lindex $el 0]
		set i [lindex $el 1]
		if { $counter == 0 } {
		    set changeAddrRange6 1
		}
		autoIPv6addr $n $i
		lappend autorenumbered_ifcs6 "$n $i"
		incr counter
		set changed 1
		set changeAddrRange6 0
	    }
	}
    }

    set autorenumber_nodes ""
    set autorenumber_ifcs ""

    #spremanje svih selektiranih cvorova koji nisu povezani s link_layer cvorom u listu autorenumber_nodes
    foreach node $selected_nodes {
	if { [[typemodel $node].layer] != "LINK" } {
	    foreach ifc [ifcList $node] {
		set peer [peerByIfc $node $ifc]
		if { [[typemodel $peer].layer] != "LINK" && [lsearch $selected_nodes $peer] != -1 } {
		    lappend autorenumber_ifcs "$node $ifc"
		    if { [lsearch $autorenumber_nodes $node] == -1 } {
			lappend autorenumber_nodes $node
		    }
		}
	    }
	}
    }

    #brisanje adresa selektiranih cvorova prije nove dodjele tako da ne bi
    #utjecalo na detekciju postojecih podmreza
    foreach el $autorenumber_ifcs {
	set node [lindex $el 0] 
	set ifc [lindex $el 1]
	setIfcIPv6addr $node $ifc ""
    }

    #dodijeljivanje adresa suceljima koja nisu spojena na link_layer cvorove
    foreach el $autorenumber_ifcs {
	set node [lindex $el 0] 
	set ifc [lindex $el 1]
	set peer [peerByIfc $node $ifc]
	if { [lsearch $autorenumber_nodes $node] < [lsearch $autorenumber_nodes $peer] } {
	    set changeAddrRange6 1
	}
	autoIPv6addr $node $ifc
	set changed 1
	set changeAddrRange6 0
    }

    set autorenumber 0
    set changeAddressRange6 0
    
    foreach node $selected_nodes {
	foreach ifc [ifcList $node] {
	    autoIPv6defaultroute $node $ifc
	}
    }
    
    redrawAll
    updateUndoLog
}

#****h* editor.tcl/double1onGrid
# NAME
#  double1onGrid.tcl -- called on Double-1 click on grid (bind command)
# SYNOPSIS
#  double1onGrid $c $x $y
# FUNCTION
#  As grid is layered above annotations this procedure is used to find 
#  annotation object closest to cursor.
# INPUTS
#   * c -- tk canvas
#   * x -- double click x coordinate
#   * y -- double click y coordinate
#****
proc double1onGrid { c x y } {
    set obj [$c find closest $x $y]
    set tags [$c gettags $obj]
    set node [lindex $tags 1]
    if {[lsearch $tags grid] != -1 || [lsearch $tags background] != -1} {
	return
    }
    # Is this really necessary?
    set coords [getNodeCoords $node] 
    set x1 [lindex $coords 0]
    set y1 [lindex $coords 1]
    set x2 [lindex $coords 2]
    set y2 [lindex $coords 3]
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
	# cursor is not ON the closest object
	return
    } else {
	annotationConfig $c $node
    }
}
