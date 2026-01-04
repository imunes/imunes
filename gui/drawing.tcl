proc refreshToolBarNodes {} {
	global mf all_modules_list runnable_node_types

	catch { destroy $mf.left.link_nodes }
	catch { destroy $mf.left.net_nodes }

	menu $mf.left.link_nodes -title "Link layer nodes"
	menu $mf.left.net_nodes -title "Network layer nodes"

	foreach node_type $all_modules_list {
		set image [image create photo -file [$node_type.icon toolbar]]

		set tool ""
		if { [$node_type.netlayer] == "LINK" } {
			set tool "link"
		} elseif { [$node_type.netlayer] == "NETWORK" } {
			set tool "net"
		}

		set background_color ""
		if { $node_type ni $runnable_node_types } {
			global show_unsupported_nodes

			if { ! $show_unsupported_nodes } {
				continue
			}

			set background_color "-background \"#bc5555\" -activebackground \"#bc5555\""
		}

		$mf.left.${tool}_nodes add command -image $image -hidemargin 1 \
			-compound left -label [string range [$node_type.toolbarIconDescr] 8 end] \
			-command "setActiveTool ${tool}_layer $node_type" {*}$background_color
	}
}

#****f* editor.tcl/redrawAll
# NAME
#   redrawAll -- redraw all
# SYNOPSIS
#   redrawAll
# FUNCTION
#   Redraws all the objects on the current canvas.
#****
proc redrawAll {} {
	global background sizex sizey grid
	global show_background_image show_annotations show_grid bkgImage

	set zoom [getFromRunning_gui "zoom"]
	set curcanvas [getFromRunning_gui "curcanvas"]

	.bottom.zoom config -text "zoom [expr {int($zoom * 100)}]%"
	set e_sizex [expr {int($sizex * $zoom)}]
	set e_sizey [expr {int($sizey * $zoom)}]
	set border 28
	.panwin.f1.c configure -scrollregion \
		"-$border -$border [expr {$e_sizex + $border}] \
		[expr {$e_sizey + $border}]"

	.panwin.f1.c delete all

	set canvasBkgImage [getCanvasBkg $curcanvas]
	if { $show_background_image == 1 && "$canvasBkgImage" != "" } {
		set ret [backgroundImage .panwin.f1.c $canvasBkgImage]
		if { "$ret" == 2 } {
			set background [.panwin.f1.c create rectangle 0 0 $e_sizex $e_sizey \
				-fill white -tags "background"]
		} else {
			set background [.panwin.f1.c create rectangle 0 0 $e_sizex $e_sizey \
				-tags "background"]
		}
	} else {
		set background [.panwin.f1.c create rectangle 0 0 $e_sizex $e_sizey \
			-fill white -tags "background"]
	}

	if { $show_annotations == 1 } {
		foreach annotation_id [getFromRunning_gui "annotation_list"] {
			if { [getAnnotationCanvas $annotation_id] == $curcanvas } {
				drawAnnotation $annotation_id
			}
		}
	}

	# Grid
	set e_grid [expr {int($grid * $zoom)}]
	set e_grid2 [expr {$e_grid * 2}]
	if { $show_grid } {
		for { set x $e_grid } { $x < $e_sizex } { incr x $e_grid } {
			if { [expr {$x % $e_grid2}] != 0 } {
				if { $zoom > 0.5 } {
					.panwin.f1.c create line $x 1 $x $e_sizey \
						-fill gray -dash {1 7} -tags "grid"
				}
			} else {
				.panwin.f1.c create line $x 1 $x $e_sizey -fill gray -dash {1 3} \
					-tags "grid"
			}
		}
		for { set y $e_grid } { $y < $e_sizey } { incr y $e_grid } {
			if { [expr {$y % $e_grid2}] != 0 } {
				if { $zoom > 0.5 } {
					.panwin.f1.c create line 1 $y $e_sizex $y \
						-fill gray -dash {1 7} -tags "grid"
				}
			} else {
				.panwin.f1.c create line 1 $y $e_sizex $y -fill gray -dash {1 3} \
					-tags "grid"
			}
		}
	}

	.panwin.f1.c lower -withtags background

	foreach node_id [getFromRunning "node_list"] {
		set node_canvas [getNodeCanvas $node_id]
		if { $node_canvas == "" } {
			set node_canvas $curcanvas
			setNodeCanvas $node_id $curcanvas
		}

		if { $node_canvas == $curcanvas } {
			drawNode $node_id

			foreach iface_id [ifcList $node_id] {
				set pseudo_id [getPseudoNodeFromNodeIface $node_id $iface_id]
				if { $pseudo_id != "" } {
					set link_id [getIfcLink $node_id $iface_id]
					if { $link_id == "" } {
						removeNodeGUI $pseudo_id

						continue
					}

					drawPseudoNode $pseudo_id
				}
			}
		}
	}

	foreach link_id [getFromRunning "link_list"] {
		drawLink $link_id
		redrawLink $link_id
		updateLinkLabel $link_id
	}

	updateIconSize
	.panwin.f1.c config -cursor left_ptr
	raiseAll .panwin.f1.c
}

#****f* editor.tcl/drawNode
# NAME
#   drawNode -- draw a node
# SYNOPSIS
#   drawNode node_id
# FUNCTION
#   Draws the specified node. Draws node's image (router pc
#   host lanswitch frswitch rj45 hub pseudo) and label.
#   The visibility of the label depends on the show_node_labels
#   variable for all types of nodes and on invisible variable
#   for pseudo nodes.
# INPUTS
#   * node_id -- node id
#****
proc drawNode { node_id } {
	global show_node_labels runnable_node_types

	if { [isPseudoNode $node_id] } {
		drawPseudoNode $node_id

		return
	}

	set type [getNodeType $node_id]
	if { $type == "" } {
		cfgUnset "nodes" $node_id
		cfgUnset "gui" "nodes" $node_id
		return
	}

	set zoom [getFromRunning_gui "zoom"]
	lassign [lmap coord [getNodeCoords $node_id] {expr $coord * $zoom}] x y
	if { $x == "" || $y == "" } {
		global ${type}_iconheight

		lassign [getCanvasSize [getFromRunning "curcanvas"]] cx cy
		set x [expr round(rand()*($cx - $cx/3) + $cx/6)]
		set y [expr round(rand()*($cy - $cy/3) + $cy/6)]
		setNodeCoords $node_id "$x $y"

		set dy [expr [set [getNodeType $node_id]\_iconheight]/2 + 11]
		setNodeLabelCoords $node_id "$x [expr $y + $dy]"
	}

	.panwin.f1.c delete -withtags "node && $node_id"
	.panwin.f1.c delete -withtags "nodedisabled && $node_id"
	.panwin.f1.c delete -withtags "node_running && $node_id"
	.panwin.f1.c delete -withtags "nodelabel && $node_id"

	set custom_icon [getNodeCustomIcon $node_id]
	if { $custom_icon == "" } {
		global $type $type\_running

		.panwin.f1.c create image $x $y -image [set $type] -tags "node $node_id"
		set image_w [image width [set $type]]
		set image_h [image height [set $type]]
	} else {
		global icon_size

		switch $icon_size {
			normal {
				set icon_data [getImageData $custom_icon]
				image create photo img_$custom_icon -data $icon_data
				.panwin.f1.c create image $x $y -image img_$custom_icon -tags "node $node_id"
			}
			small {
				set icon_data [getImageData $custom_icon]
				image create photo img_$custom_icon -data $icon_data
				set img_$custom_icon [image% img_$custom_icon 70 $custom_icon]
				.panwin.f1.c create image $x $y -image [set img_$custom_icon] -tags "node $node_id"
			}
		}

		set image_w [image width img_$custom_icon]
		set image_h [image height img_$custom_icon]
	}

	if { $type ni $runnable_node_types } {
		global defaultFontSize

		.panwin.f1.c create text $x [expr $y - int($image_h/2) - 1.3*$defaultFontSize] \
			-fill "#ff0c0c" -text "DISABLED" -tags "nodedisabled $node_id" -justify center \
			-font "imnDisabledFont" -state disabled
	}

	if { ! [dict exist [cfgGet "gui" "nodes" $node_id] "label"] } {
		set label_str [getNodeName $node_id]
		setNodeLabel $node_id $label_str
	} else {
		set label_str [getNodeLabel $node_id]
	}

	if { [getNodeType $node_id] == "ext" } {
		set nat_iface [getNodeNATIface $node_id]
		if { $nat_iface != "UNASSIGNED" } {
			set label_str "NAT-$nat_iface"
		}
	}

	set has_empty_ifaces 0
	foreach iface_id [ifcList $node_id] {
		set link_id [getIfcLink $node_id $iface_id]
		if { $type == "wlan" } {
			set label_str "$label_str [getIfcIPv4addrs $node_id $iface_id]"
		} elseif { $link_id == "" } {
			if { [getIfcType $node_id $iface_id] == "stolen" } {
				set iflabel "\[[getIfcName $node_id $iface_id]\]"
			} else {
				set iflabel "[getIfcName $node_id $iface_id]"
			}

			if { $has_empty_ifaces == 0 } {
				set label_str "\n$label_str\n$iflabel"
				set has_empty_ifaces 1
			} else {
				set label_str "$label_str $iflabel"
			}
		}
	}

	if { [getFromRunning "${node_id}_running"] == "true" } {
		global running_indicator_palette running_mask_image

		.panwin.f1.c create image \
			[expr $x - $image_w/3] \
			[expr $y + $image_h/4] \
			-image $running_mask_image -tags "node_running $node_id"

		set color [lindex $running_indicator_palette end]
	} else {
		set color blue
	}

	lassign [lmap coord [getNodeLabelCoords $node_id] {expr int($coord * $zoom)}] x y
	set label_elem [.panwin.f1.c create text $x $y -fill $color \
		-text "$label_str" -tags "nodelabel $node_id" -justify center]

	if { $show_node_labels == 0 } {
		.panwin.f1.c itemconfigure $label_elem -state hidden
	}
}

proc drawPseudoNode { node_id } {
	global show_node_labels invisible pseudo

	.panwin.f1.c delete -withtags "node && $node_id"
	.panwin.f1.c delete -withtags "nodelabel && $node_id"

	set zoom [getFromRunning_gui "zoom"]
	lassign [lmap coord [getNodeCoords $node_id] {expr int($coord * $zoom)}] x y
	.panwin.f1.c create image $x $y \
		-image $pseudo \
		-tags "node $node_id"

	set color blue

	set mirror_node_id [getNodeMirror $node_id]
	lassign [nodeFromPseudoNode $mirror_node_id] peer_id peer_iface_id
	set peer_iface_name [getIfcName $peer_id $peer_iface_id]
	if { [getIfcVlanDev $peer_id $peer_iface_id] != "" } {
		set vlan_tag [getIfcVlanTag $peer_id $peer_iface_id]
		if { $vlan_tag != "" } {
			append peer_iface_name "_$vlan_tag"
		}
	}
	set label_str "[getNodeName $peer_id]:$peer_iface_name"

	set peer_canvas [getNodeCanvas $peer_id]
	if { $peer_canvas != [getFromRunning_gui "curcanvas"] } {
		set label_str "$label_str\n@[getCanvasName $peer_canvas]"
	}

	lassign [lmap coord [getNodeLabelCoords $node_id] {expr int($coord * $zoom)}] x y
	set label_elem [.panwin.f1.c create text $x $y \
		-fill $color \
		-text "$label_str" \
		-tags "nodelabel $node_id" \
		-justify center]

	# XXX Invisible pseudo-nodes
	if { $show_node_labels == 0 || $invisible == 1 } {
		.panwin.f1.c itemconfigure $label_elem -state hidden
	}
}

#****f* editor.tcl/drawLink
# NAME
#   drawLink -- draw a link
# SYNOPSIS
#   drawLink link_id
# FUNCTION
#   Draws the specified link. An arrow is displayed for links
#   connected to pseudo nodes. If the variable invisible
#   is specified link connecting a pseudo node stays hidden.
# INPUTS
#   * link_id -- link id
#****
proc drawLink { link_id } {
	set curcanvas [getFromRunning_gui "curcanvas"]
	lassign [getLinkPeers_gui $link_id] node1_id node2_id
	if { $node1_id == "" || $node2_id == "" } {
		lassign [getLinkPeers $link_id] node1_id node2_id
		setLinkPeers_gui $link_id "$node1_id $node2_id"
	}

	if {
		[getNodeCanvas $node1_id] != $curcanvas &&
		[getNodeCanvas $node2_id] != $curcanvas
	} {
		return
	}

	lassign [getPseudoLinksFromLink $link_id] pseudo1_link_id pseudo2_link_id

	# only one node cannot have pseudo by itself
	if { $pseudo1_link_id != "" && $pseudo2_link_id != "" } {
		drawPseudoLink $pseudo1_link_id
		drawPseudoLink $pseudo2_link_id

		return
	}

	lassign [getLinkPeers_gui $link_id] node1_id node2_id
	if { [getNodeType $node1_id] == "wlan" || [getNodeType $node2_id] == "wlan" } {
		return
	}

	set lwidth [getLinkWidth $link_id]
	set newlink [.panwin.f1.c create line 0 0 0 0 \
		-fill [getLinkColor $link_id] \
		-width $lwidth \
		-tags "link $link_id $node1_id $node2_id"]

	.panwin.f1.c raise $newlink background
	set newlink [.panwin.f1.c create line 0 0 0 0 \
		-fill white -width [expr {$lwidth + 4}] \
		-tags "link $link_id $node1_id $node2_id"]
	.panwin.f1.c raise $newlink background

	set ang [calcAngle $link_id]

	.panwin.f1.c create text 0 0 -tags "linklabel $link_id" -justify center -angle $ang
	.panwin.f1.c create text 0 0 -tags "interface $node1_id $link_id" -justify center -angle $ang
	.panwin.f1.c create text 0 0 -tags "interface $node2_id $link_id" -justify center -angle $ang

	.panwin.f1.c raise linklabel "link || background"
	.panwin.f1.c raise interface "link || linklabel || background"
}

proc drawPseudoLink { link_id } {
	global invisible

	lassign [getLinkPeers_gui $link_id] node1_id node2_id

	set lwidth [getLinkWidth $link_id]
	set newlink [.panwin.f1.c create line 0 0 0 0 \
		-fill [getLinkColor $link_id] -width $lwidth \
		-tags "link $link_id $node1_id $node2_id" -arrow both]

	.panwin.f1.c raise $newlink background
	set newlink [.panwin.f1.c create line 0 0 0 0 \
		-fill white -width [expr {$lwidth + 4}] \
		-tags "link $link_id $node1_id $node2_id"]
	.panwin.f1.c raise $newlink background

	set ang [calcAngle $link_id]

	.panwin.f1.c create text 0 0 -tags "linklabel $link_id" -justify center -angle $ang
	.panwin.f1.c create text 0 0 -tags "interface $node1_id $link_id" -justify center -angle $ang
	.panwin.f1.c create text 0 0 -tags "interface $node2_id $link_id" -justify center -angle $ang

	.panwin.f1.c raise linklabel "link || background"
	.panwin.f1.c raise interface "link || linklabel || background"

	# XXX Invisible pseudo-links
	if { $invisible == 1 } {
		.panwin.f1.c itemconfigure $link_id -state hidden
	}
}

#****f* editor.tcl/calcAnglePoints
# NAME
#   calcAnglePoints -- calculate angle between two points
# SYNOPSIS
#   calcAnglePoints $x1 $y1 $x2 $y2
# FUNCTION
#   Calculates the angle between two points.
# INPUTS
#   * x1 -- X coordinate of point1
#   * y1 -- Y coordinate of point1
#   * x2 -- X coordinate of point2
#   * y2 -- Y coordinate of point2
#****
proc calcAnglePoints { x1 y1 x2 y2 } {
	set zoom [getFromRunning_gui "zoom"]
	set x1 [expr $x1*$zoom]
	set y1 [expr $y1*$zoom]
	set x2 [expr $x2*$zoom]
	set y2 [expr $y2*$zoom]
	if { [expr $x2 - $x1] == 0 } {
		set arad 0
	} else {
		set arad [expr {atan(($y2-$y1)/($x2-$x1))}]
	}

	set ang [expr {$arad*180/3.14159}]
	if { $ang < 0 } {
		set ang [expr {$ang+360}]
	}

	set ang [expr {360-$ang}]
	if { $ang > 225 && $ang < 315 || $ang > 45 && $ang < 135 || $ang == 360 } {
		set ang 0
	}

	return $ang
}

proc isPseudoNode { node_id } {
	return [expr { [string first "." $node_id] != -1 }]
}

proc isPseudoLink { link_id } {
	return [expr { [string first "." $link_id] != -1 }]
}

#****f* editor.tcl/calcAngle
# NAME
#   calcAngle -- calculate angle between two points
# SYNOPSIS
#   calcAngle $link_id
# FUNCTION
#   Calculates the angle of the link that connects 2 nodes.
#   Used to calculate the rotation angle of link and interface labels.
# INPUTS
#   * link_id -- link which rotation angle needs to be calculated.
#****
proc calcAngle { link_id } {
	lassign [getLinkPeers_gui $link_id] node1_id node2_id
	lassign [getNodeCoords $node1_id] x1 y1
	lassign [getNodeCoords $node2_id] x2 y2

	return [calcAnglePoints $x1 $y1 $x2 $y2]
}

#****f* editor.tcl/updateIfcLabel
# NAME
#   updateIfcLabel -- update interface label
# SYNOPSIS
#   updateIfcLabel $link_id $node_id $iface_id
# FUNCTION
#   Updates the interface label, including interface name,
#   interface state (* for interfaces that are down), IPv4
#   address and IPv6 address.
# INPUTS
#   * link_id -- link id to update
#   * node_id -- node id of a node where the interface resides
#   * iface_id -- interface to update
#****
proc updateIfcLabel { link_id node_id iface_id } {
	global show_interface_names show_interface_ipv4 show_interface_ipv6

	set ifipv4addr [getIfcIPv4addrs $node_id $iface_id]
	set ifipv6addr [getIfcIPv6addrs $node_id $iface_id]
	if { $iface_id == 0 } {
		set iface_id ""
	}

	set label_str ""
	if { $show_interface_names } {
		if { [getNodeType $node_id] == "rj45" } {
			lappend label_str "$iface_id - [getIfcName $node_id $iface_id]"
			if { [getIfcVlanDev $node_id $iface_id] != "" && [getIfcVlanTag $node_id $iface_id] != "" } {
				lappend label_str "VLAN [getIfcVlanTag $node_id $iface_id]"
			}
		} else {
			lappend label_str "[getIfcName $node_id $iface_id]"
		}
	}

	if { $show_interface_ipv4 && $ifipv4addr != "" } {
		if { [llength $ifipv4addr] > 1 } {
			lappend label_str "[lindex $ifipv4addr 0] ..."
		} else {
			lappend label_str "$ifipv4addr"
		}
	}

	if { $show_interface_ipv6 && $ifipv6addr != "" } {
		if { [llength $ifipv6addr] > 1 } {
			lappend label_str "[lindex $ifipv6addr 0] ..."
		} else {
			lappend label_str "$ifipv6addr"
		}
	}

	set str ""
	if { [getIfcOperState $node_id $iface_id] == "down" } {
		set str "*"
	}

	if { [getIfcNatState $node_id $iface_id] == "on" } {
		set str "${str}NAT-"
	}

	foreach elem $label_str {
		if { $str in "{} * NAT- *NAT-" } {
			set str "$str[set elem]"
		} else {
			set str "$str\r[set elem]"
		}
	}

	.panwin.f1.c itemconfigure "interface && $node_id && $link_id" \
		-text $str
}

#****f* editor.tcl/updateLinkLabel
# NAME
#   updateLinkLabel -- update link label
# SYNOPSIS
#   updateLinkLabel $link_id
# FUNCTION
#   Updates the link label, including link bandwidth, link delay,
#   BER, loss and duplicate values.
# INPUTS
#   * link_id -- link id of the link whose labels are updated.
#****
proc updateLinkLabel { link_id } {
	global show_link_labels linkJitterConfiguration

	if { [isPseudoLink $link_id] } {
		lassign [linkFromPseudoLink $link_id] link_id - -
		set pseudo1_link_id ""
		set pseudo2_link_id ""
	} else {
		lassign [getPseudoLinksFromLink $link_id] pseudo1_link_id pseudo2_link_id
	}

	if { [getLinkDirect $link_id ] } {
		set str "direct"
	} else {
		set label_str ""
		set bwstr "[getLinkBandwidthString $link_id]"
		set delstr [getLinkDelayString $link_id]
		set ber [getLinkBER $link_id]
		set loss [getLinkLoss $link_id]
		set dup [getLinkDup $link_id]
		set jitter [concat [getLinkJitterUpstream $link_id] [getLinkJitterDownstream $link_id]]
		if { "$bwstr" != "" } {
			lappend label_str $bwstr
		}
		if { "$delstr" != "" } {
			lappend label_str $delstr
		}
		if { $jitter != "" && $linkJitterConfiguration == 1 } {
			lappend label_str "jitter"
		}
		if { "$ber" != "" } {
			lappend label_str "ber=$ber"
		}
		if { "$loss" != "" } {
			lappend label_str "loss=$loss%"
		}
		if { "$dup" != "" } {
			lappend label_str "dup=$dup%"
		}

		set str ""
		foreach elem $label_str {
			if { $str == "" } {
				set str "$str[set elem]"
			} else {
				set str "$str\r[set elem]"
			}
		}
	}

	set curcanvas [getFromRunning_gui "curcanvas"]

	# only one node cannot have pseudo by itself
	if { $pseudo1_link_id != "" && $pseudo2_link_id != "" } {
		foreach link_id "$pseudo1_link_id $pseudo2_link_id" {
			lassign [getLinkPeers_gui $link_id] node1_id node2_id
			if {
				[getNodeCanvas $node1_id] != $curcanvas &&
				[getNodeCanvas $node2_id] != $curcanvas
			} {
				continue
			}

			set ang [calcAngle $link_id]
			.panwin.f1.c itemconfigure "linklabel && $link_id" -text $str -angle $ang
			if { $show_link_labels == 0 } {
				.panwin.f1.c itemconfigure "linklabel && $link_id" -state hidden
			}
		}

		return
	}

	lassign [getLinkPeers_gui $link_id] node1_id node2_id
	if {
		[getNodeCanvas $node1_id] != $curcanvas &&
		[getNodeCanvas $node2_id] != $curcanvas
	} {
		return
	}

	set ang [calcAngle $link_id]
	.panwin.f1.c itemconfigure "linklabel && $link_id" -text $str -angle $ang
	if { $show_link_labels == 0 } {
		.panwin.f1.c itemconfigure "linklabel && $link_id" -state hidden
	}
}

#****f* editor.tcl/redrawAllLinks
# NAME
#   redrawAllLinks -- redraw all links
# SYNOPSIS
#   redrawAllLinks
# FUNCTION
#   Redraws all links on the current canvas.
#****
proc redrawAllLinks {} {
	foreach link_id [getFromRunning "link_list"] {
		redrawLink $link_id
	}
}

#****f* editor.tcl/redrawLink
# NAME
#   redrawLink -- redraw a link
# SYNOPSIS
#   redrawLink $link_id
# FUNCTION
#   Redraws the specified link.
# INPUTS
#   * link_id -- link id
#****
proc redrawLink { link_id } {
	set curcanvas [getFromRunning_gui "curcanvas"]
	lassign [getLinkPeers_gui $link_id] node1_id node2_id
	if {
		[getNodeCanvas $node1_id] != $curcanvas &&
		[getNodeCanvas $node2_id] != $curcanvas
	} {
		return
	}

	if { [isPseudoLink $link_id] } {
		redrawPseudoLink $link_id

		return
	}

	lassign [getPseudoLinksFromLink $link_id] pseudo1_link_id pseudo2_link_id

	# only one node cannot have pseudo by itself
	if { $pseudo1_link_id != "" && $pseudo2_link_id != "" } {
		redrawPseudoLink $pseudo1_link_id
		redrawPseudoLink $pseudo2_link_id

		return
	}

	lassign [.panwin.f1.c find withtag "link && $link_id"] limage1 limage2
	if { $limage1 == "" || $limage2 == "" } {
		return
	}

	lassign [.panwin.f1.c gettags $limage1] {} link_id node1_id node2_id
	if { [getNodeType $node1_id] == "wlan" || [getNodeType $node2_id] == "wlan" } {
		return
	}

	lassign [.panwin.f1.c coords "node && $node1_id"] x1 y1
	lassign [.panwin.f1.c coords "node && $node2_id"] x2 y2
	.panwin.f1.c coords $limage1 $x1 $y1 $x2 $y2
	.panwin.f1.c coords $limage2 $x1 $y1 $x2 $y2

	set lx [expr {int(0.5 * ($x1 + $x2))}]
	set ly [expr {int(0.5 * ($y1 + $y2))}]
	.panwin.f1.c coords "linklabel && $link_id" $lx $ly

	lassign [getLinkPeersIfaces $link_id] iface1_id iface2_id
	updateIfcLabelParams $link_id $node1_id $iface1_id $x1 $y1 $x2 $y2
	updateIfcLabel $link_id $node1_id $iface1_id

	updateIfcLabelParams $link_id $node2_id $iface2_id $x2 $y2 $x1 $y1
	updateIfcLabel $link_id $node2_id $iface2_id
}

proc redrawPseudoLink { link_id } {
	set curcanvas [getFromRunning_gui "curcanvas"]
	lassign [getLinkPeers_gui $link_id] node1_id node2_id
	if {
		[getNodeCanvas $node1_id] != $curcanvas &&
		[getNodeCanvas $node2_id] != $curcanvas
	} {
		return
	}

	lassign [.panwin.f1.c find withtag "link && $link_id"] limage1 limage2
	if { $limage1 == "" || $limage2 == "" } {
		return
	}

	lassign [.panwin.f1.c gettags $limage1] {} {} node1_id node2_id
	if { [getNodeType $node1_id] == "wlan" || [getNodeType $node2_id] == "wlan" } {
		return
	}

	lassign [.panwin.f1.c coords "node && $node1_id"] x1 y1
	if { $x1 == "" || $y1 == "" } {
		lassign [getNodeLabelCoords $node1_id] x1 y1
	}
	lassign [.panwin.f1.c coords "node && $node2_id"] x2 y2
	if { $x2 == "" || $y2 == "" } {
		lassign [getNodeLabelCoords $node2_id] x2 y2
	}

	.panwin.f1.c coords $limage1 $x1 $y1 $x2 $y2
	.panwin.f1.c coords $limage2 $x1 $y1 $x2 $y2

	if { [isPseudoNode $node1_id] } {
		set lx [expr {int(0.25 * ($x2 - $x1) + $x1)}]
		set ly [expr {int(0.25 * ($y2 - $y1) + $y1)}]
	} elseif { [isPseudoNode $node2_id] } {
		set lx [expr {int(0.75 * ($x2 - $x1) + $x1)}]
		set ly [expr {int(0.75 * ($y2 - $y1) + $y1)}]
	}
	.panwin.f1.c coords "linklabel && $link_id" $lx $ly

	lassign [linkFromPseudoLink $link_id] real_link_id real_node_id real_iface_id

	updateIfcLabelParams $link_id $real_node_id $real_iface_id $x2 $y2 $x1 $y1
	updateIfcLabel $link_id $real_node_id $real_iface_id
}

proc updateIfcLabelParams { link_id node_id iface_id x1 y1 x2 y2 } {
	global show_interface_ipv4 show_interface_ipv6 show_interface_names

	set bbox [.panwin.f1.c bbox "node && $node_id"]
	set iconwidth [expr [lindex $bbox 2] - [lindex $bbox 0]]
	set iconheight [expr [lindex $bbox 3] - [lindex $bbox 1]]

	set ang [calcAnglePoints $x1 $y1 $x2 $y2]
	set just "center"
	set anchor "center"

	set IP4 $show_interface_ipv4
	if { [getIfcIPv4addrs $node_id $iface_id] == {} } {
		set IP4 0
	}

	set IP6 $show_interface_ipv6
	if { [getIfcIPv6addrs $node_id $iface_id] == {} } {
		set IP6 0
	}

	set add_height [expr 10*($show_interface_names + $IP4 + $IP6)]
	if { [getNodeType $node_id] == "rj45" && [getIfcVlanDev $node_id $iface_id] != "" } {
		incr add_height [expr 10*$show_interface_names]
	}

	# these params could be called dy and dx, respectively
	# additional height represents the ifnames, ipv4 and ipv6 addrs
	set height [expr 8 + $iconheight/2 + $add_height]
	# 5 pixels from icon
	set width [expr $iconwidth/2 + 10]

	if { $ang == 0 } {
		if { $y1 == $y2 } {
			set just left
			set anchor w
			set lx [expr int($x1 + $width)]
			if { $x1 > $x2 } {
				set just right
				set anchor e
				set lx [expr int($x1 - $width)]
			}

			set ly $y1
		} else {
			set just center
			if { $y1 > $y2 } {
				set ly [expr int($y1 - $height)]
				set a [expr ($x1-$x2)/($y2-$y1)*2]
			} else {
				# when the iface label is located beneath the icon, shift it by 16
				# pixels because of the nodelabel
				set ly [expr int($y1 + $height + 10)]
				set a [expr ($x2-$x1)/($y2-$y1)*2]
			}

			set lx [expr int($a*$height + $x1)]
		}
	} else {
		if { $x1 > $x2 } {
			set just right
			set anchor e
			set lx [expr int($x1 - $width)]
			set a [expr ($y2-$y1)/($x1-$x2)]
		} else {
			set just left
			set anchor w
			set lx [expr int($x1 + $width)]
			set a [expr ($y2-$y1)/($x2-$x1)]
		}

		set ly [expr int($a*$width + $y1)]
	}

	.panwin.f1.c coords "interface && $node_id && $link_id" $lx $ly
	.panwin.f1.c itemconfigure "interface && $node_id && $link_id" -justify $just \
		-anchor $anchor -angle $ang
}

#****f* drawing.tcl/connectWithNode
# NAME
#   connectWithNode -- connect with a node
# SYNOPSIS
#   connectWithNode $nodes $target_node_id
# FUNCTION
#   This procedure calls newLinkGUI procedure to connect all given nodes with
#   the one node.
# INPUTS
#   * nodes -- list of all node ids to connect
#   * target_node_id -- node id of the node to connect to
#****
proc connectWithNode { nodes target_node_id } {
	foreach node_id $nodes {
		if { $node_id != $target_node_id } {
			newLinkGUI $node_id $target_node_id
		}
	}
}

#****f* editor.tcl/newLinkGUI
# NAME
#   newLinkGUI -- new GUI link
# SYNOPSIS
#   newLinkGUI $node1_id $node2_id
# FUNCTION
#   This procedure is called to create a new link between
#   nodes node1_id and node2_id. Nodes can be on the same canvas
#   or on different canvases. The result of this function
#   is directly visible in GUI.
# INPUTS
#   * node1_id -- node id of the first node
#   * node2_id -- node id of the second node
#****
proc newLinkGUI { node1_id node2_id } {
	return [newLinkWithIfacesGUI $node1_id "" $node2_id ""]
}

proc newLinkWithIfacesGUI { node1_id iface1_id node2_id iface2_id } {
	global changed

	if { [isPseudoNode $node1_id] || [isPseudoNode $node2_id] } {
		return
	}

	set link_id [newLinkWithIfaces $node1_id $iface1_id $node2_id $iface2_id]
	if { $link_id == "" } {
		return
	}

	setLinkPeers_gui $link_id "$node1_id $node2_id"

	set node1_canvas_id [getNodeCanvas $node1_id]
	set node2_canvas_id [getNodeCanvas $node2_id]
	if { $node1_canvas_id != $node2_canvas_id || $node1_id == $node2_id } {
		lassign [getLinkPeers $link_id] orig_node1_id orig_node2_id
		lassign [getLinkPeersIfaces $link_id] orig_iface1_id orig_iface2_id
		lassign [splitLink $link_id] new_node1_id new_node2_id

		setNodeCoords $new_node1_id [getNodeCoords $orig_node2_id]
		setNodeCoords $new_node2_id [getNodeCoords $orig_node1_id]
		setNodeLabelCoords $new_node1_id [getNodeCoords $new_node1_id]
		setNodeLabelCoords $new_node2_id [getNodeCoords $new_node2_id]

		setNodeCanvas $new_node1_id $node1_canvas_id
		setNodeCanvas $new_node2_id $node2_canvas_id
	}

	if { [getFromRunning "stop_sched"] } {
		redeployCfg
	}

	redrawAll
	set changed 1
	updateUndoLog
}

#****f* editor.tcl/raiseAll
# NAME
#   raiseAll -- raise all
# SYNOPSIS
#   raiseAll $c
# FUNCTION
#   Raises all elements on canvas.
# INPUTS
#   * c -- tk canvas
#****
proc raiseAll { c } {
	$c raise grid background
	$c raise rectangle  "grid || background"
	$c raise oval "rectangle || grid || background"
	$c raise link "oval || rectangle || grid || background"
	$c raise freeform "link ||  oval || rectangle || grid || background"
	$c raise route "freeform || link || oval || rectangle || grid || background"
	$c raise linklabel "route || freeform || link || oval || rectangle || grid || background"
	$c raise interface "linklabel || route || freeform || link || oval || rectangle || grid || background"
	$c raise node "interface || linklabel || route || freeform || link || oval || rectangle || grid || background"
	$c raise nodelabel "node || interface || linklabel || route || freeform || link || oval || rectangle || grid || background"
	$c raise text "nodelabel || node || interface || linklabel || route || freeform || link || oval || rectangle || grid || background"
}

#****f* editor.tcl/changeIconPopup
# NAME
#   changeIconPopup -- change icon popup
# SYNOPSIS
#   changeIconPopup
# FUNCTION
#   Creates a popup dialog to change an icon.
#****
proc changeIconPopup {} {
	global chicondialog alignCanvasBkg iconsrcfile wi
	global ROOTDIR LIBDIR

	set chicondialog .chiconDialog
	catch { destroy $chicondialog }

	toplevel $chicondialog
	wm transient $chicondialog .
	wm resizable $chicondialog 0 0
	wm title $chicondialog "Set custom icon"
	wm iconname $chicondialog "Set custom icon"

	set wi [ttk::frame $chicondialog.changebgframe]

	ttk::panedwindow $wi.iconconf -orient horizontal
	pack $wi.iconconf -fill both

	#left and right pane
	ttk::frame $wi.iconconf.left -relief groove -borderwidth 3
	ttk::frame $wi.iconconf.right -relief groove -borderwidth 3

	#right pane definition
	ttk::frame $wi.iconconf.right.spacer -height 20
	pack $wi.iconconf.right.spacer -fill both
	ttk::label $wi.iconconf.right.l -text "Icon preview"
	pack $wi.iconconf.right.l -anchor center

	set prevcan [canvas $wi.iconconf.right.pc -bd 0 -relief sunken -highlightthickness 0 \
		-width 100 -height 100 -background white]
	pack $prevcan -anchor center

	ttk::label $wi.iconconf.right.l2 -text "Size:"
	pack $wi.iconconf.right.l2 -anchor center

	#left pane definition
	#upper left frame with treeview
	ttk::frame $wi.iconconf.left.up
	pack $wi.iconconf.left.up -anchor w -expand 1 -fill both

	ttk::frame $wi.iconconf.left.up.grid
	pack $wi.iconconf.left.up.grid -expand 1 -fill both

	set tree $wi.iconconf.left.up.tree
	ttk::treeview $tree -columns "type" -height 5 -selectmode browse \
		-xscrollcommand "$wi.iconconf.left.up.hscroll set"\
		-yscrollcommand "$wi.iconconf.left.up.vscroll set"
	ttk::scrollbar $wi.iconconf.left.up.hscroll -orient horizontal -command "$wi.iconconf.left.up.tree xview"
	ttk::scrollbar $wi.iconconf.left.up.vscroll -orient vertical -command "$wi.iconconf.left.up.tree yview"

	grid $wi.iconconf.left.up.tree $wi.iconconf.left.up.vscroll -in $wi.iconconf.left.up.grid -sticky nsew
	#disabled for now, if the addition of new columns happens it will be useful
	#grid $wi.iconconf.left.up.hscroll -in $wi.iconconf.left.up.grid -sticky nsew
	grid columnconfig $wi.iconconf.left.up.grid 0 -weight 1
	grid rowconfigure $wi.iconconf.left.up.grid 0 -weight 1

	$tree heading #0 -text "Image name"
	$tree column #0 -width 100 -minwidth 100
	$tree heading type -text "Type"
	$tree column type -width 90 -stretch 0 -minwidth 90
	focus $tree

	set set_iconsrcfile_command {
		{ wi previous_canvas file_path } {
			if { $file_path == "" } {
				return
			}

			global iconsrcfile

			updateIconPreview $previous_canvas $wi.iconconf.right.l2 $file_path
			set iconsrcfile $file_path
		}
	}

	set file_paths [glob -directory $ROOTDIR/$LIBDIR/icons/normal/ *.gif]
	foreach file_path $file_paths {
		$tree insert {} end \
			-id $file_path \
			-text [lindex [split $file_path /] end] \
			-values [list "library icon"] \
			-tags "$file_path"
	}

	set image_list [getFromRunning_gui "image_list"]
	foreach img $image_list {
		if {
			$img == "" ||
			[string match "*image*" $img] != 1 ||
			[getImageType $img] != "customIcon"
		} {
			set image_list [removeFromList $image_list $img]
			continue
		}

		$tree insert {} end \
			-id $img \
			-text $img \
			-values [list "custom icon"] \
			-tags "$img"
	}

	# set last argument as empty string
	foreach file_path [concat $file_paths $image_list] {
		set tmp_command [list apply $set_iconsrcfile_command \
			$wi \
			$prevcan \
			""
		]

		# replace last argument for each binding
		$tree tag bind $file_path <1> \
			[lreplace $tmp_command end end $file_path]
		$tree tag bind $file_path <Key-Up> \
			[lreplace $tmp_command end end [$tree prev $file_path]]
		$tree tag bind $file_path <Key-Down> \
			[lreplace $tmp_command end end [$tree next $file_path]]
	}

	set first [lindex [concat $file_paths $image_list] 0]
	$tree selection set $first
	$tree focus $first

	#center left frame with label
	ttk::frame $wi.iconconf.left.center
	pack $wi.iconconf.left.center -anchor w
	ttk::label $wi.iconconf.left.center.l -text "Custom icon file:"

	#down left frame with entry and button
	ttk::frame $wi.iconconf.left.down
	ttk::frame $wi.iconconf.left.down.left
	ttk::frame $wi.iconconf.left.down.right
	pack $wi.iconconf.left.down -fill both -padx 10
	pack $wi.iconconf.left.down.left $wi.iconconf.left.down.right \
		-side left -anchor n -padx 2

	ttk::entry $wi.iconconf.left.down.left.e -width 25 -textvariable iconFile

	set tmp_command {
		set fType {
			{{All Images} {.gif}  {}}
			{{All Images} {.png}  {}}
			{{Gif Images} {.gif}  {}}
			{{PNG Images} {.png} {}}
		}
		#{{All Images} {.jpeg} {}}
		#{{All Images} {.jpg}  {}}
		#{{All Images} {.bmp}  {}}
		#{{All Images} {.tiff} {}}
		#{{All Images} {.ico}  {}}
		#{{Jpeg Images} {.jpg} {}}
		#{{Jpeg Images} {.jpeg} {}}
		#{{Bitmap Images} {.bmp} {}}
		#{{Tiff Images} {.tiff} {}}
		#{{Icon Images} {.ico} {}}
		global canvasBkgMode wi

		set chicondialog .chiconDialog
		set prevcan $wi.iconconf.right.pc
		set imgsize $wi.iconconf.right.l2
		set iconsrcfile [tk_getOpenFile -parent $chicondialog -filetypes $fType]
		$wi.iconconf.left.down.left.e delete 0 end
		$wi.iconconf.left.down.left.e insert 0 "$iconsrcfile"
		if { $iconsrcfile != "" } {
			image create photo iconprev -file $iconsrcfile
			set image_h [image height iconprev]
			set image_w [image width iconprev]
			image delete iconprev
			if { $image_h > 100 || $image_w > 100 } {
				set iconsrcfile ""
				$wi.iconconf.left.down.left.e delete 0 end
				$wi.iconconf.left.down.left.e insert 0 "$iconsrcfile"
				$imgsize configure -text "Size:"
				tk_dialog .dialog1 "IMUNES error" \
					"Error: Icon dimensions can't be bigger than 100x100. This image is $image_w*$image_h." \
					info 0 Dismiss
				return
			}
			updateIconPreview $prevcan $imgsize $iconsrcfile
		}
	}
	ttk::button $wi.iconconf.left.down.right.b -text "Browse" -width 8 \
		-command $tmp_command

	if { $iconsrcfile != "" } {
		set prevcan $wi.iconconf.right.pc
		set imgsize $wi.iconconf.right.l2
		updateIconPreview $prevcan $imgsize $iconsrcfile
	}

	#packing left side
	pack $wi.iconconf.left.center.l -anchor w -pady 2
	pack $wi.iconconf.left.down.left.e -pady 6
	pack $wi.iconconf.left.down.right.b -pady 4
	pack $wi -fill both

	#adding panes to paned window
	$wi.iconconf add $wi.iconconf.left
	$wi.iconconf add $wi.iconconf.right

	#lower frame that contains buttons
	ttk::frame $wi.buttons
	pack $wi.buttons -side bottom -fill x -pady 2m
	ttk::button $wi.buttons.apply -text "Apply" -command {
		popupIconApply $chicondialog $iconsrcfile
	}
	ttk::button $wi.buttons.cancel -text "Cancel" -command "destroy $chicondialog"
	ttk::button $wi.buttons.remove -text "Remove custom icon" -command \
		"destroy $chicondialog; setDefaultIcon"
	pack $wi.buttons.remove $wi.buttons.cancel $wi.buttons.apply -side right -expand 1

	bind $chicondialog <Key-Return> { popupIconApply $chicondialog $iconsrcfile }
	bind $chicondialog <Key-Escape> "destroy $chicondialog"
}

#****f* editor.tcl/updateIconPreview
# NAME
#   updateIconPreview -- update icon preview
# SYNOPSIS
#   updateIconPreview $pc $imgsize $image
# FUNCTION
#   Updates icon preview.
# INPUTS
#   * pc -- selected pc
#   * imgsize -- image size
#   * image -- image file
#****
proc updateIconPreview { pc imgsize image } {
	$pc delete "preview"

	if { ! [string match -nocase "*.*" $image] } {
		image create photo iconprev -data [getImageData $image]
	} else {
		image create photo iconprev -file $image
	}

	set image_h [image height iconprev]
	set image_w [image width iconprev]

	$imgsize configure -text "Size: $image_w*$image_h"

	$pc create image 50 50 -anchor center -image iconprev -tags "preview"
}

#****f* editor.tcl/popupIconApply
# NAME
#   popupIconApply -- popup icon apply
# SYNOPSIS
#   popupIconApply $dialog $image
# FUNCTION
#   This procedure is called when the button apply is pressed in
#   change icon popup dialog box.
# INPUTS
#   * dialog -- tk dialog
#   * image -- image file
#****
proc popupIconApply { dialog image } {
	global changed

	if { $image != "" } {
		set nodelist [selectedNodes]
		if { [string match -nocase "*.*" $image] } {
			set imgname [loadImage $image "" customIcon $image]
			foreach node_id $nodelist {
				set icon [getNodeCustomIcon $node_id]
				if { $icon != "" } {
					removeImageReference $icon $node_id
				}

				setNodeCustomIcon $node_id $imgname
				setImageReference $imgname $node_id
			}
		} else {
			foreach node_id $nodelist {
				set icon [getNodeCustomIcon $node_id]
				if { $icon != "" } {
					removeImageReference $icon $node_id
				}
				setNodeCustomIcon $node_id $image
				setImageReference $image $node_id
			}
		}

		redrawAll
		set changed 1
		updateUndoLog
	}

	destroy $dialog
}

#****f* editor.tcl/updateCustomIconReferences
# NAME
#   updateCustomIconReferences -- update custom icon references
# SYNOPSIS
#   updateCustomIconReferences
# FUNCTION
#   Updates custom icon references.
#****
proc updateCustomIconReferences {} {
	foreach node_id [getFromRunning "node_list"] {
		set icon [getNodeCustomIcon $node_id]
		if { $icon != "" } {
			setImageReference $icon $node_id
		}
	}
}

#****f* editor.tcl/updateIconSize
# NAME
#   updateIconSize -- update icon size
# SYNOPSIS
#   updateIconSize
# FUNCTION
#   Updates icon size.
#****
proc updateIconSize {} {
	global all_modules_list

	foreach b $all_modules_list {
		global $b icon_size
		set $b [image create photo -file [$b.icon $icon_size]]
	}
}

#****f* editor.tcl/selectZoomPopupMenu
# NAME
#   selectZoomPopupMenu -- select zoom popup menu
# SYNOPSIS
#   selectZoomPopupMenu $x $y
# FUNCTION
#   Creates select zoom popup menu on (x,y) coordinates
# INPUTS
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc selectZoomPopupMenu { x y } {
	global zoom_stops changed
	.button3menu delete 0 end

	set sel_zoom [getFromRunning_gui "zoom"]

	foreach z $zoom_stops {
		set tmp_command {
			setToRunning_gui "zoom" $sel_zoom

			redrawAll
			set changed 1
			updateUndoLog
		}
		.button3menu add radiobutton -label [expr {int($z*100)}] \
			-variable sel_zoom -value $z \
			-command $tmp_command
	}

	set x [winfo pointerx .]
	set y [winfo pointery .]
	tk_popup .button3menu $x $y
}

#****f* editor.tcl/align2grid
# NAME
#   align2grid -- align to grid
# SYNOPSIS
#   align2grid
# FUNCTION
#   Aligns all nodes to grid.
#****
proc align2grid {} {
	global sizex sizey grid changed

	set node_objects [.panwin.f1.c find withtag node]
	if { [llength $node_objects] == 0 } {
		return
	}

	set step [expr {$grid * 4}]

	for { set x $step } { $x <= [expr {$sizex - $step}] } { incr x $step } {
		for { set y $step } { $y <= [expr {$sizey - $step}] } { incr y $step } {
			if { [llength $node_objects] == 0 } {
				set changed 1
				updateUndoLog
				redrawAll

				return
			}

			set node_id [lindex [.panwin.f1.c gettags [lindex $node_objects 0]] 1]
			set node_objects [lreplace $node_objects 0 0]
			setNodeCoords $node_id "$x $y"
			set dy 32
			if { [getNodeType $node_id] in "router hub lanswitch rj45" } {
				set dy 24
			}

			setNodeLabelCoords $node_id "$x [expr {$y + $dy}]"
		}
	}
}

#****f* editor.tcl/rearrange
# NAME
#   rearrange -- rearrange
# SYNOPSIS
#   rearrange $mode
# FUNCTION
#   This procedure rearranges the position of nodes in imunes.
#   It can be used to rearrange all the nodes or only the selected
#   nodes.
# INPUTS
#   * mode -- when set to "selected" only the selected nodes will be
#   rearranged.
#****
proc rearrange { mode } {
	global autorearrange_enabled sizex sizey

	set curcanvas [getFromRunning_gui "curcanvas"]
	set zoom [getFromRunning_gui "zoom"]

	set autorearrange_enabled 1
	.menubar.tools entryconfigure "Auto rearrange all" -state disabled
	.menubar.tools entryconfigure "Auto rearrange selected" -state disabled
	.bottom.mbuf config -text "autorearrange"
	if { $mode == "selected" } {
		set tagmatch "node && selected"
	} else {
		set tagmatch "node"
	}
	set otime [clock clicks -milliseconds]
	set idlems 1
	while { $autorearrange_enabled } {
		set ntime [clock clicks -milliseconds]
		if { $otime == $ntime } {
			set dt 0.001
		} else {
			set dt [expr {($ntime - $otime) * 0.001}]
			if { $dt > 0.2 } {
				set dt 0.2
			}
			set otime $ntime
		}

		set objects [.panwin.f1.c find withtag $tagmatch]
		set peer_objects [.panwin.f1.c find withtag node]
		foreach obj $peer_objects {
			set node_id [lindex [.panwin.f1.c gettags $obj] 1]
			lassign [.panwin.f1.c coords $obj] x y
			set x [expr {$x / $zoom}]
			set y [expr {$y / $zoom}]
			set x_t($node_id) $x
			set y_t($node_id) $y

			if { $x > 0 } {
				set fx [expr {1000 / ($x * $x + 100)}]
			} else {
				set fx 10
			}
			set dx [expr {$sizex - $x}]
			if { $dx > 0 } {
				set fx [expr {$fx - 1000 / ($dx * $dx + 100)}]
			} else {
				set fx [expr {$fx - 10}]
			}

			if { $y > 0 } {
				set fy [expr {1000 / ($y * $y + 100)}]
			} else {
				set fy 10
			}
			set dy [expr {$sizey - $y}]
			if { $dy > 0 } {
				set fy [expr {$fy - 1000 / ($dy * $dy + 100)}]
			} else {
				set fy [expr {$fy - 10}]
			}
			set fx_t($node_id) $fx
			set fy_t($node_id) $fy
		}

		foreach obj $objects {
			set node_id [lindex [.panwin.f1.c gettags $obj] 1]
			set i [lsearch -exact $peer_objects $obj]
			set peer_objects [lreplace $peer_objects $i $i]
			set x $x_t($node_id)
			set y $y_t($node_id)
			foreach other_obj $peer_objects {
				set other [lindex [.panwin.f1.c gettags $other_obj] 1]
				set o_x $x_t($other)
				set o_y $y_t($other)
				set dx [expr {$x - $o_x}]
				set dy [expr {$y - $o_y}]
				set d [expr {hypot($dx, $dy)}]
				set d2 [expr {$d * $d}]
				if { $d == 0 } {
					set p_fx 20
					set p_fy 20
				} else {
					set p_fx [expr {1000.0 * $dx / ($d2 * $d + 100)}]
					set p_fy [expr {1000.0 * $dy / ($d2 * $d + 100)}]
					if { [linksByPeers $node_id $other] != {} } {
						set p_fx [expr {$p_fx - $dx * $d2 * .0000000005}]
						set p_fy [expr {$p_fy - $dy * $d2 * .0000000005}]
					}
				}
				set fx_t($node_id) [expr {$fx_t($node_id) + $p_fx}]
				set fy_t($node_id) [expr {$fy_t($node_id) + $p_fy}]
				set fx_t($other) [expr {$fx_t($other) - $p_fx}]
				set fy_t($other) [expr {$fy_t($other) - $p_fy}]
			}

			foreach link_id [getFromRunning "link_list"] {
				lassign [getLinkPeers $link_id] node1_id node2_id
				if {
					[getNodeCanvas $node1_id] != $curcanvas ||
					[getNodeCanvas $node2_id] != $curcanvas ||
					[getLinkMirror $link_id] != ""
				} {
					continue
				}

				if {
					[getNodeType $node1_id] == "wlan" ||
					[getNodeType $node2_id] == "wlan"
				} {
					continue
				}

				set coords0 [getNodeCoords $node1_id]
				set coords1 [getNodeCoords $node2_id]
				set o_x \
					[expr {([lindex $coords0 0] + [lindex $coords1 0]) * .5}]
				set o_y \
					[expr {([lindex $coords0 1] + [lindex $coords1 1]) * .5}]
				set dx [expr {$x - $o_x}]
				set dy [expr {$y - $o_y}]
				set d [expr {hypot($dx, $dy)}]
				set d2 [expr {$d * $d}]
				set fx_t($node_id) \
					[expr {$fx_t($node_id) + 500.0 * $dx / ($d2 * $d + 100)}]
				set fy_t($node_id) \
					[expr {$fy_t($node_id) + 500.0 * $dy / ($d2 * $d + 100)}]
			}
		}

		foreach obj $objects {
			set node_id [lindex [.panwin.f1.c gettags $obj] 1]
			if { [catch "set v_t($node_id)" v] } {
				set vx 0.0
				set vy 0.0
			} else {
				set vx [lindex $v_t($node_id) 0]
				set vy [lindex $v_t($node_id) 1]
			}
			set vx [expr {$vx + 1000.0 * $fx_t($node_id) * $dt}]
			set vy [expr {$vy + 1000.0 * $fy_t($node_id) * $dt}]
			set dampk [expr {0.5 + ($vx * $vx + $vy * $vy) * 0.00001}]
			set vx [expr {$vx * exp( - $dampk * $dt)}]
			set vy [expr {$vy * exp( - $dampk * $dt)}]
			set dx [expr {$vx * $dt}]
			set dy [expr {$vy * $dt}]
			set x [expr {$x_t($node_id) + $dx}]
			set y [expr {$y_t($node_id) + $dy}]
			set v_t($node_id) "$vx $vy"

			setNodeCoords $node_id "$x $y"
			set e_dx [expr {$dx * $zoom}]
			set e_dy [expr {$dy * $zoom}]
			.panwin.f1.c move $obj $e_dx $e_dy
			set img [.panwin.f1.c find withtag "selectmark && $node_id"]
			.panwin.f1.c move $img $e_dx $e_dy
			set img [.panwin.f1.c find withtag "nodelabel && $node_id"]
			.panwin.f1.c move $img $e_dx $e_dy
			set x [expr {[lindex [.panwin.f1.c coords $img] 0] / $zoom}]
			set y [expr {[lindex [.panwin.f1.c coords $img] 1] / $zoom}]
			setNodeLabelCoords $node_id "$x $y"
			set img [.panwin.f1.c find withtag "node_running && $node_id"]
			.panwin.f1.c move $img $e_dx $e_dy
			set img [.panwin.f1.c find withtag "nodedisabled && $node_id"]
			.panwin.f1.c move $img $e_dx $e_dy
			.panwin.f1.c addtag need_redraw withtag "link && $node_id"
		}
		foreach link_id [.panwin.f1.c find withtag "link && need_redraw"] {
			redrawLink [lindex [.panwin.f1.c gettags $link_id] 1]
		}
		.panwin.f1.c dtag link need_redraw
		update
		set idlems [expr int($idlems + (33 - $dt * 1000) / 2)]
		if { $idlems < 1 } {
			set idlems 1
		}
		after $idlems
	}
	.menubar.tools entryconfigure "Auto rearrange all" -state normal
	.menubar.tools entryconfigure "Auto rearrange selected" -state normal
	.bottom.mbuf config -text ""
}

#****f* editor.tcl/switchCanvas
# NAME
#   switchCanvas -- switch canvas
# SYNOPSIS
#   switchCanvas $direction
# FUNCTION
#   This procedure switches the canvas in one of the defined
#   directions (previous, next, first and last).
# INPUTS
#   * direction -- the direction of switching canvas. Can be: prev --
#   previus, next -- next, first -- first, last -- last.
#****
proc switchCanvas { direction } {
	global sizex sizey

	set curcanvas [getFromRunning_gui "curcanvas"]
	set canvas_list [getFromRunning_gui "canvas_list"]

	if { $curcanvas ni $canvas_list } {
		set direction prev
	}

	set i [lsearch $canvas_list $curcanvas]
	switch -exact -- $direction {
		prev {
			incr i -1
			if { $i < 0 } {
				set curcanvas [lindex $canvas_list end]
			} else {
				set curcanvas [lindex $canvas_list $i]
			}
		}
		next {
			incr i
			if { $i >= [llength $canvas_list] } {
				set curcanvas [lindex $canvas_list 0]
			} else {
				set curcanvas [lindex $canvas_list $i]
			}
		}
		first {
			set curcanvas [lindex $canvas_list 0]
		}
		last {
			set curcanvas [lindex $canvas_list end]
		}
	}

	setToRunning_gui "curcanvas" $curcanvas

	.panwin.f1.hframe.t delete all
	set x 0
	foreach canvas_id $canvas_list {
		set text [.panwin.f1.hframe.t create text 0 0 \
			-text "[getCanvasName $canvas_id]" -tags "text $canvas_id"]
		set ox [lindex [.panwin.f1.hframe.t bbox $text] 2]
		set oy [lindex [.panwin.f1.hframe.t bbox $text] 3]
		set tab [.panwin.f1.hframe.t create polygon $x 0 [expr {$x + 7}] 18 \
			[expr {$x + 2 * $ox + 17}] 18 [expr {$x + 2 * $ox + 24}] 0 $x 0 \
			-fill #d9d9d9 -tags "tab $canvas_id"]
		set line [.panwin.f1.hframe.t create line 0 0 $x 0 [expr {$x + 7}] 18 \
			[expr {$x + 2 * $ox + 17}] 18 [expr {$x + 2 * $ox + 24}] 0 999 0 \
			-fill #d9d9d9 -width 2 -tags "line $canvas_id"]
		.panwin.f1.hframe.t coords $text [expr {$x + $ox + 12}] [expr {$oy + 2}]
		.panwin.f1.hframe.t raise $text
		incr x [expr {2 * $ox + 17}]
	}

	incr x 7
	.panwin.f1.hframe.t raise "$curcanvas"
	.panwin.f1.hframe.t itemconfigure "tab && $curcanvas" -fill #808080
	.panwin.f1.hframe.t configure -scrollregion "0 0 $x 18"
	update

	set width [lindex [.panwin.f1.hframe.t configure -width] 4]
	set lborder [lindex [.panwin.f1.hframe.t bbox "tab && $curcanvas"] 0]
	set rborder [lindex [.panwin.f1.hframe.t bbox "tab && $curcanvas"] 2]
	set lmargin [expr {[lindex [.panwin.f1.hframe.t xview] 0] * $x - 1}]
	set rmargin [expr {[lindex [.panwin.f1.hframe.t xview] 1] * $x + 1}]
	if { $lborder < $lmargin } {
		.panwin.f1.hframe.t xview moveto [expr {1.0 * ($lborder - 10) / $x}]
	}
	if { $rborder > $rmargin } {
		.panwin.f1.hframe.t xview moveto [expr {1.0 * ($rborder - $width + 10) / $x}]
	}

	set sizex [lindex [getCanvasSize $curcanvas] 0]
	set sizey [lindex [getCanvasSize $curcanvas] 1]

	redrawAll
}

#****f* editor.tcl/animate
# NAME
#   animate -- animate
# SYNOPSIS
#   animate
# FUNCTION
#   This function animates the selectbox. The animation looks
#   different for edit and exec mode.
#****
proc animate {} {
	global animatephase

	catch { .panwin.f1.c itemconfigure "selectmark || selectbox" -dashoffset $animatephase } err
	if { $err != "" } {
		puts stderr "IMUNES was closed unexpectedly before experiment termination was completed."
		puts stderr "Clean all running experiments with the 'cleanupAll' command."
		return;
	}

	incr animatephase 2
	if { $animatephase == 100 } {
		set animatephase 0
	}

	setWmTitle [getFromRunning "current_file"]

	if { [getFromRunning "oper_mode"] == "edit" } {
		after 250 animate
	} else {
		after 1500 animate
	}
}

#****f* editor.tcl/zoom
# NAME
#   zoom -- zoom
# SYNOPSIS
#   zoom $dir
# FUNCTION
#   Zooms the canvas up or down.
# INPUTS
#   * dir -- zoom direction (up or down)
#****
proc zoom { dir } {
	global zoom_stops

	set zoom [getFromRunning_gui "zoom"]
	set minzoom [lindex $zoom_stops 0]
	set maxzoom [lindex $zoom_stops [expr [llength $zoom_stops] - 1]]
	switch -exact -- $dir {
		"down" {
			if { $zoom > $maxzoom } {
				setToRunning_gui "zoom" $maxzoom
			} elseif { $zoom < $minzoom } {
				; # leave it unchanged
			} else {
				set newzoom $minzoom
				foreach z $zoom_stops {
					if { $zoom <= $z } {
						break
					} else {
						set newzoom $z
					}
				}
				setToRunning_gui "zoom" $newzoom
			}
			redrawAll
		}
		"up" {
			if { $zoom < $minzoom } {
				setToRunning_gui "zoom" $minzoom
			} elseif { $zoom > $maxzoom } {
				; # leave it unchanged
			} else {
				foreach z [lrange $zoom_stops 1 end] {
					set newzoom $z
					if { $zoom < $z } {
						break
					}
				}
				setToRunning_gui "zoom" $newzoom
			}
			redrawAll
		}
		default {
			if { $i < [expr [llength $zoom_stops] - 1] } {
				setToRunning_gui "zoom" [lindex $zoom_stops [expr $i + 1]]
				redrawAll
			}
		}
	}
}

#****f* drawing.tcl/drawGradientCircle
# NAME
#   drawGradientCircle -- create an image of a gradient circle
# SYNOPSIS
#   drawGradientCircle $image_obj $palette $image_width $image_height
# FUNCTION
#   Draws a circle and fills it up with the gradient of colors from the
#   $pallete. The result will be saved inside the $image_obj image.
# INPUTS
#   * image_obj -- an image created with [image create photo]
#   * palette -- a list of colors for the gradient (center to rim) - last one is ignored
#   * image_width -- image width
#   * image_height -- image height
#****
proc drawGradientCircle { image_obj palette image_width image_height } {
	set steps [expr [llength $palette] - 1]

	# calculate radius and center
	set cx [expr {($image_width - 1) / 2.0}]
	set cy [expr {($image_height - 1) / 2.0}]
	set r [expr {min($cx, $cy)}]

	# clear the image
	$image_obj put {} -to 0 0 $image_width $image_height

	for { set y 0 } { $y < $image_height } { incr y } {
		for { set x 0 } { $x < $image_width } { incr x } {
			set dx [expr {$x - $cx}]
			set dy [expr {$y - $cy}]
			set dist [expr {sqrt($dx*$dx + $dy*$dy)}]

			if { $dist <= $r } {
				# normalize distance [0..1] and map to palette index
				set norm [expr {$dist / $r}]
				set index [expr {int($norm * ($steps - 1))}]
				set color [lindex $palette $index]

				$image_obj put $color -to $x $y
			}
		}
	}
}
