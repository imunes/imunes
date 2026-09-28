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
	global main_canvas_elem

	if { [clock seconds] == $clock_seconds } {
		update

		return
	}

	set clock_seconds [clock seconds]
	if { $cursorState } {
		$main_canvas_elem config -cursor watch
		set cursorState 0
	} else {
		$main_canvas_elem config -cursor pirate
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
	global changed main_canvas_elem

	if { $link_id == "" } {
		return
	}

	if { $atomic == "atomic" } {
		if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
			setToExecuteVars "terminate_cfg" [cfgGet]
		}
	}

	set new_link_id [mergeLink $link_id]
	if { $new_link_id != "" } {
		set link_id $new_link_id
	}

	# this data needs to be fetched before we removeLink
	lassign [getLinkPeers $link_id] node1_id node2_id
	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id

	set node1_type [getNodeType $node1_id]
	set node2_type [getNodeType $node2_id]
	# TODO: check this when wlan node turn comes
	if { "wlan" in "$node1_type $node2_type" } {
		removeLink [lindex [linkFromPseudoLink $link_id] 0]

		return
	}

	removeLink [lindex [linkFromPseudoLink $link_id] 0] $keep_ifaces
	cfgUnset "gui" "links" $link_id

	if { $atomic == "atomic" } {
		$main_canvas_elem delete $link_id

		if { [getFromRunning "stop_sched"] } {
			redeployCfg
		}

		set lifaces_refresh 0
		if { ! $keep_ifaces && [getActiveOption "show_vlan_interfaces"]} {
			foreach node_id "$node1_id $node2_id" iface_id "$iface1_id $iface2_id" {
				set iface_name [getIfcName $node_id $iface_id]
				foreach log_iface_id [logIfcList $node_id] {
					if { [getIfcVlanDev $node_id $log_iface_id] != $iface_name } {
						continue
					}

					set lifaces_refresh 1
				}

				if { $lifaces_refresh } {
					break
				}
			}
		}

		set changed 1
		updateUndoLog

		# TODO: better way to force redraw of a single node
		if {
			$new_link_id != "" ||
			$keep_ifaces ||
			"rj45" in "$node1_type $node2_type" ||
			$lifaces_refresh
		} {
			redrawAll
		}

		$main_canvas_elem config -cursor left_ptr
	}
}

#****f* editor.tcl/removeNodeGUI
# NAME
#   removeNodeGUI -- remove node from GUI
# SYNOPSIS
#   removeNodeGUI $node_id
# FUNCTION
#   Removes node from GUI. When removing a node from GUI the links
#   connected to that node are also removed.
# INPUTS
#   * node_id -- node id
#****
proc removeNodeGUI { node_id { keep_other_ifaces 0 } } {
	global main_canvas_elem

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	if { [isPseudoNode $node_id] } {
		removeLinkGUI [getPseudoNodeLink $node_id] non-atomic $keep_other_ifaces
	} else {
		foreach iface_id [ifcList $node_id] {
			set pseudo_id [getPseudoNodeFromNodeIface $node_id $iface_id]
			if { $pseudo_id != "" } {
				removeLinkGUI [getPseudoNodeLink $pseudo_id] non-atomic $keep_other_ifaces

				continue
			}

			set link_id [getIfcLink $node_id $iface_id]
			if { $link_id != "" } {
				removeLinkGUI $link_id non-atomic $keep_other_ifaces
			}
		}
	}

	if { [getNodeCustomIcon $node_id] != "" } {
		removeImageReference [getNodeCustomIcon $node_id] $node_id
	}

	removeNode $node_id $keep_other_ifaces
	cfgUnset "gui" "nodes" $node_id

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	$main_canvas_elem delete $node_id
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

	set zoom [getActiveOption "zoom"]
	set curcanvas [getFromRunning_gui "curcanvas"]

	lassign [getLinkPeers $link_id] orig_node1_id orig_node2_id
	lassign [splitLink $link_id] new_node1_id new_node2_id

	lassign [getNodeCoords $orig_node1_id] x1 y1
	lassign [getNodeCoords $orig_node2_id] x2 y2

	setNodeCoords $new_node1_id \
		"[expr { $x1 + 0.4 * ($x2 - $x1) }] \
		[expr { $y1 + 0.4 * ($y2 - $y1) }]"
	setNodeCoords $new_node2_id \
		"[expr { $x1 + 0.6 * ($x2 - $x1) }] \
		[expr { $y1 + 0.6 * ($y2 - $y1) }]"
	setNodeLabelCoords $new_node1_id [getNodeCoords $new_node1_id]
	setNodeLabelCoords $new_node2_id [getNodeCoords $new_node2_id]

	setNodeCanvas $new_node1_id $curcanvas
	setNodeCanvas $new_node2_id $curcanvas

	set changed 1
	updateUndoLog
	redrawAll
}

#****f* editor.tcl/selectNode
# NAME
#   selectNode -- select node
# SYNOPSIS
#   selectNode $obj
# FUNCTION
#   Crates the selecting box around the specified canvas
#   object.
# INPUTS
#   * obj -- tk canvas object tag id
#****
proc selectNode { obj } {
	global main_canvas_elem all_annotation_types

	if { $obj == "none" } {
		$main_canvas_elem delete -withtags "selectmark"

		return
	}

	set node_id [lindex [$main_canvas_elem gettags $obj] 1]
	if { $node_id == "" } {
		return
	}

	$main_canvas_elem addtag selected withtag "node && $node_id"
	set annotation_type [getAnnotationType $node_id]
	if { [isPseudoNode $node_id] } {
		set bbox [$main_canvas_elem bbox "nodelabel && $node_id"]
	} elseif { $annotation_type in $all_annotation_types } {
		$main_canvas_elem addtag selected withtag "$annotation_type && $node_id"
		set bbox [$main_canvas_elem bbox "$annotation_type && $node_id"]
	} else {
		set bbox [$main_canvas_elem bbox "node && $node_id"]
	}

	if { $bbox == "" } {
		return
	}

	lassign $bbox bx1 by1 bx2 by2
	set bx1 [expr {$bx1 - 2}]
	set by1 [expr {$by1 - 2}]
	set bx2 [expr {$bx2 + 1}]
	set by2 [expr {$by2 + 1}]
	$main_canvas_elem delete -withtags "selectmark && $node_id"
	$main_canvas_elem create line $bx1 $by1 $bx2 $by1 $bx2 $by2 $bx1 $by2 $bx1 $by1 \
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
proc selectAllObjects {} {
	global main_canvas_elem all_annotation_types

	set tags [join "node $all_annotation_types" " || "]
	foreach obj [$main_canvas_elem find withtag $tags] {
		selectNode $obj
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
	global main_canvas_elem all_annotation_types

	set tags [join "node $all_annotation_types" " || "]
	foreach node_id $nodelist {
		selectNode [$main_canvas_elem find withtag \
			"($tags) && $node_id"]
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
	global main_canvas_elem

	set selected {}
	foreach obj [$main_canvas_elem find withtag "node && selected"] {
		lappend selected [lindex [$main_canvas_elem gettags $obj] 1]
	}

	return $selected
}

#****f* editor.tcl/selectedAnnotations
# NAME
#   selectedAnnotations -- get selected annotations
# SYNOPSIS
#   selectedAnnotations
# FUNCTION
#   Gets selected annotations and returns them as a list.
# RESULT
#   * selected -- object list of selected annotations.
#****
proc selectedAnnotations {} {
	global main_canvas_elem all_annotation_types

	set selected {}
	foreach annotation_type $all_annotation_types {
		foreach obj [$main_canvas_elem find withtag "$annotation_type && selected"] {
			lappend selected [lindex [$main_canvas_elem gettags $obj] 1]
		}
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
	global main_canvas_elem

	set selected {}
	foreach obj [$main_canvas_elem find withtag "node && selected"] {
		set node_id [lindex [$main_canvas_elem gettags $obj] 1]
		if { [isPseudoNode $node_id] } {
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
		foreach iface_id [ifcList $node_id] {
			set peer_id [getIfcPeer $node_id $iface_id]
			if { $peer_id == "" } {
				continue
			}

			set mirror_node [getNodeMirror $peer_id]
			if { $mirror_node != "" } {
				set peer_id [getIfcPeer $mirror_node "ifc0"]
			}

			if { $peer_id ni $adjacent } {
				lappend adjacent $peer_id
			}
		}
	}

	if { $adjacent != "" } {
		selectNodes $adjacent
	}
}

#****f* editor.tcl/button3link
# NAME
#   button3link
# SYNOPSIS
#   button3link $x $y
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
#   * x -- x coordinate for popup menu
#   * y -- y coordinate for popup menu
#****
proc button3link { x y } {
	global isOSlinux main_canvas_elem

	clearTempObjects $x $y

	set oper_mode [getFromRunning "oper_mode"]

	set link_id [lindex [$main_canvas_elem gettags "link && current"] 1]
	if { $link_id == "" } {
		set link_id [lindex [$main_canvas_elem gettags "linklabel && current"] 1]
		if { $link_id == "" } {
			return
		}
	}

	lassign [linkFromPseudoLink $link_id] real_link_id - -

	if { $real_link_id != "" } {
		global linkDirect_$real_link_id
		set linkDirect_$real_link_id [getLinkDirect $real_link_id]
	}

	.button3menu delete 0 end

	#
	# Configure link
	#
	.button3menu add command -label "Configure" \
		-command "linkConfigGUI $link_id"

	#
	# Clear link configuration
	#
	.button3menu add command -label "Clear all settings" \
		-command "linkResetConfig [lindex [linkFromPseudoLink $link_id] 0] ; redrawAll"

	global linkJitterConfiguration
	if  { $linkJitterConfiguration } {
		#
		# Edit link jitter
		#
		.button3menu add command -label "Edit link jitter" \
			-command "linkJitterConfigGUI $link_id"
		#
		# Reset link jitter
		#
		.button3menu add command -label "Clear link jitter" \
			-command "linkJitterReset $link_id"
	}

	#
	# Toggle direct link
	#
	if { [isPseudoLink $link_id] } {
		lassign [linkFromPseudoLink $link_id] - peer1_id peer1_iface_id
		lassign [logicalPeerByIfc $peer1_id $peer1_iface_id] peer2_id peer2_iface_id -
	} else {
		lassign [getLinkPeers $link_id] peer1_id peer2_id
		lassign [getLinkPeersIfaces $link_id] peer1_iface_id peer2_iface_id
	}

	if {
		! $isOSlinux ||
		$oper_mode == "edit" ||
		! [getFromRunning "auto_execution"] ||
		([isRunningNode $peer1_id] &&
		[isRunningNode $peer2_id])
	} {
		.button3menu add checkbutton -label "Direct link" \
			-underline 5 -variable linkDirect_$real_link_id \
			-command "toggleDirectLink $link_id"
	} else {
		.button3menu add checkbutton -label "Direct link" \
			-underline 5 -variable linkDirect_$real_link_id \
			-state disabled
	}

	#
	# Delete link
	#
	if { $oper_mode == "edit" || [getFromRunning "stop_sched"] } {
		.button3menu add command -label "Delete" \
			-command "removeLinkGUI $link_id atomic"
	} else {
		.button3menu add command -label "Delete" \
			-state disabled
	}

	#
	# Delete link (keep ifaces)
	#
	if {
		$oper_mode == "edit" ||
		[getFromRunning "stop_sched"]
	} {
		.button3menu add command -label "Delete (keep interfaces)" \
			-command "removeLinkGUI $link_id atomic 1"
	} else {
		.button3menu add command -label "Delete (keep interfaces)" \
			-state disabled
	}

	#
	# Split link
	#
	if { ! [isPseudoLink $link_id] } {
		.button3menu add command -label "Split" \
			-command "splitLinkGUI $link_id"
	} else {
		.button3menu add command -label "Split" -state disabled
	}

	#
	# Merge two pseudo nodes / links
	#
	set peers [getLinkPeers $real_link_id]
	if {
		[isPseudoLink $link_id] &&
		[getNodeCanvas [lindex [getLinkPeers_gui [getLinkMirror $link_id]] 0]] ==
		[getFromRunning_gui "curcanvas"] &&
		[lindex $peers 0] != [lindex $peers 1]
	} {
		.button3menu add command -label "Merge" \
			-command "mergeNodeGUI [lindex [getLinkPeers_gui $link_id] 0]"
	} else {
		.button3menu add command -label "Merge" -state disabled
	}

	#
	# Segment link
	#
	if { ! [isPseudoLink $link_id] } {
		.button3menu add command -label "Segment" \
			-command "segmentLinkGUI $link_id $x $y"
	} else {
		.button3menu add command -label "Segment" -state disabled
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
	global changed main_canvas_elem

	set curcanvas [getFromRunning_gui "curcanvas"]

	lassign [getCanvasSize $canvas_id] max_x max_y

	set selected_nodes [selectedNodes]
	foreach node_id $selected_nodes {
		set type [getNodeType $node_id]

		lassign [getNodeCoords $node_id] node_x node_y
		if { $node_x > $max_x } {
			global ${type}_iconwidth

			set new_x [expr $max_x - [set $type\_iconwidth]/2]
		} else {
			set new_x $node_x
		}

		if { $node_y > $max_y } {
			global ${type}_iconheight

			set new_y [expr $max_y - [set $type\_iconheight]/2]
		} else {
			set new_y $node_y
		}

		if { "$new_x $new_y" != "$node_x $node_y" } {
			setNodeCoords $node_id [snapCoordsToGrid $new_x $new_y]
		}

		lassign [getNodeLabelCoords $node_id] lnode_x lnode_y
		if { $lnode_x > $max_x } {
			set lnew_x $max_x
		} else {
			set lnew_x $lnode_x
		}

		if { $lnode_y > $max_y } {
			set lnew_y $max_y
		} else {
			set lnew_y $lnode_y
		}

		if { "$lnew_x $lnew_y" != "$lnode_x $lnode_y" } {
			setNodeLabelCoords $node_id "$lnew_x $lnew_y"
		}

		setNodeCanvas $node_id $canvas_id
		set changed 1
	}

	set selected_annotations [selectedAnnotations]
	foreach node_id [getCanvasAnnotationOrder $curcanvas] {
		if { $node_id ni $selected_annotations } {
			continue
		}

		# TODO: skip if annotation does not fit to new canvas
		setAnnotationCanvas $node_id $canvas_id

		setCanvasAnnotationOrder $curcanvas [removeFromList [getCanvasAnnotationOrder $curcanvas] $node_id]
		set new_order [removeFromList [getCanvasAnnotationOrder $canvas_id] $node_id]
		if { $new_order == {} } {
			set new_order "grid"
		}

		lappend new_order $node_id
		setCanvasAnnotationOrder $canvas_id $new_order

		set changed 1
	}

	foreach obj [$main_canvas_elem find withtag "linklabel"] {
		set link_id [lindex [$main_canvas_elem gettags $obj] 1]

		lassign [getLinkPeers [lindex [linkFromPseudoLink $link_id] 0]] \
			real_peer1_id real_peer2_id

		# if both (or none) real nodes are moved, don't do anything
		if {
			($real_peer1_id in $selected_nodes &&
			$real_peer2_id in $selected_nodes) ||
			($real_peer1_id ni $selected_nodes &&
			$real_peer2_id ni $selected_nodes)
		} {
			continue
		}

		# if we had a pseudo link before, merge it
		if { [isPseudoLink $link_id] } {
			set link_id [mergeLink $link_id]
		}

		#lassign [getLinkPeers_gui $link_id] peer1_id peer2_id
		set real_peer1_canvas_id [getNodeCanvas $real_peer1_id]
		set real_peer2_canvas_id [getNodeCanvas $real_peer2_id]

		# if nodes are on different canvases, split link
		if { $real_peer1_canvas_id != $real_peer2_canvas_id } {
			lassign [splitLink $link_id] new_node1_id new_node2_id

			setNodeCoords $new_node1_id [getNodeCoords $real_peer2_id]
			setNodeCoords $new_node2_id [getNodeCoords $real_peer1_id]
			setNodeLabelCoords $new_node1_id [getNodeCoords $new_node1_id]
			setNodeLabelCoords $new_node2_id [getNodeCoords $new_node2_id]

			setNodeCanvas $new_node1_id $real_peer1_canvas_id
			setNodeCanvas $new_node2_id $real_peer2_canvas_id
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

	set link_id [mergeLink [getPseudoNodeLink $node_id]]

	set changed 1
	updateUndoLog
	redrawAll

	return $link_id
}

proc pointEnter {} {
	global main_canvas_elem

	if { [getActiveTool] != "select" } {
		return
	}

	set point_id [lindex [$main_canvas_elem gettags current] 1]

	$main_canvas_elem config -cursor hand1
}

proc segmentLinkGUI { link_id x y } {
	global main_canvas_elem changed

	set points [getLinkPoints_gui $link_id]

	set segment_celem [$main_canvas_elem find withtag "link && $link_id && current"]
	if { $segment_celem == "" } {
		# when clicked on link label, choose a middle segment
		set all_segment_celems [$main_canvas_elem find withtag "link && $link_id"]
		set segment_celem [lindex $all_segment_celems [expr { int([llength $all_segment_celems]/2) }]]

		if { $segment_celem == "" } {
			return $link_id
		}
	}

	lassign [$main_canvas_elem gettags $segment_celem] - - point1_id point2_id

	if { [string index $point1_id 0] == "p" } {
		set new_point_idx [expr { [lsearch -exact $points $point1_id] + 1 }]
		lassign [getPoint_gui $point1_id] x1 y1
	} else {
		set new_point_idx 0
		lassign [getNodeCoords $point1_id] x1 y1
	}

	if { [string index $point2_id 0] == "p" } {
		lassign [getPoint_gui $point2_id] x2 y2
	} else {
		lassign [getNodeCoords $point2_id] x2 y2
	}

	set new_point_id [newObjectId [cfgGet "gui" "points"] "p"]
	setLinkPoints_gui $link_id [linsert $points $new_point_idx $new_point_id]

	set x [expr { int(0.5 * ($x1 + $x2)) }]
	set y [expr { int(0.5 * ($y1 + $y2)) }]
	lassign [snapCoordsToGrid $x $y] x y
	setPoint_gui $new_point_id "$x $y"

	set changed 1
	updateUndoLog
	redrawAll

	return $link_id
}

proc removePointGUI {} {
	global main_canvas_elem changed

	set segment_celem [$main_canvas_elem find withtag "point && current"]
	lassign [$main_canvas_elem gettags $segment_celem] - point_id link_id

	setPoint_gui $point_id ""
	setLinkPoints_gui $link_id [removeFromList [getLinkPoints_gui $link_id] $point_id]

	set changed 1
	updateUndoLog
	redrawAll

	return $link_id
}

#****f* editor.tcl/button3node
# NAME
#   button3node
# SYNOPSIS
#   button3node $x $y
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
#   * x -- x coordinate for popup menu
#   * y -- y coordinate for popup menu
#****
proc button3node { x y } {
	global main_canvas_elem

	clearTempObjects $x $y

	set canvas_list [getFromRunning_gui "canvas_list"]
	set curcanvas [getFromRunning_gui "curcanvas"]
	set oper_mode [getFromRunning "oper_mode"]

	set node_id [lindex [$main_canvas_elem gettags "(node || nodelabel || node_running) && current"] 1]
	if { $node_id == "" } {
		return
	}

	if { [$main_canvas_elem gettags "node && $node_id && selected"] == "" } {
		$main_canvas_elem dtag node selected
		$main_canvas_elem delete -withtags selectmark
		selectNode [$main_canvas_elem find withtag "current"]
	}

	set node_type [getNodeType $node_id]

	set root_menu ".button3menu"
	$root_menu delete 0 end

	# pseudo node menu
	if { $node_type == "" && [isPseudoNode $node_id] } {
		menu_mergeNodes $node_id $root_menu
		menu_deleteSelection $node_id $root_menu
		menu_deleteSelectionKeepIfaces $node_id $root_menu

		#
		# Finally post the popup menu on current pointer position
		#
		set x [winfo pointerx .]
		set y [winfo pointery .]
		tk_popup $root_menu $x $y

		return
	}

	foreach menu_proc [invokeTypeProc $node_type "gui::rightClickMenus"] {
		{*}${menu_proc} $node_id $root_menu
	}

	#
	# Finally post the popup menu on current pointer position
	#
	set x [winfo pointerx .]
	set y [winfo pointery .]
	tk_popup $root_menu $x $y
}

#****f* editor.tcl/button1
# NAME
#   button1 -- button1 clicked
# SYNOPSIS
#   button1 $x $y $button
# FUNCTION
#   This procedure is called when a left mouse button is
#   clicked on the canvas. This procedure selects a new
#   node or creates a new node, depending on the selected
#   tool.
# INPUTS
#   * x -- x coordinate
#   * y -- y coordinate
#   * button -- the keyboard button that is pressed.
#****
proc button1 { x y button } {
	global newlink curobj changed
	global router pc host lanswitch frswitch rj45 hub
	global oval rectangle text freeform newtext
	global lastX lastY
	global background selectbox
	global resizemode resizeobj main_canvas_elem
	global all_annotation_types

	set zoom [getActiveOption "zoom"]

	set x [$main_canvas_elem canvasx $x]
	set y [$main_canvas_elem canvasy $y]

	set lastX $x
	set lastY $y

	set active_tool [getActiveTool]
	set curobj [$main_canvas_elem find withtag current]
	set curtype [lindex [$main_canvas_elem gettags current] 0]
	set wasselected 0
	if {
		($active_tool == "select" && $curtype in "node node_running $all_annotation_types") ||
		($curtype == "nodelabel" &&
		[isPseudoNode [lindex [$main_canvas_elem gettags $curobj] 1]])
	} {
		set node_id [lindex [$main_canvas_elem gettags current] 1]
		set wasselected [expr {$node_id in "[selectedNodes] [selectedAnnotations]"}]

		if { $button == "ctrl" } {
			if { $wasselected } {
				$main_canvas_elem dtag $node_id selected
				$main_canvas_elem delete -withtags "selectmark && $node_id"
			}
		} elseif { ! $wasselected } {
			foreach node_type "node $all_annotation_types" {
				$main_canvas_elem dtag $node_type selected
			}
			$main_canvas_elem delete -withtags selectmark
		}

		if { $active_tool != "link" && ! $wasselected } {
			selectNode $curobj
		}
	} elseif { $active_tool == "select" && $curtype == "point" } {
		set point_id [lindex [$main_canvas_elem gettags current] 1]
		$main_canvas_elem dtag "point" "point_selected"
		$main_canvas_elem addtag "point_selected" withtag "point && $point_id"
	} elseif { $active_tool == "select" && $curtype == "selectmark" } {
		set o1 [lindex [$main_canvas_elem gettags current] 1]
		if { [getAnnotationType $o1] in "oval rectangle" } {
			set resizeobj $o1
			set bbox1 [$main_canvas_elem bbox $o1]
			set x1 [lindex $bbox1 0]
			set y1 [lindex $bbox1 1]
			set x2 [lindex $bbox1 2]
			set y2 [lindex $bbox1 3]
			set l 0 ;# left
			set r 0 ;# right
			set u 0 ;# up
			set d 0 ;# down

			if { $x < [expr $x1+($x2-$x1)/8.0] } { set l 1 }
			if { $x > [expr $x2-($x2-$x1)/8.0] } { set r 1 }
			if { $y < [expr $y1+($y2-$y1)/8.0] } { set u 1 }
			if { $y > [expr $y2-($y2-$y1)/8.0] } { set d 1 }

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
	} elseif { $button != "ctrl" || $active_tool != "select" } {
		foreach node_type "node $all_annotation_types" {
			$main_canvas_elem dtag $node_type selected
		}

		$main_canvas_elem delete -withtags selectmark
	}

	#determine whether we can create nodes on the current object
	set object_drawable 0
	foreach type "background grid $all_annotation_types" {
		if { $type in [$main_canvas_elem gettags $curobj] } {
			set object_drawable 1
			break
		}
	}

	if { $object_drawable } {
		if { $active_tool ni "select link $all_annotation_types" } {
			global newnode

			# adding a new node
			set node_id [newNode $active_tool]
			if { $button == "ctrl" } {
				lappendToRunning "no_auto_execute_nodes" $node_id
			}

			setNodeLabel $node_id [getNodeName $node_id]
			setNodeCanvas $node_id [getFromRunning_gui "curcanvas"]
			setNodeCoords $node_id "[expr {$x / $zoom}] [expr {$y / $zoom}]"

			# To calculate label distance we take into account the normal icon
			# height
			global $active_tool\_iconheight

			set dy [expr [set $active_tool\_iconheight]/2 + 11]
			setNodeLabelCoords $node_id "[expr {$x / $zoom}] \
				[expr {$y / $zoom + $dy}]"

			drawNode $node_id
			foreach node_type "node $all_annotation_types" {
				$main_canvas_elem dtag $node_type selected
			}
			$main_canvas_elem delete -withtags selectmark
			selectNode [$main_canvas_elem find withtag "node && $node_id"]

			set newnode $node_id
			set changed 1
		} elseif {
			$active_tool == "select" &&
			$curtype ni "node nodelabel"
		} {
			$main_canvas_elem config -cursor cross

			set lastX $x
			set lastY $y
			if { $selectbox != "" } {
				# We actually shouldn't get here!
				$main_canvas_elem delete $selectbox
				set selectbox ""
			}
		} elseif { $active_tool in "oval rectangle" } {
			$main_canvas_elem config -cursor cross
			set lastX $x
			set lastY $y
		} elseif { $active_tool == "text" } {
			$main_canvas_elem config -cursor xterm
			set lastX $x
			set lastY $y
			set newtext [$main_canvas_elem create text $lastX $lastY \
				-text "" \
				-anchor w \
				-justify left \
				-tags "newtext"]
		}
	} else {
		if { $curtype in "node nodelabel $all_annotation_types" } {
			if { $active_tool == "select" && $button == "ctrl" && $wasselected } {
				$main_canvas_elem config -cursor cross
			} else {
				$main_canvas_elem config -cursor fleur
			}
		}

		if { $active_tool == "link" && $curtype in "node node_running" } {
			$main_canvas_elem config -cursor cross
			set lastX [lindex [$main_canvas_elem coords $curobj] 0]
			set lastY [lindex [$main_canvas_elem coords $curobj] 1]
			set newlink [$main_canvas_elem create line $lastX $lastY $x $y \
				-fill [getActiveOption "default_link_color"] -width [getActiveOption "default_link_width"] \
				-tags "link"]
		}
	}

	raiseAll
}

#****f* editor.tcl/button1-motion
# NAME
#   button1-motion -- button1 moved
# SYNOPSIS
#   button1-motion $x $y
# FUNCTION
#   This procedure is called when a left mouse button is
#   pressed and the mouse is moved around the canvas.
#   This procedure creates new select box, moves the
#   selected nodes or draws a new link.
# INPUTS
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button1-motion { x y } {
	global newlink changed
	global lastX lastY sizex sizey selectbox background
	global resizemode main_canvas_elem
	global all_annotation_types

	foreach annotation_type $all_annotation_types {
		global new$annotation_type
	}

	set zoom [getActiveOption "zoom"]

	set x [$main_canvas_elem canvasx $x]
	set y [$main_canvas_elem canvasy $y]
	set curobj [$main_canvas_elem find withtag current]
	set curtype [lindex [$main_canvas_elem gettags current] 0]
	set active_tool [getActiveTool]
	if { $active_tool == "link" } {
		if { $newlink != "" } {
			#creating a new link
			$main_canvas_elem coords $newlink $lastX $lastY $x $y
		} else {
			return
		}
	} elseif {
		$active_tool == "select" &&
		$curtype == "nodelabel" &&
		! [isPseudoNode [lindex [$main_canvas_elem gettags $curobj] 1]]
	} {
		$main_canvas_elem move $curobj [expr {$x - $lastX}] [expr {$y - $lastY}]

		set changed 1
		set lastX $x
		set lastY $y
	} elseif { $active_tool == "select" && $curtype == "point" } {
		$main_canvas_elem move $curobj [expr { $x - $lastX }] [expr { $y - $lastY }]

		set changed 1
		set lastX $x
		set lastY $y

		lassign [$main_canvas_elem gettags $curobj] - point_id link_id

		set coordinates [$main_canvas_elem coords $curobj]
		set x [expr { int([lindex $coordinates 0] / $zoom) }]
		set y [expr { int([lindex $coordinates 1] / $zoom) }]

		setPoint_gui $point_id "$x $y"
	} elseif {
		$active_tool == "select" &&
		$curobj == "" &&
		$curtype == ""
	} {
		return
	} elseif {
		$active_tool == "select" &&
		$curtype != "node_running" &&
		($curobj == $selectbox ||
		$curtype in "background grid" ||
		($curobj ni [$main_canvas_elem find withtag "selected"] &&
		$curtype != "selectmark") &&
		! [isPseudoNode [lindex [$main_canvas_elem gettags $curobj] 1]])
	} {
		#forming the selectbox and resizing
		if { $selectbox == "" } {
			set err [catch {
				set selectbox [$main_canvas_elem create line \
					$lastX $lastY $x $lastY $x $y $lastX $y $lastX $lastY \
					-dash {10 4} -fill black -width 1 -tags "selectbox"]
			} error]
			if { $err != 0 } {
				return
			}

			$main_canvas_elem raise $selectbox "all"
		} else {
			set err [catch {
				$main_canvas_elem coords $selectbox \
					$lastX $lastY $x $lastY $x $y $lastX $y $lastX $lastY
			} error]
			if { $err != 0 } {
				return
			}
		}
		# actually we should check if curobj == bkgImage
	} elseif {
		$active_tool == "oval" &&
		($curobj in "$newoval $background" ||
		$curtype in "background grid $all_annotation_types")
	} {
		# Draw a new oval
		if { $newoval == "" } {
			set newoval [$main_canvas_elem create oval $lastX $lastY $x $y \
				-outline blue \
				-dash {10 4} \
				-width 1 \
				-tags "newoval"]

			$main_canvas_elem raise $newoval "background || link || linklabel || interface"
		} else {
			$main_canvas_elem coords $newoval \
				$lastX $lastY $x $y
		}
	} elseif {
		$active_tool == "rectangle" &&
		($curobj in "$newrectangle $background" ||
		$curtype in "background grid $all_annotation_types")
	} {
		# Draw a new rectangle
		if { $newrectangle == "" } {
			set newrectangle [$main_canvas_elem create rectangle $lastX $lastY $x $y \
				-outline blue \
				-dash {10 4} \
				-width 1 \
				-tags "newrectangle"]

			$main_canvas_elem raise $newrectangle "oval || background || link || linklabel || interface"
		} else {
			$main_canvas_elem coords $newrectangle $lastX $lastY $x $y
		}
	} elseif {
		$active_tool == "freeform" &&
		($curobj in "$newfreeform $background" ||
		$curtype in "background grid $all_annotation_types")
	} {
		# Draw a new freeform
		if { $newfreeform == "" } {
			set newfreeform [$main_canvas_elem create line $lastX $lastY $x $y \
				-fill blue \
				-width 2 \
				-tags "newfreeform"]

			$main_canvas_elem raise $newfreeform "oval || rectangle || background || link || linklabel || interface"
		} else {
			xpos $newfreeform $x $y 2 blue
		}
	} elseif { $active_tool == "select" && $curtype == "selectmark" } {
		# resize annotation
		foreach o [$main_canvas_elem find withtag "selected"] {
			set node_id [lindex [$main_canvas_elem gettags $o] 1]

			lassign [lmap n [getAnnotationCoords $node_id] {expr {$n * $zoom}}] oldX1 oldY1 oldX2 oldY2
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
					set selectbox [$main_canvas_elem create line \
						$oldX1 $oldY1 $oldX2 $oldY1 $oldX2 $oldY2 $oldX1 $oldY2 $oldX1 $oldY1 \
						-dash {10 4} -fill black -width 1 -tags "selectbox"]
				} error]
				if { $err != 0 } {
					return
				}

				$main_canvas_elem raise $selectbox "all"
			} else {
				set err [catch {
					$main_canvas_elem coords $selectbox \
						$oldX1 $oldY1 $oldX2 $oldY1 $oldX2 $oldY2 $oldX1 $oldY2 $oldX1 $oldY1
				} error]
				if { $err != 0 } {
					return
				}
			}
		}
	} else {
		foreach img [$main_canvas_elem find withtag "selected"] {
			$main_canvas_elem move $img [expr {$x - $lastX}] [expr {$y - $lastY}]

			set node_id [lindex [$main_canvas_elem gettags $img] 1]

			foreach elem "selectmark nodedisabled node_running nodelabel link" {
				set obj [$main_canvas_elem find withtag "$elem && $node_id"]
				$main_canvas_elem move $obj [expr {$x - $lastX}] [expr {$y - $lastY}]

				if { $elem == "link" } {
					$main_canvas_elem addtag need_redraw withtag "link && $node_id"
				}
			}
		}

		foreach link_id [$main_canvas_elem find withtag "link && need_redraw"] {
			redrawLink [lindex [$main_canvas_elem gettags $link_id] 1]
		}

		$main_canvas_elem dtag link need_redraw
		set changed 1
		set lastX $x
		set lastY $y
	}
}

#****f* editor.tcl/button1-release
# NAME
#   button1-release -- button1 released
# SYNOPSIS
#   button1-release $x $y
# FUNCTION
#   This procedure is called when a left mouse button is
#   released.
#   The result of this function depends on the actions
#   during the button1-motion procedure.
# INPUTS
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button1-release { x y } {
	global newlink curobj grid
	global changed selectbox
	global lastX lastY sizex sizey
	global autorearrange_enabled
	global resizemode resizeobj
	global newnode main_canvas_elem
	global all_annotation_types

	set zoom [getActiveOption "zoom"]
	set undolevel [getFromRunning "undolevel"]
	set redolevel [getFromRunning "redolevel"]

	set redrawNeeded 0

	set outofbounds 0

	set x [$main_canvas_elem canvasx $x]
	set y [$main_canvas_elem canvasy $y]
	$main_canvas_elem config -cursor left_ptr
	set active_tool [getActiveTool]
	# if the link tool is active and we are creating a new link
	if { $active_tool == "link" && $newlink != "" } {
		$main_canvas_elem delete $newlink
		set newlink ""
		set destobj ""

		# find the node that is under the cursor
		foreach obj [$main_canvas_elem find overlapping $x $y $x $y] {
			if { [lindex [$main_canvas_elem gettags $obj] 0] in "node node_running" } {
				set destobj $obj
				break
			}
		}

		# if there is an object beneath the cursor and an object was
		# selected by the button1 procedure create a link between nodes
		if { $destobj != "" && $curobj != "" && $destobj != $curobj } {
			set lnode1 [lindex [$main_canvas_elem gettags $curobj] 1]
			set lnode2 [lindex [$main_canvas_elem gettags $destobj] 1]
			if { $lnode1 != $lnode2 } {
				newLinkGUI $lnode1 $lnode2
			}
		}
	} elseif { $active_tool in $all_annotation_types } {
		#popup.*Dialog and destroy all other temporary annotations
		popup[string totitle $active_tool]Dialog 0 "false"

		foreach annotation_type [removeFromList $all_annotation_types $active_tool] {
			destroyNew[string totitle $annotation_type]
		}
	}

	if { $changed == 1 } {
		set regular true

		set selected {}

		if { [lindex [$main_canvas_elem gettags $curobj] 0] == "nodelabel" } {
			set node_id [lindex [$main_canvas_elem gettags $curobj] 1]

			lassign [$main_canvas_elem coords $curobj] view_lx view_ly
			set lx [expr { $view_lx / $zoom }]
			set ly [expr { $view_ly / $zoom }]
			if { [isPseudoNode $node_id] } {
				lassign [snapCoordsToGrid $lx $ly] lx ly
				$main_canvas_elem addtag need_redraw withtag "link && $node_id"
			}

			lassign [getNodeLabelCoords $node_id] orig_lx orig_ly
			if { $lx < 0 || $ly < 0 || $lx > $sizex || $ly > $sizey } {
				set regular false
			} elseif { "$orig_lx $orig_ly" != "$lx $ly" } {
				setNodeLabelCoords $node_id "$lx $ly"

				if { [isPseudoNode $node_id] } {
					setNodeCoords $node_id "$lx $ly"
				}

				set view_dlx [expr { int(($lx - $orig_lx) / $zoom) }]
				set view_dly [expr { int(($ly - $orig_ly) / $zoom) }]

				$main_canvas_elem move "nodelabel && $node_id" $view_dlx $view_dly
			}

			# selects the node whose label was moved
			selectNode [$main_canvas_elem find withtag "node && $node_id"]
		} else {
			foreach img [$main_canvas_elem find withtag "selected"] {
				set node_id [lindex [$main_canvas_elem gettags $img] 1]
				lappend selected $node_id
				lassign [$main_canvas_elem coords $img] view_x view_y
				set x [expr { $view_x / $zoom }]
				set y [expr { $view_y / $zoom }]

				# only nodes are snapped to grid, annotations are not
				if {
					$autorearrange_enabled == 0 &&
					[$main_canvas_elem find withtag "node && $node_id"] != ""
				} {
					lassign [snapCoordsToGrid $x $y] x y
					lassign [getNodeCoords $node_id] orig_x orig_y
					if { $x < 0 || $y < 0 || $x > $sizex || $y > $sizey } {
						set regular false
					} elseif { "$orig_x $orig_y" != "$x $y" } {
						set dx [expr { $x - $orig_x }]
						set dy [expr { $y - $orig_y }]

						lassign [getNodeLabelCoords $node_id] orig_lx orig_ly
						set lx [expr { $orig_lx + $dx }]
						set ly [expr { $orig_ly + $dy }]

						if { $lx < 0 || $ly < 0 || $lx > $sizex || $ly > $sizey } {
							set regular false
						} elseif { "$orig_lx $orig_ly" != "$lx $ly" } {
							#moving the nodelabel and selectbox assigned to the moving node

							set view_dx [expr { int($dx / $zoom) }]
							set view_dy [expr { int($dy / $zoom) }]

							setNodeCoords $node_id "$x $y"
							$main_canvas_elem move "selectmark && $node_id" $view_dx $view_dy

							setNodeLabelCoords $node_id "$lx $ly"
							$main_canvas_elem move "nodelabel && $node_id" $view_dx $view_dy
						}
					}
				}

				if { [lindex [$main_canvas_elem gettags $node_id] 0] == "oval" } {
					lassign [$main_canvas_elem coords [lindex [$main_canvas_elem gettags $node_id] 1]] x1 y1 x2 y2
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

				if { [lindex [$main_canvas_elem gettags $node_id] 0] == "rectangle" } {
					set coordinates [$main_canvas_elem coords [lindex [$main_canvas_elem gettags $node_id] 1]]
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

				if { [lindex [$main_canvas_elem gettags $node_id] 0] == "freeform" } {
					lassign [$main_canvas_elem bbox "selectmark && $node_id"] x1 y1 x2 y2
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

					set coordinates [$main_canvas_elem coords [lindex [$main_canvas_elem gettags $node_id] 1]]
					set l [expr {[llength $coordinates]-1}]
					set newcoords {}
					set i 0

					while { $i <= $l } {
						set f1 [expr {[lindex $coordinates $i] * $zoom}]
						set g1 [expr {[lindex $coordinates $i+1] * $zoom}]
						set xx1 [expr $f1+$shiftx]
						set yy1 [expr $g1+$shifty]

						lappend newcoords $xx1 $yy1
						set i [expr {$i+2}]
					}

					setAnnotationCoords $node_id $newcoords
				}

				if { [lindex [$main_canvas_elem gettags $node_id] 0] == "text" } {
					set bbox [$main_canvas_elem bbox "selectmark && $node_id"]
					lassign [$main_canvas_elem coords [lindex [$main_canvas_elem gettags $node_id] 1]] x1 y1
					set x1 [expr {$x1 / $zoom}]
					set y1 [expr {$y1 / $zoom}]

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

				$main_canvas_elem addtag need_redraw withtag "link && $node_id"
				set changed 1
			} ;# end of: foreach img selected

			foreach img [$main_canvas_elem find withtag "point_selected"] {
				lassign [$main_canvas_elem gettags $img] - point_id link_id

				set coordinates [$main_canvas_elem coords $img]
				set x [expr { [lindex $coordinates 0] / $zoom }]
				set y [expr { [lindex $coordinates 1] / $zoom }]

				set dx [expr { (int($x / $grid + 0.5) * $grid - $x) * $zoom }]
				set dy [expr { (int($y / $grid + 0.5) * $grid - $y) * $zoom }]
				$main_canvas_elem move $img $dx $dy

				set coordinates [$main_canvas_elem coords $img]
				set x [expr { int([lindex $coordinates 0] / $zoom) }]
				set y [expr { int([lindex $coordinates 1] / $zoom) }]

				if { $x < 0 } {
					set x 0
				}
				if { $y < 0 } {
					set y 0
				}
				if { $x > $sizex } {
					set x $sizex
				}
				if { $y > $sizey } {
					set y $sizey
				}

				setPoint_gui $point_id "$x $y"

				redrawLink $link_id
				updateLinkLabel $link_id
			}
		}

		if { $outofbounds } {
			redrawAll
			if { $active_tool == "select" } {
				selectNodes $selected
			}
		}

		if { $regular == "true" } {
			if { [getFromRunning "stop_sched"] } {
				redeployCfg
			}

			foreach img [$main_canvas_elem find withtag "node && selected"] {
				set node_id [lindex [$main_canvas_elem gettags $img] 1]
				drawNode $node_id
				selectNode [$main_canvas_elem find withtag "node && $node_id"]
			}

			foreach link_id [$main_canvas_elem find withtag "link && need_redraw"] {
				redrawLink [lindex [$main_canvas_elem gettags $link_id] 1]
				updateLinkLabel [lindex [$main_canvas_elem gettags $link_id] 1]
			}
		} else {
			if { $newnode != "" } {
				removeNode $newnode
			}

			$main_canvas_elem config -cursor watch
			.bottom.textbox config -text ""

			redrawAll

			if { $active_tool == "select" } {
				selectNodes $selected
			}

			set changed 0
		}

		$main_canvas_elem dtag link need_redraw
	} elseif { $active_tool == "select" } {
		# $changed!=1
		if { $selectbox == "" } {
			set x1 $x
			set y1 $y
			set resizemode "false"
			if { $autorearrange_enabled } {
				set autorearrange_enabled 0
				update
				set redrawNeeded [snapCanvasNodesToGrid]
			}
		} else {
			set coordinates [$main_canvas_elem coords $selectbox]

			$main_canvas_elem delete $selectbox
			set selectbox ""

			if { $coordinates == "" } {
				return
			}

			set x [lindex $coordinates 0]
			set y [lindex $coordinates 1]
			set x1 [lindex $coordinates 4]
			set y1 [lindex $coordinates 5]
		}

		if { $resizemode == "false" } {
			set enclosed {}

			catch { $main_canvas_elem find enclosed $x $y $x1 $y1 } enc_objs
			foreach obj $enc_objs {
				set tags [$main_canvas_elem gettags $obj]

				foreach object_type "node $all_annotation_types" {
					if { [lindex $tags 0] == $object_type && [lsearch $tags selected] == -1 } {
						lappend enclosed $obj
					}
				}
			}

			foreach obj $enclosed {
				selectNode $obj
			}
		} else {
			setAnnotationCoords $resizeobj "$x $y $x1 $y1"
			set redrawNeeded 1
			set resizemode false
			set changed 1
		}
	}

	set newnode ""

	updateUndoLog

	if { $redrawNeeded } {
		set redrawNeeded 0
		redrawAll
	} else {
		raiseAll
	}

	update
	$main_canvas_elem config -cursor left_ptr
}

#****f* editor.tcl/button3background
# NAME
#   button3background -- button3 background
# SYNOPSIS
#   button3background $x $y
# FUNCTION
#   Popup menu for right click on canvas background.
# INPUTS
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc button3background { x y } {
	global changed

	clearTempObjects $x $y

	set canvas_list [getFromRunning_gui "canvas_list"]
	set curcanvas [getFromRunning_gui "curcanvas"]

	.button3menu delete 0 end

	#
	# Show canvas background
	#
	set toggle_bkg_command {
		setGlobalOption "show_background_image" - "toggle"

		redrawAll
	}
	.button3menu add checkbutton -label "Show background" \
		-underline 5 -variable show_background_image \
		-command $toggle_bkg_command

	.button3menu add separator
	#
	# Change canvas background
	#
	.button3menu add command -label "Change background" \
		-command "changeBkgPopup"

	#
	# Remove canvas background
	#
	set tmp_command [list apply {
		{ curcanvas canvas_bkg } {
			global changed

			removeCanvasBkg $curcanvas
			if { $canvas_bkg != "" } {
				removeImageReference $canvas_bkg $curcanvas
			}

			set changed 1
			updateUndoLog
			redrawAll
		}
	} \
		$curcanvas \
		[getCanvasBkg $curcanvas]
	]
	.button3menu add command \
		-label "Remove background" \
		-command $tmp_command

	.button3menu.canvases delete 0 end

	set m .button3menu.canvases

	set mode normal
	if { [llength $canvas_list] == 1 } {
		set mode disabled
	}

	.button3menu add cascade \
		-label "Set background from:" \
		-menu $m \
		-underline 0 \
		-state $mode

	foreach cnv $canvas_list {
		set canv_name [getCanvasName $cnv]
		set canvas_bkg [getCanvasBkg $cnv]
		set curcanvas_size [getCanvasSize $curcanvas]
		set othercanvsize [getCanvasSize $cnv]
		if { $curcanvas != $cnv && $curcanvas_size == $othercanvsize } {

			set tmp_command [list apply {
				{ curcanvas canvas_bkg } {
					setCanvasBkg $curcanvas $canvas_bkg
					setImageReference $canvas_bkg $curcanvas

					set changed 1
					updateUndoLog
					redrawAll
				}
			} \
				$curcanvas \
				$canvas_bkg
			]
			$m add command \
				-label "$canv_name" \
				-command $tmp_command
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
		set icon [getNodeCustomIcon $node_id]
		removeNodeCustomIcon $node_id
		removeImageReference $icon $node_id
	}

	set changed 1
	updateUndoLog
	redrawAll
}

#****f* editor.tcl/nodeEnter
# NAME
#   nodeEnter -- node enter
# SYNOPSIS
#   nodeEnter
# FUNCTION
#   This procedure prints the node id, node name and
#   node model (if exists), as well as all the interfaces
#   of the node in the status line.
#   Information is presented for the node above which is
#   the mouse pointer.
#****
proc nodeEnter {} {
	global main_canvas_elem

	set node_id [lindex [$main_canvas_elem gettags current] 1]
	if { [isPseudoNode $node_id] } {
		lassign [nodeFromPseudoNode $node_id] real_node_id real_iface_id
		.bottom.textbox config -foreground "black" \
			-text "pseudo {$node_id} from {$real_node_id} [getNodeName $real_node_id]:[getIfcName $real_node_id $real_iface_id]"

		return
	}

	set err [catch { getNodeType $node_id } error]
	if { $err != 0 } {
		return
	}

	#Show node error only if in exec mode
	if { [isRunningNode $node_id] } {
		if { [isErrorNode $node_id] && [getStateErrorMsgNode $node_id] != "" } {
			.bottom.textbox configure -text "{$node_id} ERROR: [getStateErrorMsgNode $node_id]" -foreground "red"

			return
		}

		set line ""
		foreach iface_id [ifcList $node_id] {
			if { ! [isErrorNodeIface $node_id $iface_id] } {
				continue
			}

			set iface_error [getStateErrorMsgNodeIface $node_id $iface_id]
			if { $iface_error == "" } {
				continue
			}

			set line "$line$iface_error\n"
		}

		if { $line != "" } {
			# remove last \n
			set line [string range $line 0 end-1]
			.bottom.textbox config -text "{$node_id} IFACES ERRORS: $line" -foreground "red"

			return
		}
	}

	set name [getNodeName $node_id]
	set model [getNodeModel $node_id]
	if { $model != "" } {
		set line "{$node_id} $name ($model):"
	} else {
		set line "{$node_id} $name:"
	}

	if { [getNodeType $node_id] != "rj45" } {
		foreach iface_id [ifcList $node_id] {
			set line "$line [getIfcName $node_id $iface_id]:[join [getIfcIPv4addrs $node_id $iface_id] ", "]"
		}
	}
	.bottom.textbox config -text "$line" -foreground "black"

	showCfg $node_id
	showRoute $node_id
}

#****f* editor.tcl/linkEnter
# NAME
#   linkEnter -- link enter
# SYNOPSIS
#   linkEnter
# FUNCTION
#   This procedure prints the link id, link bandwidth
#   and link delay in the status line.
#   Information is presented for the link above which is
#   the mouse pointer.
#****
proc linkEnter {} {
	global main_canvas_elem

	set link_id [lindex [$main_canvas_elem gettags current] 1]
	if { [lsearch [getFromRunning "link_list"] $link_id] == -1 } {
		return
	}
	set line "$link_id: [getLinkBandwidthString $link_id] [getLinkDelayString $link_id]"
	.bottom.textbox config -text "$line" -foreground "black"
}

#****f* editor.tcl/anyLeave
# NAME
#   anyLeave
# SYNOPSIS
#   anyLeave
# FUNCTION
#   This procedure clears the status line.
#****
proc anyLeave {} {
	global main_canvas_elem

	.bottom.textbox config -text "" -foreground "black"

	$main_canvas_elem delete -withtag showCfgPopup
	$main_canvas_elem delete -withtag route
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
proc deleteSelection { { keep_other_ifaces 0 } { no_warning "" } } {
	global changed
	global viewid main_canvas_elem

	set selected_nodes [selectedNodes]
	if {
		$selected_nodes != {} &&
		$no_warning == "" &&
		[getFromRunning "cfg_deployed"]
	} {
		set answer [tk_messageBox -message "Are you sure you want to delete selected nodes?\n\nThere is no undo in exec mode." \
			-icon question -type yesno]

		switch -- $answer {
			yes {}
			no {
				return false
			}
		}
	}

	if { ! [getFromRunning "stop_sched"] } {
		return false
	}

	catch { unset viewid }
	$main_canvas_elem config -cursor watch; update

	foreach node_id $selected_nodes {
		removeNodeGUI $node_id $keep_other_ifaces

		set changed 1
	}

	foreach annotation_id [selectedAnnotations] {
		deleteAnnotation $annotation_id

		set changed 1
	}

	if { $changed } {
		raiseAll
		updateUndoLog
		redrawAll
	}

	$main_canvas_elem config -cursor left_ptr
	.bottom.textbox config -text ""

	return true
}

#****f* editor.tcl/removeIPv4Nodes
# NAME
#   removeIPv4Nodes -- remove ipv4 nodes
# SYNOPSIS
#   removeIPv4Nodes
# FUNCTION
#   Sets all nodes' IPv4 addresses to empty strings.
#****
proc removeIPv4Nodes { nodes all_ifaces } {
	global changed

	if { $nodes == "*" } {
		set nodes [getFromRunning "node_list"]
	}

	set nodes_ifaces [dict create]
	foreach node_id $nodes {
		if { [isPseudoNode $node_id] } {
			set nodes [removeFromList $nodes $node_id]
		}

		if { $all_ifaces == "*" } {
			dict set nodes_ifaces $node_id [ifcList $node_id]
		} else {
			dict set nodes_ifaces $node_id [dictGet $all_ifaces $node_id]
		}
	}

	if { $nodes == "" } {
		return
	}

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	set removed_addrs {}
	foreach node_id $nodes {
		if { [getNodeStatIPv4routes $node_id] != "" } {
			setNodeStatIPv4routes $node_id ""
		}

		set ifaces [dictGet $nodes_ifaces $node_id]
		if { $ifaces == "*" } {
			set ifaces [ifcList $node_id]
		}

		foreach iface_id $ifaces {
			set addrs [getIfcIPv4addrs $node_id $iface_id]
			if { $addrs == "" } {
				continue
			}

			set removed_addrs [concat $removed_addrs $addrs]
			setIfcIPv4addrs $node_id $iface_id ""
		}
	}

	setToRunning "ipv4_used_list" [removeFromList [getFromRunning "ipv4_used_list"] $removed_addrs "keep_doubles"]

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	set changed 1
	updateUndoLog
	redrawAll
}

#****f* editor.tcl/removeIPv6Nodes
# NAME
#   removeIPv6Nodes -- remove ipv6 nodes
# SYNOPSIS
#   removeIPv6Nodes
# FUNCTION
#   Sets all nodes' IPv6 addresses to empty strings.
#****
proc removeIPv6Nodes { nodes all_ifaces } {
	global changed

	if { $nodes == "*" } {
		set nodes [getFromRunning "node_list"]
	}

	set nodes_ifaces [dict create]
	foreach node_id $nodes {
		if { [isPseudoNode $node_id] } {
			set nodes [removeFromList $nodes $node_id]
		}

		if { $all_ifaces == "*" } {
			dict set nodes_ifaces $node_id [ifcList $node_id]
		} else {
			dict set nodes_ifaces $node_id [dictGet $all_ifaces $node_id]
		}
	}

	if { $nodes == "" } {
		return
	}

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	set removed_addrs {}
	foreach node_id $nodes {
		if { [getNodeStatIPv6routes $node_id] != "" } {
			setNodeStatIPv6routes $node_id ""
		}

		set ifaces [dictGet $nodes_ifaces $node_id]
		if { $ifaces == "*" } {
			set ifaces [ifcList $node_id]
		}

		foreach iface_id $ifaces {
			set addrs [getIfcIPv6addrs $node_id $iface_id]
			if { $addrs == "" } {
				continue
			}

			set removed_addrs [concat $removed_addrs $addrs]
			setIfcIPv6addrs $node_id $iface_id ""
		}
	}

	setToRunning "ipv6_used_list" [removeFromList [getFromRunning "ipv6_used_list"] $removed_addrs "keep_doubles"]

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	set changed 1
	updateUndoLog
	redrawAll
}

proc matchSubnet { ip_version node_id iface_id subnet } {
	global changed main_canvas_elem

	assignSubnet $ip_version $node_id $iface_id [selectedNodes] $subnet

	set changed 1
	updateUndoLog
	redrawAll

	$main_canvas_elem config -cursor left_ptr
}

proc addressChangeDialog { ip_version node_id iface_id } {
	global $ip_version

	set ip_version_num [string index $ip_version 3]

	set top_elem .entry1
	catch { destroy $top_elem }
	toplevel $top_elem
	wm transient $top_elem .
	wm title $top_elem "IPv${ip_version_num} autonumbering subnet"
	wm iconname $top_elem "IPv${ip_version_num} subnet"
	grab $top_elem

	set main_frame [ttk::frame $top_elem.ipframe]
	pack $main_frame -fill both -expand 1

	set label_elem [ttk::label $main_frame.msg -text "IPv${ip_version_num} subnet:"]
	pack $label_elem -side top

	set entry_elem [ttk::entry $main_frame.e1 -width 27 -validate focus -invalidcommand "focusAndFlash %W"]

	# findFreeIPv4Subnet/findFreeIPv6Subnet ipv4_used_list/ipv6_used_list
	$entry_elem insert 0 [findFreeIPv${ip_version_num}Subnet "" [getFromRunning "ipv${ip_version_num}_used_list"]]
	pack $entry_elem -side top -pady 5 -padx 10 -fill x

	# checkIPv4Net/checkIPv6Net
	$entry_elem configure -invalidcommand { checkIPv${ip_version_num}Net %P }

	set buttons_frame [ttk::frame $main_frame.buttons]
	pack $buttons_frame -side bottom -fill x -pady 2m

	set apply_btn [ttk::button $buttons_frame.apply]
	$apply_btn configure -text "Apply" \
		-command "subnetApply $ip_version $entry_elem $node_id $iface_id ; destroy $top_elem"

	set cancel_btn [ttk::button $buttons_frame.cancel]
	$cancel_btn configure -text "Cancel" \
		-command "destroy $top_elem"

	bind $top_elem <Key-Return> "subnetApply $ip_version $entry_elem $node_id $iface_id ; destroy $top_elem"
	bind $top_elem <Key-Escape> "destroy $top_elem"

	pack $buttons_frame.apply -side left -expand 1 -anchor e -padx 2
	pack $buttons_frame.cancel -side right -expand 1 -anchor w -padx 2
}

proc clearTempObjects { x y } {
	global main_canvas_elem all_annotation_types

	# clear existing temporary objects
	foreach object_type "link $all_annotation_types" {
		set object "new$object_type"
		global $object

		if { [set $object] != "" } {
			$main_canvas_elem delete [set $object]
			set $object ""

			$main_canvas_elem config -cursor left_ptr
		}
	}

	# catch error in case button1 wasn't clicked before
	catch { button1-release $x $y }
}
