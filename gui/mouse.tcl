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

#****f* editor.tcl/removeLinkGUI
# NAME
#   removeLinkGUI -- remove link from GUI
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
proc removeLinkGUI { link_id atomic { keep_ifaces 0 } } {
    global changed

    # this data needs to be fetched before we removeLink
    lassign [getLinkPeers $link_id] node1 node2
    set mirror_link_id [getLinkMirror $link_id]
    if { $mirror_link_id != "" } {
	set mirror_node_id [getNodeMirror $node1]
    }

    # TODO: check this when wlan node turn comes
    if { [getNodeType $node1] == "wlan" || [getNodeType $node2] == "wlan" } {
	removeLink $link_id
	return
    }

    removeLink $link_id $keep_ifaces
    .panwin.f1.c delete $link_id

    if { $mirror_link_id != "" } {
	# remove mirror link from GUI
	.panwin.f1.c delete $mirror_link_id

	# remove pseudo nodes from GUI
	.panwin.f1.c delete $node1
	.panwin.f1.c delete $mirror_node_id
    }

    if { $atomic == "atomic" } {
	set changed 1
	if { $keep_ifaces } {
	    redrawAll
	}

	updateUndoLog
    }
}

#****f* editor.tcl/removeNodeGUI
# NAME
#   removeNodeGUI -- remove node from GUI
# SYNOPSIS
#   renoveGUINode $node_id
# FUNCTION
#   Removes node from GUI. When removing a node from GUI the links
#   connected to that node are also removed.
# INPUTS
#   * node_id -- node id
#****
proc removeNodeGUI { node_id { keep_other_ifaces 0 } } {
    foreach iface [ifcList $node_id] {
	removeLinkGUI [linkByPeers $node_id [getIfcPeer $node_id $iface]] non-atomic $keep_other_ifaces
    }

    removeNode $node_id $keep_other_ifaces
    .panwin.f1.c delete $node_id
}

#****f* editor.tcl/splitLinkGUI
# NAME
#   splitLinkGUI -- splits a link
# SYNOPSIS
#   splitLinkGUI $link_id
# FUNCTION
#   Splits the link and draws new links and new pseudo nodes
#   on the canvas.
# INPUTS
#   * link_id -- link id
#****
proc splitLinkGUI { link_id } {
    global changed

    set zoom [getFromRunning "zoom"]

    lassign [getLinkPeers $link_id] orig_node1 orig_node2
    lassign [splitLink $link_id] new_node1 new_node2

    lassign [getNodeCoords $orig_node1] x1 y1
    lassign [getNodeCoords $orig_node2] x2 y2

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

    set node_id [lindex [$c gettags $obj] 1]
    if { $node_id == "" } {
	return
    }

    $c addtag selected withtag "node && $node_id"
    if { [getNodeType $node_id] == "pseudo" } {
	set bbox [$c bbox "nodelabel && $node_id"]
    } elseif { [getAnnotationType $node_id] == "rectangle" } {
	$c addtag selected withtag "rectangle && $node_id"
	set bbox [$c bbox "rectangle && $node_id"]
    } elseif { [getAnnotationType $node_id] == "text" } {
	$c addtag selected withtag "text && $node_id"
	set bbox [$c bbox "text && $node_id"]
    } elseif { [getAnnotationType $node_id] == "oval" } {
	$c addtag selected withtag "oval && $node_id"
	set bbox [$c bbox "oval && $node_id"]
    } elseif { [getAnnotationType $node_id] == "freeform" } {
	$c addtag selected withtag "freeform && $node_id"
	set bbox [$c bbox "freeform && $node_id"]
    } else {
	set bbox [$c bbox "node && $node_id"]
    }

    if { $bbox == "" } {
	return
    }

    lassign $bbox bx1 by1 bx2 by2
    set bx1 [expr {$bx1 - 2}]
    set by1 [expr {$by1 - 2}]
    set bx2 [expr {$bx2 + 1}]
    set by2 [expr {$by2 + 1}]
    $c delete -withtags "selectmark && $node_id"
    $c create line $bx1 $by1 $bx2 $by1 $bx2 $by2 $bx1 $by2 $bx1 $by1 \
	-dash {6 4} -fill black -width 1 -tags "selectmark $node_id"
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
    foreach node_id $nodelist {
	selectNode .panwin.f1.c [.panwin.f1.c find withtag \
	    "(node || text || oval || rectangle || freeform) && $node_id"]
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
	set node_id [lindex [.panwin.f1.c gettags $obj] 1]
	if { [getNodeMirror $node_id] != "" || [getNodeType $node_id] == "rj45" } {
	    continue
	}
	lappend selected $node_id
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
    set selected [selectedNodes]
    set adjacent {}
    foreach node_id $selected {
	foreach iface [ifcList $node_id] {
	    set peer [getIfcPeer $node_id $iface]
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
    set oper_mode [getFromRunning "oper_mode"]

    set link_id [lindex [$c gettags "link && current"] 1]
    if { $link_id == "" } {
	set link_id [lindex [$c gettags "linklabel && current"] 1]
	if { $link_id == "" } {
	    return
	}
    }

    global linkDirect_$link_id
    set linkDirect_$link_id [getLinkDirect $link_id]

    .button3menu delete 0 end

    #
    # Configure link
    #
    .button3menu add command -label "Configure" \
	-command "linkConfigGUI $c $link_id"

    #
    # Clear link configuration
    #
    .button3menu add command -label "Clear all settings" \
	-command "linkResetConfig $link_id"

    global linkJitterConfiguration
    if  { $linkJitterConfiguration } {
	#
	# Edit link jitter
	#
	.button3menu add command -label "Edit link jitter" \
	    -command "linkJitterConfigGUI $c $link_id"
	#
	# Reset link jitter
	#
	.button3menu add command -label "Clear link jitter" \
	    -command "linkJitterReset $link_id"
    }

    #
    # Toggle direct link
    #
    if { $oper_mode != "exec" } {
	.button3menu add checkbutton -label "Direct link" \
	    -underline 5 -variable linkDirect_$link_id \
	    -command "toggleDirectLink $c $link_id"
    } else {
	.button3menu add checkbutton -label "Direct link" \
	    -underline 5 -variable linkDirect_$link_id \
	    -state disabled
    }

    #
    # Delete link
    #
    if { $oper_mode != "exec" } {
	.button3menu add command -label "Delete" \
	    -command "removeLinkGUI $link_id atomic"
    } else {
	.button3menu add command -label "Delete" \
	    -state disabled
    }

    #
    # Delete link (keep ifaces)
    #
    if { $oper_mode != "exec" } {
	.button3menu add command -label "Delete (keep interfaces)" \
	    -command "removeLinkGUI $link_id atomic 1"
    } else {
	.button3menu add command -label "Delete (keep interfaces)" \
	    -state disabled
    }

    #
    # Split link
    #
    if { $oper_mode != "exec" && [getLinkMirror $link_id] == "" } {
	.button3menu add command -label "Split" \
	    -command "splitLinkGUI $link_id"
    } else {
	.button3menu add command -label "Split" \
	    -state disabled
    }

    #
    # Merge two pseudo nodes / links
    #
    set link_mirror_id [getLinkMirror $link_id]
    if { $oper_mode != "exec" && $link_mirror_id != "" &&
	[getNodeCanvas [lindex [getLinkPeers $link_mirror_id] 0]] ==
	[getFromRunning "curcanvas"] } {

	.button3menu add command -label "Merge" \
	    -command "mergeNodeGUI [lindex [getLinkPeers $link_id] 0]"
    } else {
	.button3menu add command -label "Merge" -state disabled
    }

    set x [winfo pointerx .]
    set y [winfo pointery .]
    tk_popup .button3menu $x $y
}

#****f* editor.tcl/moveToCanvas
# NAME
#   moveToCanvas -- move to canvas
# SYNOPSIS
#   moveToCanvas $canvas_id
# FUNCTION
#   This procedure moves all the nodes selected in the GUI to
#   the specified canvas.
# INPUTS
#   * canvas_id -- canvas id.
#****
proc moveToCanvas { canvas_id } {
    global changed

    set selected_nodes [selectedNodes]
    foreach node_id $selected_nodes {
	setNodeCanvas $node_id $canvas_id
	set changed 1
    }

    foreach obj [.panwin.f1.c find withtag "linklabel"] {
	set link_id [lindex [.panwin.f1.c gettags $obj] 1]

	lassign [getLinkPeers $link_id] peer1 peer2
	if { ($peer1 ni $selected_nodes && $peer2 in $selected_nodes) ||
	    ($peer1 in $selected_nodes && $peer2 ni $selected_nodes) } {

	    # pseudo nodes are always peer1
	    if { [getNodeType $peer1] == "pseudo" } {
		setNodeCanvas $peer1 $canvas_id
		if { [getNodeCanvas [getNodeMirror $peer1]] == $canvas_id } {
		    mergeLink $link_id
		}
		continue
	    }

	    lassign [splitLink $link_id] new_node1 new_node2

	    setNodeName $new_node1 $peer2
	    setNodeName $new_node2 $peer1
	}
    }

    updateUndoLog
    redrawAll
}

#****f* editor.tcl/mergeNodeGUI
# NAME
#   mergeNodeGUI -- merge GUI node
# SYNOPSIS
#   mergeNodeGUI $node_id
# FUNCTION
#   This procedure removes the specified pseudo node as well
#   as it's mirror copy. Also this procedure removes the
#   pseudo links and reestablish the original link between
#   the non-pseudo nodes.
# INPUTS
#   * node_id -- node id of a pseudo node.
#****
proc mergeNodeGUI { node_id } {
    global changed

    mergeLink [getIfcLink $node_id "ifc0"]

    set changed 1
    updateUndoLog
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

    set canvas_list [getFromRunning "canvas_list"]
    set curcanvas [getFromRunning "curcanvas"]
    set oper_mode [getFromRunning "oper_mode"]

    set node_id [lindex [$c gettags "node && current"] 1]
    if { $node_id == "" } {
	set node_id [lindex [$c gettags "nodelabel && current"] 1]
	if { $node_id == "" } {
	    return
	}
    }

    set type [getNodeType $node_id]
    set mirror_node [getNodeMirror $node_id]

    if { [$c gettags "node && $node_id && selected"] == "" } {
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
	    -command "nodeConfigGUI $c $node_id"
    } else {
	.button3menu add command -label "Configure" \
	    -command "nodeConfigGUI $c $node_id" -state disabled
    }

    #
    # Transform
    #
    .button3menu.transform delete 0 end
    if { $oper_mode != "exec" && $type in "router pc host" } {
	.button3menu add cascade -label "Transform to" \
	    -menu .button3menu.transform
	.button3menu.transform add command -label "Router" \
	    -command "transformNodesGUI \"[selectedRealNodes]\" router"
	.button3menu.transform add command -label "PC" \
	    -command "transformNodesGUI \"[selectedRealNodes]\" pc"
	.button3menu.transform add command -label "Host" \
	    -command "transformNodesGUI \"[selectedRealNodes]\" host"
    }

    #
    # Node icon preferences
    #
    .button3menu.icon delete 0 end
    if { $oper_mode == "edit" && $type != "pseudo" } {
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
    if { $oper_mode == "edit" && $type != "pseudo" } {
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
	-command "Kb $node_id \[lsearch -all -inline -not -exact \
	\[selectedRealNodes\] $node_id\]"
    .button3menu.connect.selected add command \
	-label "Cycle" -command "C \[selectedRealNodes\]"
    .button3menu.connect.selected add command \
	-label "Clique" -command "K \[selectedRealNodes\]"
    .button3menu.connect.selected add command \
	-label "Random" -command "R \[selectedRealNodes\] \
	\[expr \[llength \[selectedRealNodes\]\] - 1\]"
    .button3menu.connect add separator

    foreach canvas_id $canvas_list {
	destroy .button3menu.connect.$canvas_id
	menu .button3menu.connect.$canvas_id -tearoff 0
	.button3menu.connect add cascade -label [getCanvasName $canvas_id] \
	    -menu .button3menu.connect.$canvas_id
    }

    foreach peer_node [getFromRunning "node_list"] {
	set canvas_id [getNodeCanvas $peer_node]
	if { $node_id == $peer_node } {
	    .button3menu.connect.$canvas_id add command \
		-label [getNodeName $peer_node] \
		-command "newLinkGUI $node_id $node_id"
	} elseif { [getNodeType $peer_node] != "pseudo" } {
	    .button3menu.connect.$canvas_id add command \
		-label [getNodeName $peer_node] \
		-command "connectWithNode \"[selectedRealNodes]\" $peer_node"
	}
    }

    #
    # Connect interface - can be between different canvases
    #
    .button3menu.connect_iface delete 0 end
    if { $oper_mode == "edit" && $type != "pseudo" } {
	.button3menu add cascade -label "Connect interface" \
	    -menu .button3menu.connect_iface
    }

    foreach this_iface_id [concat "new_iface" [ifcList $node_id]] {
	if { [getIfcLink $node_id $this_iface_id] != "" } {
	    continue
	}

	set from_iface_id $this_iface_id
	set from_iface_label [getIfcName $node_id $this_iface_id]
	if { $this_iface_id == "new_iface" } {
	    set from_iface_id {}
	    set from_iface_label "Create new interface"
	}

	destroy .button3menu.connect_iface.$this_iface_id
	menu .button3menu.connect_iface.$this_iface_id -tearoff 0
	.button3menu.connect_iface add cascade -label $from_iface_label \
	    -menu .button3menu.connect_iface.$this_iface_id

	foreach canvas_id $canvas_list {
	    destroy .button3menu.connect_iface.$this_iface_id.$canvas_id
	    menu .button3menu.connect_iface.$this_iface_id.$canvas_id -tearoff 0
	    .button3menu.connect_iface.$this_iface_id add cascade -label [getCanvasName $canvas_id] \
		-menu .button3menu.connect_iface.$this_iface_id.$canvas_id
	}

	foreach peer_node_id [getFromRunning "node_list"] {
	    set canvas_id [getNodeCanvas $peer_node_id]
	    if { [getNodeType $peer_node_id] != "pseudo" } {
		destroy .button3menu.connect_iface.$this_iface_id.$canvas_id.$peer_node_id
		menu .button3menu.connect_iface.$this_iface_id.$canvas_id.$peer_node_id -tearoff 0
		.button3menu.connect_iface.$this_iface_id.$canvas_id add cascade -label [getNodeName $peer_node_id] \
		    -menu .button3menu.connect_iface.$this_iface_id.$canvas_id.$peer_node_id

		foreach other_iface_id [concat "new_peer_iface" [ifcList $peer_node_id]] {
		    if { $node_id == $peer_node_id && $this_iface_id == $other_iface_id } {
			continue
		    }

		    if { [getIfcLink $peer_node_id $other_iface_id] != "" } {
			continue
		    }

		    set to_iface_id $other_iface_id
		    set to_iface_label [getIfcName $peer_node_id $other_iface_id]
		    if { $other_iface_id == "new_peer_iface" } {
			set to_iface_id {}
			set to_iface_label "Create new interface"
		    }

		    .button3menu.connect_iface.$this_iface_id.$canvas_id.$peer_node_id add command \
			-label $to_iface_label \
			-command "newLinkWithIfacesGUI $node_id \"$from_iface_id\" $peer_node_id \"$to_iface_id\""
		}
	    }
	}
    }

    #
    # Move to another canvas
    #
    .button3menu.moveto delete 0 end
    if { $oper_mode == "edit" && $type != "pseudo" } {
	.button3menu add cascade -label "Move to" \
	    -menu .button3menu.moveto
	.button3menu.moveto add command -label "Canvas:" -state disabled

	foreach canvas_id $canvas_list {
	    if { $canvas_id != $curcanvas } {
		.button3menu.moveto add command \
		    -label [getCanvasName $canvas_id] \
		    -command "moveToCanvas $canvas_id"
	    } else {
		.button3menu.moveto add command \
		    -label [getCanvasName $canvas_id] -state disabled
	    }
	}
    }

    #
    # Merge two pseudo nodes / links
    #
    if { $oper_mode != "exec" && $type == "pseudo" && \
	[getNodeCanvas $mirror_node] == $curcanvas } {
	.button3menu add command -label "Merge" \
	    -command "mergeNodeGUI $node_id"
    }

    #
    # Delete selection
    #
    if { $oper_mode != "exec" } {
	.button3menu add command -label "Delete" -command "deleteSelection"
    }

    #
    # Delete selection (keep linked interfaces)
    #
    if { $oper_mode != "exec" } {
	.button3menu add command -label "Delete (keep interfaces)" -command "deleteSelection 1"
    }

    if { $type != "pseudo" } {
	.button3menu add separator
    }

    #
    # Start & stop node
    #
    if { $oper_mode == "exec" && [info procs [getNodeType $node_id].start] != "" \
	&& [info procs [getNodeType $node_id].shutdown] != ""} {

	.button3menu add command -label Start \
	    -command "startNodeFromMenu $node_id"
	.button3menu add command -label Stop \
	    -command "stopNodeFromMenu $node_id"
	.button3menu add command -label Restart \
	    -command "stopNodeFromMenu $node_id; \
	     startNodeFromMenu $node_id"
    }

    #
    # Services menu
    #
    .button3menu.services delete 0 end
    if { $oper_mode == "exec" && [[getNodeType $node_id].virtlayer] == "VIMAGE" && $type != "ext" } {
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
		    -command "$service.[string tolower $action] $node_id"
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
    }

    if { $oper_mode == "exec" } {
	.button3menu.sett add command -label "Import Running Configuration" \
	    -command "fetchNodeConfiguration"
    } else {
	.button3menu.sett add command -label "Remove IPv4 addresses" \
	    -command "removeIPv4nodes"
        .button3menu.sett add command -label "Remove IPv6 addresses" \
	    -command "removeIPv6nodes"
    }

    #
    # IPv4 autorenumber
    #
    if { $oper_mode == "edit" && [[getNodeType $node_id].netlayer] != "LINK" \
	&& $type != "pseudo" } {

	.button3menu add command -label "IPv4 autorenumber" -command {
	    global IPv4autoAssign

	    set tmp $IPv4autoAssign
	    set IPv4autoAssign 1
	    changeAddressRange
	    set IPv4autoAssign $tmp
	}
    }

    #
    # IPv6 autorenumber
    #
    if { $oper_mode == "edit" && [[getNodeType $node_id].netlayer] != "LINK" \
	&& $type != "pseudo" } {

	.button3menu add command -label "IPv6 autorenumber" -command {
	    global IPv6autoAssign

	    set tmp $IPv6autoAssign
	    set IPv6autoAssign 1
	    changeAddressRange6
	    set IPv6autoAssign $tmp
	}
    }

    #
    # Shell selection
    #
    .button3menu.shell delete 0 end
    if { $type != "ext" && $oper_mode == "exec" && [[getNodeType $node_id].virtlayer] == "VIMAGE" } {
	.button3menu add separator
	.button3menu add cascade -label "Shell window" \
	    -menu .button3menu.shell
	foreach cmd [existingShells [[getNodeType $node_id].shellcmds] $node_id] {
	    .button3menu.shell add command -label "[lindex [split $cmd /] end]" \
		-command "spawnShell $node_id $cmd"
	}
    }

    .button3menu.wireshark delete 0 end
    .button3menu.tcpdump delete 0 end
    if { $oper_mode == "exec" && $type == "ext" } {
	.button3menu add separator

	#
	# Wireshark
	#
        set wireshark_command ""
        foreach wireshark "wireshark wireshark-gtk wireshark-qt" {
            if { [checkForExternalApps $wireshark] == 0 } {
                set wireshark_command $wireshark
                break
            }
        }

        if { $wireshark_command != "" } {
	    .button3menu add command -label "Wireshark" \
		-command "captureOnExtIfc $node_id $wireshark_command"
	}

	#
	# tcpdump
	#
	if { [checkForExternalApps "tcpdump"] == 0 } {
	    .button3menu add command -label "tcpdump" \
		-command "captureOnExtIfc $node_id tcpdump"
	}
    } elseif { $oper_mode == "exec" && [[getNodeType $node_id].virtlayer] == "VIMAGE" } {
	#
	# Wireshark
	#
	.button3menu add cascade -label "Wireshark" \
	    -menu .button3menu.wireshark
	if { [llength [allIfcList $node_id]] == 0 } {
	    .button3menu.wireshark add command -label "No interfaces available."
	} else {
	    foreach iface [allIfcList $node_id] {
		set label "$iface"
		if { [getIfcIPv4addr $node_id $iface] != "" } {
		    set label "$label ([getIfcIPv4addr $node_id $iface])"
		}
		if { [getIfcIPv6addr $node_id $iface] != "" } {
		    set label "$label ([getIfcIPv6addr $node_id $iface])"
		}
		.button3menu.wireshark add command -label $label \
		    -command "startWiresharkOnNodeIfc $node_id $iface"
	    }
	}

	#
	# tcpdump
	#
	.button3menu add cascade -label "tcpdump" \
	    -menu .button3menu.tcpdump
	if { [llength [allIfcList $node_id]] == 0 } {
	    .button3menu.tcpdump add command -label "No interfaces available."
	} else {
	    foreach iface [allIfcList $node_id] {
		set label "$iface"
		if { [getIfcIPv4addr $node_id $iface] != "" } {
		    set label "$label ([getIfcIPv4addr $node_id $iface])"
		}
		if { [getIfcIPv6addr $node_id $iface] != "" } {
		    set label "$label ([getIfcIPv6addr $node_id $iface])"
		}
		.button3menu.tcpdump add command -label $label \
		    -command "startTcpdumpOnNodeIfc $node_id $iface"
	    }
	}

	#
	# Firefox
	#
	if { [checkForExternalApps "startxcmd"] == 0 && \
	    [checkForApplications $node_id "firefox"] == 0 } {

	    .button3menu add command -label "Web Browser" \
		-command "startXappOnNode $node_id \"firefox -no-remote -setDefaultBrowser about:blank\""
	} else {
	    .button3menu add command -label "Web Browser" -state disabled
	}

	#
	# Sylpheed mail client
	#
	if { [checkForExternalApps "startxcmd"] == 0 && \
	    [checkForApplications $node_id "sylpheed"] == 0 } {

	    .button3menu add command -label "Mail client" \
		-command "startXappOnNode $node_id \"G_FILENAME_ENCODING=UTF-8 sylpheed\""
	} else {
	    .button3menu add command -label "Mail client" -state disabled
	}
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
    global activetool newlink curobj changed def_router_model
    global router pc host lanswitch frswitch rj45 hub
    global oval rectangle text freeform newtext
    global lastX lastY
    global background selectbox
    global defLinkColor defLinkWidth
    global resizemode resizeobj

    set zoom [getFromRunning "zoom"]

    set x [$c canvasx $x]
    set y [$c canvasy $y]

    set lastX $x
    set lastY $y

    set curobj [$c find withtag current]
    set curtype [lindex [$c gettags current] 0]
    if { $curtype in "node oval rectangle text freeform" || ( $curtype == "nodelabel" &&
	 [getNodeType [lindex [$c gettags $curobj] 1]] == "pseudo") } {

	set node_id [lindex [$c gettags current] 1]
	set wasselected \
	    [expr {[lsearch [$c find withtag "selected"] \
	    [$c find withtag "(node || text || freeform || rectangle || oval) && $node_id"]] > -1}]

	if { $button == "ctrl" } {
	    if { $wasselected } {
		$c dtag $node_id selected
		$c delete -withtags "selectmark && $node_id"
	    }
	} elseif { ! $wasselected } {
	    foreach node_type "node text oval rectangle freeform" {
		$c dtag $node_type selected
	    }
	    $c delete -withtags selectmark
	}

	if { $activetool == "select" && ! $wasselected } {
	    selectNode $c $curobj
	}
    } elseif { $curtype == "selectmark" } {
	set t1 [$c gettags current]
	set o1 [lindex $t1 1]
	set type1 [getNodeType $o1]

	if { $type1 == "oval" || $type1 == "rectangle" } {
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

	    if { $l == 1 } {
		if { $u == 1 } {
		    set resizemode lu
		} elseif { $d == 1 } {
		    set resizemode ld
		} else {
		    set resizemode l
		}
	    } elseif { $r == 1 } {
		if { $u == 1 } {
		    set resizemode ru
		} elseif { $d == 1 } {
		    set resizemode rd
		} else {
		    set resizemode r
		}
	    } elseif { $u == 1 } {
		set resizemode u
	    } elseif { $d == 1 } {
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
    set object_drawable 0
    foreach type {background grid rectangle oval freeform text} {
	if { $type in [.panwin.f1.c gettags $curobj] } {
	    set object_drawable 1
	    break
	}
    }

    if { $object_drawable } {
	if { $activetool ni "select link oval rectangle text freeform" } {
	    # adding a new node
	    set node_id [newNode $activetool]
	    setNodeCanvas $node_id [getFromRunning "curcanvas"]
	    setNodeCoords $node_id "[expr {$x / $zoom}] [expr {$y / $zoom}]"

	    # To calculate label distance we take into account the normal icon
	    # height
	    global $activetool\_iconheight

	    set dy [expr [set $activetool\_iconheight]/2 + 11]
	    setNodeLabelCoords $node_id "[expr {$x / $zoom}] \
		[expr {$y / $zoom + $dy}]"

	    drawNode $node_id
	    selectNode $c [$c find withtag "node && $node_id"]
	    set changed 1
	} elseif { $activetool == "select" \
	    && $curtype != "node" && $curtype != "nodelabel" } {

	    $c config -cursor cross
	    set lastX $x
	    set lastY $y
	    if { $selectbox != "" } {
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
	if { $curtype in "node nodelabel text oval rectangle freeform" } {
	    $c config -cursor fleur
	}

	if { $activetool == "link" && $curtype == "node" } {
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
    if { $activetool == "link" && $newlink != "" } {
	#creating a new link
	$c coords $newlink $lastX $lastY $x $y
    } elseif { $activetool == "select" && $curtype == "nodelabel" \
	&& [getNodeType [lindex [$c gettags $curobj] 1]] != "pseudo" } {

	$c move $curobj [expr {$x - $lastX}] [expr {$y - $lastY}]
	set changed 1
	set lastX $x
	set lastY $y
    } elseif { $activetool == "select" && $curobj == "" && $curtype == "" } {
	return
    } elseif { $activetool == "select" &&
	( $curobj == $selectbox || $curtype == "background" ||
	$curtype == "grid" || ($curobj ni [$c find withtag "selected"] &&
	$curtype != "selectmark") && [getNodeType [lindex [$c gettags $curobj] 1]] != "pseudo") } {

	#forming the selectbox and resizing
	if { $selectbox == "" } {
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
    # actually we should check if curobj == bkgImage
    } elseif { $activetool == "oval" && ( $curobj == $newoval \
	|| $curobj == $background || $curtype == "background" \
	|| $curtype == "grid") } {

	# Draw a new oval
	if { $newoval == "" } {
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
	|| $curtype == "oval" || $curtype == "grid") } {

	# Draw a new rectangle
	if { $newrect == "" } {
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
	|| $curtype == "grid") } {

	# Draw a new freeform
	if { $newfree == "" } {
	    set newfree [$c create line $lastX $lastY $x $y \
		-fill blue -width 2 -tags "newfree"]
	    $c raise $newfree "oval || rectangle || background || link || linklabel || interface"
	} else {
	    xpos $newfree $x $y 2 blue
	}
    } elseif { $curtype == "selectmark" } {
	foreach o [$c find withtag "selected"] {
	    set node_id [lindex [$c gettags $o] 1]

	    lassign [getNodeCoords $node_id] oldX1 oldY1 oldX2 oldY2
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
	    if { $selectbox == "" } {
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

	    set node_id [lindex [$c gettags $img] 1]

	    foreach elem { "selectmark" "nodelabel" "link"} {
		set obj [$c find withtag "$elem && $node_id"]
		$c move $obj [expr {$x - $lastX}] [expr {$y - $lastY}]

		if { $elem == "link" } {
		    $c addtag need_redraw withtag "link && $node_id"
		}
	    }
	}

	foreach link_id [$c find withtag "link && need_redraw"] {
	    redrawLink [lindex [$c gettags $link_id] 1]
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
    global activetool newlink curobj grid
    global changed selectbox
    global lastX lastY sizex sizey
    global autorearrange_enabled
    global resizemode resizeobj

    set zoom [getFromRunning "zoom"]
    set undolevel [getFromRunning "undolevel"]
    set redolevel [getFromRunning "redolevel"]

    set redrawNeeded 0

    set outofbounds 0

    set x [$c canvasx $x]
    set y [$c canvasy $y]

    $c config -cursor left_ptr
    # if the link tool is active and we are creating a new link
    if { $activetool == "link" && $newlink != "" } {
	$c delete $newlink
	set newlink ""
	set destobj ""

	# find the node that is under the cursor
	foreach obj [$c find overlapping $x $y $x $y] {
	    if { [lindex [$c gettags $obj] 0] == "node" } {
		set destobj $obj
		break
	    }
	}

	# if there is an object beneath the cursor and an object was
	# selected by the button1 procedure create a link between nodes
	if { $destobj != "" && $curobj != "" && $destobj != $curobj } {
	    set lnode1 [lindex [$c gettags $curobj] 1]
	    set lnode2 [lindex [$c gettags $destobj] 1]
	    set link_id [newLink $lnode1 $lnode2]
	    if { $link_id != "" } {
		drawLink $link_id
		redrawLink $link_id
		updateLinkLabel $link_id
		set changed 1
	    }
	}
    } elseif { $activetool in "rectangle oval text freeform" } {
	popupAnnotationDialog $c 0 "false"
    }

    if { $changed == 1 } {
	set regular true

	# selects the node whose label was moved
	if { [lindex [$c gettags $curobj] 0] == "nodelabel" } {
	    set node_id [lindex [$c gettags $curobj] 1]
	    selectNode $c [$c find withtag "node && $node_id"]
	}

	set selected {}
	foreach img [$c find withtag "selected"] {
	    set node_id [lindex [$c gettags $img] 1]
	    lappend selected $node_id
	    set coords [$c coords $img]
	    set x [expr {[lindex $coords 0] / $zoom}]
	    set y [expr {[lindex $coords 1] / $zoom}]

	    # only nodes are snapped to grid, annotations are not
	    if { $autorearrange_enabled == 0 && \
		[$c find withtag "node && $node_id"] != ""  } {

		set dx [expr {(int($x / $grid + 0.5) * $grid - $x) * $zoom}]
		set dy [expr {(int($y / $grid + 0.5) * $grid - $y) * $zoom}]
		$c move $img $dx $dy

		set coords [$c coords $img]
		set x [expr {[lindex $coords 0] / $zoom}]
		set y [expr {[lindex $coords 1] / $zoom}]
		setNodeCoords $node_id "$x $y"

		#moving the nodelabel assigned to the moving node
		$c move "nodelabel && $node_id" $dx $dy
		set coords [$c coords "nodelabel && $node_id"]
		set x [expr {[lindex $coords 0] / $zoom}]
		set y [expr {[lindex $coords 1] / $zoom}]
		setNodeLabelCoords $node_id "$x $y"
		if { $x < 0 || $y < 0 || $x > $sizex || $y > $sizey } {
		    set regular false
		}
	    } else {
		set dx 0
		set dy 0
	    }

	    if { [lindex [$c gettags $node_id] 0] == "oval"} {
		lassign [$c coords [lindex [$c gettags $node_id] 1]] x1 y1 x2 y2
		set x1 [expr {$x1 / $zoom}]
		set y1 [expr {$y1 / $zoom}]
		set x2 [expr {$x2 / $zoom}]
		set y2 [expr {$y2 / $zoom}]
		if { $x1 < 0 } {
		    set x2 [expr {$x2-$x1}]
		    set x1 0
		    set outofbounds 1
		}
		if { $y1 < 0 } {
		    set y2 [expr {$y2-$y1}]
		    set y1 0
		    set outofbounds 1
		}
		if { $x2 > $sizex } {
		    set x1 [expr {$x1-($x2-$sizex)}]
		    set x2 $sizex
		    set outofbounds 1
		}
		if { $y2 > $sizey } {
		    set y1 [expr {$y1-($y2-$sizey)}]
		    set y2 $sizey
		    set outofbounds 1
		}

		setAnnotationCoords $node_id "$x1 $y1 $x2 $y2"
	    }

	    if { [lindex [$c gettags $node_id] 0] == "rectangle" } {
		set coordinates [$c coords [lindex [$c gettags $node_id] 1]]
		set x1 [expr {[lindex $coordinates 0] / $zoom}]
		set y1 [expr {[lindex $coordinates 1] / $zoom}]
		set x2 [expr {[lindex $coordinates 6] / $zoom}]
		set y2 [expr {[lindex $coordinates 13] / $zoom}]
		if { $x1 < 0 } {
		    set x2 [expr {$x2-$x1}]
		    set x1 0
		    set outofbounds 1
		}
		if { $y1 < 0 } {
		    set y2 [expr {$y2-$y1}]
		    set y1 0
		    set outofbounds 1
		}
		if { $x2 > $sizex } {
		    set x1 [expr {$x1-($x2-$sizex)}]
		    set x2 $sizex
		    set outofbounds 1
		}
		if { $y2 > $sizey } {
		    set y1 [expr {$y1-($y2-$sizey)}]
		    set y2 $sizey
		    set outofbounds 1
		}

		setAnnotationCoords $node_id "$x1 $y1 $x2 $y2"
	    }

	    if { [lindex [$c gettags $node_id] 0] == "freeform"} {
		lassign [$c bbox "selectmark && $node_id"] x1 y1 x2 y2
		set x1 [expr {$x1 / $zoom}]
		set y1 [expr {$y1 / $zoom}]
		set x2 [expr {$x2 / $zoom}]
		set y2 [expr {$y2 / $zoom}]
		set shiftx 0
		set shifty 0

		if { $x1 < 0 } {
		    set shiftx -$x1
		    set outofbounds 1
		}
		if { $y1 < 0 } {
		    set shifty -$y1
		    set outofbounds 1
		}
		if { $x2 > $sizex } {
		    set shiftx [expr $sizex-$x2]
		    set outofbounds 1
		}
		if { $y2 > $sizey } {
		    set shifty [expr $sizey-$y2]
		    set outofbounds 1
		}

		set coordinates [$c coords [lindex [$c gettags $node_id] 1]]
                set l [expr {[llength $coordinates]-1}]
                set newcoords {}
                set i 0

		while { $i <= $l } {
                    set f1 [expr {[lindex $coords $i] * $zoom}]
                    set g1 [expr {[lindex $coords $i+1] * $zoom}]
                    set xx1 [expr $f1+$shiftx]
                    set yy1 [expr $g1+$shifty]

                    lappend newcoords $xx1 $yy1
                    set i [expr {$i+2}]
                }

                setAnnotationCoords $node_id $newcoords
	    }

	    if { [lindex [$c gettags $node_id] 0] == "text"} {
		set bbox [$c bbox "selectmark && $node_id"]
		lassign [$c coords [lindex [$c gettags $node_id] 1]] x1 y1
		set width [expr [lindex $bbox 2] - [lindex $bbox 0]]
		set height [expr [lindex $bbox 3] - [lindex $bbox 1]]

		if { [lindex $bbox 0] < 0 } {
		    set x1 5
		    set outofbounds 1
		}
		if { [lindex $bbox 1] < 0 } {
		    set y1 [expr $height/2]
		    set outofbounds 1
		}
		if { [lindex $bbox 2] > $sizex } {
		    set x1 [expr $sizex-$width+5]
		    set outofbounds 1
		}
		if { [lindex $bbox 3] > $sizey } {
		    set y1 [expr {$sizey-$height/2}]
		    set outofbounds 1
		}

		setAnnotationCoords $node_id "$x1 $y1"
	    }

	    $c move "selectmark && $node_id" $dx $dy
	    $c addtag need_redraw withtag "link && $node_id"
	    set changed 1
	} ;# end of: foreach img selected

	if { $outofbounds } {
	    redrawAll
	    if { $activetool == "select" } {
		selectNodes $selected
	    }
	}

	if { $regular == "true" } {
	    foreach link_id [$c find withtag "link && need_redraw"] {
		redrawLink [lindex [$c gettags $link_id] 1]
                updateLinkLabel [lindex [$c gettags $link_id] 1]
	    }
	} else {
	    .panwin.f1.c config -cursor watch

	    jumpToUndoLevel $undolevel
	    redrawAll

	    if { $activetool == "select" } {
		selectNodes $selected
	    }

	    set changed 0
	}
	$c dtag link need_redraw
    # $changed!=1
    } elseif { $activetool == "select" } {
	if { $selectbox == "" } {
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

	    catch { $c find enclosed $x $y $x1 $y1 } enc_objs
	    foreach obj $enc_objs {
		set tags [$c gettags $obj]
		if { [lindex $tags 0] == "node" && [lsearch $tags selected] == -1 } {
		    lappend enclosed $obj
		}
		if { [lindex $tags 0] == "oval" && [lsearch $tags selected] == -1 } {
		    lappend enclosed $obj
		}
		if { [lindex $tags 0] == "rectangle" && [lsearch $tags selected] == -1 } {
		    lappend enclosed $obj
		}
		if { [lindex $tags 0] == "text" && [lsearch $tags selected] == -1 } {
		    lappend enclosed $obj
		}
		if { [lindex $tags 0] == "freeform" && [lsearch $tags selected] == -1 } {
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
    global show_background_images changed

    set canvas_list [getFromRunning "canvas_list"]
    set curcanvas [getFromRunning "curcanvas"]

    .button3menu delete 0 end

    #
    # Show canvas background
    #
    .button3menu add checkbutton -label "Show background" \
    -underline 5 -variable show_background_images \
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
	set curcanvas_size [getCanvasSize $curcanvas]
	set othercanvsize [getCanvasSize $c]
	if {$curcanvas != $c && $curcanvas_size == $othercanvsize} {
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

    foreach node_id $nodelist {
	set icon [getCustomIcon $node_id]
	removeCustomIcon $node_id
	removeImageReference $icon $node_id
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

    set node_id [lindex [$c gettags current] 1]
    set err [catch {getNodeType $node_id} error]
    if { $err != 0 } {
	return
    }

    set type [getNodeType $node_id]
    set name [getNodeName $node_id]
    set model [getNodeModel $node_id]
    if { $model != "" } {
	set line "{$node_id} $name ($model):"
    } else {
	set line "{$node_id} $name:"
    }
    if { $type != "rj45" } {
	foreach iface [ifcList $node_id] {
	    set line "$line [getIfcName $node_id $iface]:[getIfcIPv4addr $node_id $iface]"
	}
    }
    .bottom.textbox config -text "$line"

    showCfg $c $node_id
    showRoute $c $node_id
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
proc linkEnter { c } {
    global activetool

    set link_id [lindex [$c gettags current] 1]
    if { [lsearch [getFromRunning "link_list"] $link_id] == -1 } {
	return
    }
    set line "$link_id: [getLinkBandwidthString $link_id] [getLinkDelayString $link_id]"
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
proc anyLeave { c } {
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
proc deleteSelection { { keep_other_ifaces 0 } } {
    global changed
    global background
    global viewid

    if { [getFromRunning "oper_mode"] == "exec" } {
	return
    }

    catch { unset viewid }
    .panwin.f1.c config -cursor watch; update

    foreach lnode [selectedNodes] {
	if { $lnode != "" } {
	    removeNodeGUI $lnode $keep_other_ifaces
	}

	set type [getAnnotationType $lnode]
	if { $type != "" } {
	    deleteAnnotation $lnode $type
	}
	set changed 1
    }

    if { $changed } {
	raiseAll .panwin.f1.c
	updateUndoLog
	redrawAll
    }

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

    foreach node_id [selectedNodes] {
	setStatIPv4routes $node_id ""
	foreach iface [ifcList $node_id] {
	    setIfcIPv4addrs $node_id $iface ""
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

    foreach node_id [selectedNodes] {
	setStatIPv6routes $node_id ""
	foreach iface [ifcList $node_id] {
	    setIfcIPv6addrs $node_id $iface ""
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
# TODO: merge this with auto default gateway procedures?
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

    # all L2 nodes are saved in link_nodes_selected list
    foreach node_id [lsort -dictionary $selected_nodes] {
	if { [[getNodeType $node_id].netlayer] == "LINK" } {
	    lappend link_nodes_selected $node_id
	}
    }

    # all L2 nodes from the same subnet are saved as one element of connected_link_layer_nodes list
    foreach link_node $link_nodes_selected {
	set lan_nodes [lsort -dictionary [listLANNodes $link_node {}]]
	if { [lsearch $connected_link_layer_nodes $lan_nodes] == -1 } {
	    lappend connected_link_layer_nodes $lan_nodes
	}
    }

    global autorenumbered_ifcs
    set autorenumbered_ifcs ""

    # assign addresses to nodes connected to L2 nodes
    foreach element $connected_link_layer_nodes {
	set counter 0
	foreach node_id $element {
	    set autorenumber_nodes ""
	    foreach iface [ifcList $node_id] {
		lassign [logicalPeerByIfc $node_id $iface] peer peer_iface
		if { $peer != "" && [[getNodeType $peer].netlayer] != "LINK" && $peer in $selected_nodes } {
		    lappend autorenumber_nodes "$peer $peer_iface"
		}
	    }

	    foreach el $autorenumber_nodes {
		lassign $el node_id iface
		if { $counter == 0 } {
		    set changeAddrRange 1
		}

		autoIPv4addr $node_id $iface
		lappend autorenumbered_ifcs "$node_id $iface"
		incr counter
		set changed 1
		set changeAddrRange 0
	    }
	}
    }

    set autorenumber_nodes ""
    set autorenumber_ifcs ""

    # save nodes not connected to the L2 node in the autorenumber_nodes list
    foreach node_id $selected_nodes {
	if { [[getNodeType $node_id].netlayer] != "LINK" } {
	    foreach iface [ifcList $node_id] {
		lassign [logicalPeerByIfc $node_id $iface] peer peer_iface
		if { $peer != "" && [[getNodeType $peer].netlayer] != "LINK" && $peer in $selected_nodes } {
		    lappend autorenumber_ifcs "$node_id $iface"
		    if { [lsearch $autorenumber_nodes $node_id] == -1 } {
			lappend autorenumber_nodes $node_id
		    }
		}
	    }
	}
    }

    # delete the existing IP addresses
    foreach el $autorenumber_ifcs {
	lassign $el node_id iface
	setIfcIPv4addrs $node_id $iface ""
    }

    # assign IP addresses to interfaces not connected to L2 nodes
    foreach el $autorenumber_ifcs {
	lassign $el node_id iface
	lassign [logicalPeerByIfc $node_id $iface] peer peer_iface
	if { [lsearch $autorenumber_nodes $node_id] < [lsearch $autorenumber_nodes $peer] } {
	    set changeAddrRange 1
	}

	autoIPv4addr $node_id $iface
	set changed 1
	set changeAddrRange 0
    }

    set autorenumber 0
    set changeAddressRange 0

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
# TODO: merge this with auto default gateway procedures?
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

    # all L2 nodes are saved in link_nodes_selected list
    foreach node_id [lsort -dictionary $selected_nodes] {
	if { [[getNodeType $node_id].netlayer] == "LINK" } {
	    lappend link_nodes_selected $node_id
	}
    }

    # all L2 nodes from the same subnet are saved as one element of connected_link_layer_nodes list
    foreach link_node $link_nodes_selected {
	set lan_nodes [lsort -dictionary [listLANNodes $link_node {}]]
	if { [lsearch $connected_link_layer_nodes $lan_nodes] == -1 } {
	    lappend connected_link_layer_nodes $lan_nodes
	}
    }

    global autorenumbered_ifcs6
    set autorenumbered_ifcs6 ""

    # assign addresses to nodes connected to L2 nodes
    foreach element $connected_link_layer_nodes {
	set counter 0
	foreach node_id $element {
	    set autorenumber_nodes ""
	    foreach iface [ifcList $node_id] {
		lassign [logicalPeerByIfc $node_id $iface] peer peer_iface
		if { $peer != "" && [[getNodeType $peer].netlayer] != "LINK" && $peer in $selected_nodes } {
		    lappend autorenumber_nodes "$peer $peer_iface"
		}
	    }

	    foreach el $autorenumber_nodes {
		lassign $el node_id iface
		if { $counter == 0 } {
		    set changeAddrRange6 1
		}

		autoIPv6addr $node_id $iface
		lappend autorenumbered_ifcs6 "$node_id $iface"
		incr counter
		set changed 1
		set changeAddrRange6 0
	    }
	}
    }

    set autorenumber_nodes ""
    set autorenumber_ifcs ""

    # save nodes not connected to the L2 node in the autorenumber_nodes list
    foreach node_id $selected_nodes {
	if { [[getNodeType $node_id].netlayer] != "LINK" } {
	    foreach iface [ifcList $node_id] {
		lassign [logicalPeerByIfc $node_id $iface] peer peer_iface
		if { $peer != "" && [[getNodeType $peer].netlayer] != "LINK" && $peer in $selected_nodes } {
		    lappend autorenumber_ifcs "$node_id $iface"
		    if { [lsearch $autorenumber_nodes $node_id] == -1 } {
			lappend autorenumber_nodes $node_id
		    }
		}
	    }
	}
    }

    # delete the existing IP addresses
    foreach el $autorenumber_ifcs {
	lassign $el node_id iface
	setIfcIPv6addrs $node_id $iface ""
    }

    # assign IP addresses to interfaces not connected to L2 nodes
    foreach el $autorenumber_ifcs {
	lassign $el node_id iface
	lassign [logicalPeerByIfc $node_id $iface] peer peer_iface
	if { [lsearch $autorenumber_nodes $node_id] < [lsearch $autorenumber_nodes $peer] } {
	    set changeAddrRange6 1
	}

	autoIPv6addr $node_id $iface
	set changed 1
	set changeAddrRange6 0
    }

    set autorenumber 0
    set changeAddressRange6 0

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
    set tags [$c gettags [$c find closest $x $y]]
    if { [lsearch $tags grid] != -1 || [lsearch $tags background] != -1 } {
	return
    }

    set node_id [lindex $tags 1]
    # Is this really necessary?
    lassign [getAnnotationCoords $node_id] x1 y1 x2 y2
    if { $x < $x1 || $x > $x2 || $y < $y1 || $y > $y2 } {
	# cursor is not ON the closest object
	return
    }

    annotationConfig $c $node_id
}
