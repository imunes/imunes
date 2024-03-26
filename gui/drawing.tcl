#****f* editor.tcl/redrawAll
# NAME
#   redrawAll -- redraw all
# SYNOPSIS
#   redrawAll
# FUNCTION
#   Redraws all the objects on the current canvas.
#****
proc redrawAll {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::annotation_list annotation_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global background sizex sizey grid
    global showBkgImage showAnnotations showGrid bkgImage
    .bottom.zoom config -text "zoom [expr {int($zoom * 100)}]%"
    set e_sizex [expr {int($sizex * $zoom)}]
    set e_sizey [expr {int($sizey * $zoom)}]
    set border 28
    .panwin.f1.c configure -scrollregion \
	"-$border -$border [expr {$e_sizex + $border}] \
	[expr {$e_sizey + $border}]"

    .panwin.f1.c delete all

    set canvasBkgImage [getCanvasBkg $curcanvas]
    if { $showBkgImage == 1 && "$canvasBkgImage" != ""} {
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

    if { $showAnnotations == 1 } {
	foreach obj $annotation_list {
	    if { [getNodeCanvas $obj] == $curcanvas } {
		drawAnnotation $obj
	    }
	} 
    }

    # Grid
    set e_grid [expr {int($grid * $zoom)}]
    set e_grid2 [expr {$e_grid * 2}]
    if { $showGrid } {
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

    foreach node $node_list {
	if { [getNodeCanvas $node] == $curcanvas } {
	    drawNode $node
	}
    }
    foreach link $link_list {
	set nodes [linkPeers $link]
	if { [getNodeCanvas [lindex $nodes 0]] != $curcanvas ||
	    [getNodeCanvas [lindex $nodes 1]] != $curcanvas } {
	    continue
	}
	drawLink $link
	redrawLink $link
	updateLinkLabel $link
    }
    updateIconSize
    .panwin.f1.c config -cursor left_ptr
    raiseAll .panwin.f1.c



			#Modification For Vlan

  			#*********************************************

 foreach node $node_list {
	if { [nodeType $node] == "lanswitch"} {
		
			

					global RouterCisco listVlan

				# c'est à dire qu'on a fait un open file qui exist
					if { $RouterCisco != ""} {

				# On remplit listVlan avec la configuration du fichier


							set Mynode ""
							set enable ""
							set Mytag ""
							set Mymode ""
							set Myinterface ""
							set Myrange ""

               			    upvar 0 ::cf::[set ::curcfg]::$node $node

                			set netconf [lindex [lsearch -inline [set $node] "network-config *"] 1]


                			foreach entry $netconf {
                  
					 				if {$entry == "!"} {
                     		       			lappend listVlan "!"
								   			set Mynode ""
                                 			set enable ""
								   			set Mytag ""
								   			set Mymode ""
								   			set Myinterface ""
							       			set Myrange ""
					 				} else {
                  	 					if { [lindex $entry 0] == "interface" && [lindex $entry 1] != ""} {
                  		 			   				set entry1 [lindex $entry 1]
                         			   				set Mynode "$node-$entry1"


			         					} else { 

                    				   				set entry [split $entry "="]
                                       

                            						if {[lindex $entry 0] == " vlan_enable"} {
                            						set enable [lindex $entry 1]

                            			} elseif {[lindex $entry 0] == " vlan_tag"} {
                            						set Mytag [lindex $entry 1]	

										} elseif {[lindex $entry 0] == " vlan_mode"} {
                            						set Mymode [lindex $entry 1]	

										} elseif {[lindex $entry 0] == " Interface_type"} {
                            						set Myinterface [lindex $entry 1]

										} elseif {[lindex $entry 0] == " vlan_range"} {
                            						set Myrange [lindex $entry 1]	

										}

		                     } 
					       }
                   if {$Mynode != "" && $enable != "" && $Mytag != "" && $Mymode != "" && $Myinterface != "" && $Myrange != ""} {



     				 foreach element $listVlan {
	
							set nom [lindex $element 0]
                			set nom1 [lindex $nom 0]

							if { $Mynode == $nom1 } {

								set id [lsearch $listVlan $element]
                                
                                set ID [expr $id-1]

								set malist [lreplace $listVlan $id $id]
								set malist [lreplace $malist $ID $ID]
								set listVlan $malist
							}


						}

                         lappend listVlan "$Mynode $enable $Mytag $Mymode $Myinterface $Myrange"

					}                      


                 }



}




  			#*********************************************
	}
    }

}

#****f* editor.tcl/drawNode
# NAME
#   drawNode -- draw a node
# SYNOPSIS
#   drawNode node_id
# FUNCTION
#   Draws the specified node. Draws node's image (router pc
#   host lanswitch frswitch rj45 hub pseudo) and label.
#   The visibility of the label depends on the showNodeLabels
#   variable for all types of nodes and on invisible variable 
#   for pseudo nodes.
# INPUTS
#   * node_id -- node id
#****
proc drawNode { node } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global showNodeLabels pseudo

    set type [nodeType $node]
    set coords [getNodeCoords $node]
    set x [expr {[lindex $coords 0] * $zoom}]
    set y [expr {[lindex $coords 1] * $zoom}]
    set customIcon [getCustomIcon $node]
    if {[string match "*img*" $customIcon] == 0} {
	global $type
	.panwin.f1.c create image $x $y -image [set $type] -tags "node $node"
    } else {
	global iconSize
	switch $iconSize {
	    normal {
		set icon_data [getImageData $customIcon]
		image create photo img_$customIcon -data $icon_data
		.panwin.f1.c create image $x $y -image img_$customIcon -tags "node $node"
	    }
	    small {
		set icon_data [getImageData $customIcon]
		image create photo img_$customIcon -data $icon_data
		set img_$customIcon [image% img_$customIcon 70 $customIcon]
		.panwin.f1.c create image $x $y -image [set img_$customIcon] -tags "node $node"
	    }
	}
    }
    set coords [getNodeLabelCoords $node]
    set x [expr {[lindex $coords 0] * $zoom}]
    set y [expr {[lindex $coords 1] * $zoom}]
    if { [nodeType $node] != "pseudo" } {
	set labelstr1 [getNodeName $node];
#	set labelstr2 [getNodePartition $node];
#	set l [format "%s\n%s" $labelstr1 $labelstr2];
	set l $labelstr1;
	foreach ifc [ifcList $node] {
	    if {[string trim $ifc 0123456789] == "wlan"} {
		set l [format "%s %s" $l [getIfcIPv4addr $node $ifc]]
	    }
	}
	set label [.panwin.f1.c create text $x $y -fill blue \
	    -text "$l" \
	    -tags "nodelabel $node"]
    } else {
	set pnode [peerByIfc [getNodeMirror $node] 0]
	set pcanvas [getNodeCanvas $pnode]
	set ifc [ifcByPeer $pnode [getNodeMirror $node]]
	if { $pcanvas != $curcanvas } {
	    set label [.panwin.f1.c create text $x $y -fill blue \
		-text "[getNodeName $pnode]:$ifc
@[getCanvasName $pcanvas]" \
		-tags "nodelabel $node" -justify center]
	} else {
	    set label [.panwin.f1.c create text $x $y -fill blue \
		-text "[getNodeName $pnode]:$ifc" \
		-tags "nodelabel $node" -justify center]
	}
    }
    if { $showNodeLabels == 0} {
	.panwin.f1.c itemconfigure $label -state hidden
    }
    # XXX Invisible pseudo-node labels
    global invisible
    if { $invisible == 1 && [nodeType $node] == "pseudo" } {
	.panwin.f1.c itemconfigure $label -state hidden
    }
    if {[nodeType $node] == "cloud"} {
	setCloudParts $node 1
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
proc drawLink { link } {
    set nodes [linkPeers $link]
    set lnode1 [lindex $nodes 0]
    set lnode2 [lindex $nodes 1]
    if {[nodeType $lnode1] == "wlan" || [nodeType $lnode2] == "wlan"} {
	return
    }
    set lwidth [getLinkWidth $link]
    if { [getLinkMirror $link] != "" } {
	set newlink [.panwin.f1.c create line 0 0 0 0 \
	    -fill [getLinkColor $link] -width $lwidth \
	    -tags "link $link $lnode1 $lnode2" -arrow both]
    } else {
	set newlink [.panwin.f1.c create line 0 0 0 0 \
	    -fill [getLinkColor $link] -width $lwidth \
	    -tags "link $link $lnode1 $lnode2"]
    }
    # XXX Invisible pseudo-liks
    global invisible
    if { $invisible == 1 && [getLinkMirror $link] != "" } {
	.panwin.f1.c itemconfigure $link -state hidden
    }
    .panwin.f1.c raise $newlink background
    set newlink [.panwin.f1.c create line 0 0 0 0 \
	-fill white -width [expr {$lwidth + 4}] \
	-tags "link $link $lnode1 $lnode2"]
    .panwin.f1.c raise $newlink background

    set ang [calcAngle $link]

    .panwin.f1.c create text 0 0 -tags "linklabel $link" -justify center -angle $ang
    .panwin.f1.c create text 0 0 -tags "interface $lnode1 $link" -justify center -angle $ang
    .panwin.f1.c create text 0 0 -tags "interface $lnode2 $link" -justify center -angle $ang

    .panwin.f1.c raise linklabel "link || background"
    .panwin.f1.c raise interface "link || linklabel || background"
}

#****f* editor.tcl/calcAnglePoints
# NAME
#   calcAnglePoints -- calculate angle between two points
# SYNOPSIS
#   calcAnglePoints $link
# FUNCTION
#   Calculates the angle of the link that connects 2 nodes.
#   Used to calculate the rotation angle of link and interface labels.
# INPUTS
#   * link -- link which rotation angle needs to be calculated.
#****
proc calcAnglePoints { x1 y1 x2 y2 } {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
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
    if {$ang < 0} {
	set ang [expr {$ang+360}]
    }
    set ang [expr {360-$ang}]
    if {$ang > 225 && $ang < 315 || $ang > 45 && $ang < 135 || $ang == 360} {
	set ang 0
    }
    return $ang
}

proc calcAngle { link } {
    set nodes [linkPeers $link]
    set lnode1 [lindex $nodes 0]
    set lnode2 [lindex $nodes 1]
    set coords [getNodeCoords $lnode1]
    set x1 [expr {[lindex $coords 0]}]
    set y1 [expr {[lindex $coords 1]}]
    set coords [getNodeCoords $lnode2]
    set x2 [expr {[lindex $coords 0]}]
    set y2 [expr {[lindex $coords 1]}]

    return [calcAnglePoints $x1 $y1 $x2 $y2]
}

#****f* editor.tcl/updateIfcLabel
# NAME
#   updateIfcLabel -- update interface label
# SYNOPSIS
#   updateIfcLabel $lnode1 $lnode2
# FUNCTION
#   Updates the interface label, including interface name,
#   interface state (* for interfaces that are down), IPv4
#   address and IPv6 address.
# INPUTS
#   * lnode1 -- node id of a node where the interface resides
#   * lnode2 -- node id of the node that is connected by this 
#   interface. 
#****
proc updateIfcLabel { lnode1 lnode2 } {
    global showIfNames showIfIPaddrs showIfIPv6addrs

    set link [lindex [.panwin.f1.c gettags "link && $lnode1 && $lnode2"] 1]
    set ifc [ifcByPeer $lnode1 $lnode2]
    set ifipv4addr [getIfcIPv4addr $lnode1 $ifc]
    set ifipv6addr [getIfcIPv6addr $lnode1 $ifc]
    if { $ifc == 0 } {
	set ifc ""
    }
    set labelstr ""
    if { $showIfNames } {
	lappend labelstr "$ifc"
    }
    if { $showIfIPaddrs && $ifipv4addr != "" } {
	lappend labelstr "$ifipv4addr"
    }
    if { $showIfIPv6addrs && $ifipv6addr != "" } {
	lappend labelstr "$ifipv6addr"
    }
    if { [getIfcOperState $lnode1 $ifc] == "down" } {
	set str "*"
    } else {
	set str ""
    }
    foreach elem $labelstr {
	if {$str == "" || $str == "*"} {
	    set str "$str[set elem]"
	} else {
	    set str "$str\r[set elem]"
	}
    }
    .panwin.f1.c itemconfigure "interface && $lnode1 && $link" \
	-text $str
}

#****f* editor.tcl/updateLinkLabel
# NAME
#   updateLinkLabel -- update link label
# SYNOPSIS
#   updateLinkLabel $link
# FUNCTION
#   Updates the link label, including link bandwidth, link delay,
#   BER and duplicate values.
# INPUTS
#   * link -- link id of the link whose labels are updated.
#****
proc updateLinkLabel { link } {
    global showLinkLabels linkJitterConfiguration 

    set labelstr ""
    set bwstr "[getLinkBandwidthString $link]"
    set delstr [getLinkDelayString $link]
    set ber [getLinkBER $link]
    set dup [getLinkDup $link]
    set jitter [concat [getLinkJitterUpstream $link] [getLinkJitterDownstream $link]]
    if { "$bwstr" != "" } {
	lappend labelstr $bwstr
    }
    if { "$delstr" != "" } {
	lappend labelstr $delstr
    }
    if { $jitter != "" && $linkJitterConfiguration == 1 } {
	lappend labelstr "jitter"
    }
    if { "$ber" != "" } {
	lappend labelstr "ber=$ber"
    }
    if { "$dup" != "" } {
	lappend labelstr "dup=$dup%"
    }
    set str ""
    foreach elem $labelstr {
	if {$str == ""} {
	    set str "$str[set elem]"
	} else {
	    set str "$str\r[set elem]"
	}
    }
    set ang [calcAngle $link]
    .panwin.f1.c itemconfigure "linklabel && $link" -text $str -angle $ang
    if { $showLinkLabels == 0} {
	.panwin.f1.c itemconfigure "linklabel && $link" -state hidden
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
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas

    foreach link $link_list {
	set nodes [linkPeers $link]
	if { [getNodeCanvas [lindex $nodes 0]] != $curcanvas ||
	    [getNodeCanvas [lindex $nodes 1]] != $curcanvas } {
	    continue
	}
	redrawLink $link
    }
}

#****f* editor.tcl/redrawLink
# NAME
#   redrawLink -- redraw a link
# SYNOPSIS
#   redrawLink $link
# FUNCTION
#   Redraws the specified link.
# INPUTS
#   * link -- link id
#****
proc redrawLink { link } {
    set limages [.panwin.f1.c find withtag "link && $link"]
    if {$limages == ""} {
	return
    }
    set limage1 [lindex $limages 0]
    set limage2 [lindex $limages 1]
    set tags [.panwin.f1.c gettags $limage1]
    set link [lindex $tags 1]
    set lnode1 [lindex $tags 2]
    set lnode2 [lindex $tags 3]

    if {[nodeType $lnode1] == "wlan" || [nodeType $lnode2] == "wlan"} {
	return
    }

    set coords1 [.panwin.f1.c coords "node && $lnode1"]
    set coords2 [.panwin.f1.c coords "node && $lnode2"]
    set x1 [lindex $coords1 0]
    set y1 [lindex $coords1 1]
    set x2 [lindex $coords2 0]
    set y2 [lindex $coords2 1]

    .panwin.f1.c coords $limage1 $x1 $y1 $x2 $y2
    .panwin.f1.c coords $limage2 $x1 $y1 $x2 $y2

    if { [nodeType $lnode1] == "pseudo" } {
	set lx [expr {0.25 * ($x2 - $x1) + $x1}]
	set ly [expr {0.25 * ($y2 - $y1) + $y1}]
    } elseif { [nodeType $lnode2] == "pseudo" } {
	set lx [expr {0.75 * ($x2 - $x1) + $x1}]
	set ly [expr {0.75 * ($y2 - $y1) + $y1}]
    } else {
	set lx [expr {0.5 * ($x1 + $x2)}]
	set ly [expr {0.5 * ($y1 + $y2)}]
    }
    .panwin.f1.c coords "linklabel && $link" $lx $ly

    if {[nodeType $lnode1] != "pseudo"} {
	updateIfcLabelParams $link $lnode1 $lnode2 $x1 $y1 $x2 $y2
	updateIfcLabel $lnode1 $lnode2
    }

    if {[nodeType $lnode2] != "pseudo"} {
	updateIfcLabelParams $link $lnode2 $lnode1 $x2 $y2 $x1 $y1
	updateIfcLabel $lnode2 $lnode1
    }
}

proc updateIfcLabelParams { link lnode1 lnode2 x1 y1 x2 y2 } {
    global showIfIPaddrs showIfIPv6addrs showIfNames

    set bbox [.panwin.f1.c bbox "node && $lnode1"]
    set iconwidth [expr [lindex $bbox 2] - [lindex $bbox 0]]
    set iconheight [expr [lindex $bbox 3] - [lindex $bbox 1]]

    set ang [calcAnglePoints $x1 $y1 $x2 $y2]
    set just center
    set anchor center

    set IP4 $showIfIPaddrs
    if { [getIfcIPv4addr $lnode1 [ifcByPeer $lnode1 $lnode2]] == "" } {
	set IP4 0
    }
    set IP6 $showIfIPv6addrs
    if { [getIfcIPv6addr $lnode1 [ifcByPeer $lnode1 $lnode2]] == "" } {
	set IP6 0
    }
    set add_height [expr 10*($showIfNames + $IP4 + $IP6)]

    # these params could be called dy and dx, respectively
    # additional height represents the ifnames, ipv4 and ipv6 addrs
    set height [expr $iconheight/2 + $add_height]
    # 5 pixels from icon
    set width [expr $iconwidth/2 + 10]

    if { $ang == 0 } {
	if { $y1 == $y2 } {
	    set just left
	    set anchor w
	    set lx [expr $x1 + $width]
	    if { $x1 > $x2 } {
		set just right
		set anchor e
		set lx [expr $x1 - $width]
	    }
	    set ly $y1
	} else {
	    set just center
	    if { $y1 > $y2} {
		set ly [expr $y1 - $height]
		set a [expr ($x1-$x2)/($y2-$y1)*2]
	    } else {
		# when the ifc label is located beneath the icon, shift it by 16
		# pixels because of the nodelabel
		set ly [expr $y1 + $height + 10]
		set a [expr ($x2-$x1)/($y2-$y1)*2]
	    }
	    set lx [expr $a*$height + $x1]
	}
    } else {
	if { $x1 > $x2 } {
	    set just right
	    set anchor e
	    set lx [expr $x1 - $width]
	    set a [expr ($y2-$y1)/($x1-$x2)]
	} else {
	    set just left
	    set anchor w
	    set lx [expr $x1 + $width]
	    set a [expr ($y2-$y1)/($x2-$x1)]
	}
	set ly [expr $a*$width + $y1]
    }
    .panwin.f1.c coords "interface && $lnode1 && $link" $lx $ly
    .panwin.f1.c itemconfigure "interface && $lnode1 && $link" -justify $just \
	-anchor $anchor -angle $ang
}

#****f* drawing.tcl/connectWithNode
# NAME
#   connectWithNode -- connect with a node
# SYNOPSIS
#   connectWithNode $nodes $node
# FUNCTION
#   This procedure calls newGUILink procedure to connect all given nodes with
#   the one node.
# INPUTS
#   * nodes -- list of all node ids to connect
#   * node -- node id of the node to connect to
#****
proc connectWithNode { nodes node } {
    foreach n $nodes {
	if { $n != $node } {
	    newGUILink $n $node
	}
    }
}

#****f* editor.tcl/newGUILink
# NAME
#   newGUILink -- new GUI link
# SYNOPSIS
#   newGUILink $lnode1 $lnode2
# FUNCTION
#   This procedure is called to create a new link between 
#   nodes lnode1 and lnode2. Nodes can be on the same canvas 
#   or on different canvases. The result of this function
#   is directly visible in GUI.
# INPUTS
#   * lnode1 -- node id of the first node
#   * lnode2 -- node id of the second node
#****
proc newGUILink { lnode1 lnode2 } {
    global changed

    set link [newLink $lnode1 $lnode2]
    if { $link == "" } {
	return
    }
    if { [getNodeCanvas $lnode1] != [getNodeCanvas $lnode2] } {
	set new_nodes [splitLink $link pseudo]
	set orig_nodes [linkPeers $link]
	set new_node1 [lindex $new_nodes 0]
	set new_node2 [lindex $new_nodes 1]
	set orig_node1 [lindex $orig_nodes 0]
	set orig_node2 [lindex $orig_nodes 1]
	set new_link1 [linkByPeers $orig_node1 $new_node1]
	set new_link2 [linkByPeers $orig_node2 $new_node2]
	setNodeMirror $new_node1 $new_node2
	setNodeMirror $new_node2 $new_node1
	setNodeName $new_node1 $orig_node2
	setNodeName $new_node2 $orig_node1
	setLinkMirror $new_link1 $new_link2
	setLinkMirror $new_link2 $new_link1
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
    upvar 0 ::cf::[set ::curcfg]::image_list image_list
    global chicondialog alignCanvasBkg iconsrcfile wi
    global ROOTDIR LIBDIR
    
    set chicondialog .chiconDialog
    catch {destroy $chicondialog}
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
    
    foreach file [glob -directory $ROOTDIR/$LIBDIR/icons/normal/ *.gif] {
	set filename [lindex [split $file /] end]
	$tree insert {} end -id $file -text $filename -values [list "library icon"] \
	  -tags "$file"
	$tree tag bind $file <1> \
	  "updateIconPreview $prevcan $wi.iconconf.right.l2 $file
	   set iconsrcfile \"$file\""
    }
    
    foreach img $image_list {
	if {$img != "" && [string match "*img*" $img] == 1 && \
	  [getImageType $img] == "customIcon"} {
	    $tree insert {} end -id $img -text $img -values [list "custom icon"] \
	      -tags "$img"
	    $tree tag bind $img <1> \
	      "updateIconPreview $prevcan $wi.iconconf.right.l2 $img
	       set iconsrcfile $img"
	}
    }
    
    foreach file [glob -directory $ROOTDIR/$LIBDIR/icons/normal/ *.gif] {
	$tree tag bind $file <Key-Up> \
	    "if {![string equal {} [$tree prev $file]]} {
		updateIconPreview $prevcan $wi.iconconf.right.l2 [$tree prev $file]
		set iconsrcfile [$tree prev $file]
	     }"
	$tree tag bind $file <Key-Down> \
	    "if {![string equal {} [$tree next $file]]} {
		updateIconPreview $prevcan $wi.iconconf.right.l2 [$tree next $file]
		set iconsrcfile [$tree next $file]
	     }"
    }
    
    set first [lindex [glob -directory $ROOTDIR/$LIBDIR/icons/normal/ *.gif] 0]
    $tree selection set $first
    $tree focus $first
        
    foreach img $image_list {
	if {$img != "" && [string match "*img*" $img] == 1 && \
	  [getImageType $img] == "customIcon"} {
	    $tree tag bind $img <Key-Up> \
		"if {![string equal {} [$tree prev $img]]} {
		    updateIconPreview $prevcan $wi.iconconf.right.l2 [$tree prev $img]
		    set iconsrcfile [$tree prev $img]
		}"
	    $tree tag bind $img <Key-Down> \
		"if {![string equal {} [$tree next $img]]} {
		    updateIconPreview $prevcan $wi.iconconf.right.l2 [$tree next $img]
		    set iconsrcfile [$tree next $img]
		}"
	}
    }

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
    ttk::button $wi.iconconf.left.down.right.b -text "Browse" -width 8 \
	-command {
	    set fType {
		{{All Images} {.gif}  {}}
		{{All Images} {.png}  {}}
		{{Gif Images} {.gif}  {}}
		{{PNG Images} {.png} {}}
	    }
#		{{All Images} {.jpeg} {}}
#		{{All Images} {.jpg}  {}}
#		{{All Images} {.bmp}  {}}
#		{{All Images} {.tiff} {}}
#		{{All Images} {.ico}  {}}
#		{{Jpeg Images} {.jpg} {}}
#		{{Jpeg Images} {.jpeg} {}}
#		{{Bitmap Images} {.bmp} {}}
#		{{Tiff Images} {.tiff} {}}
#		{{Icon Images} {.ico} {}}
	    global canvasBkgMode wi
	    set chicondialog .chiconDialog
	    set prevcan $wi.iconconf.right.pc
	    set imgsize $wi.iconconf.right.l2
	    set iconsrcfile [tk_getOpenFile -parent $chicondialog -filetypes $fType]
	    $wi.iconconf.left.down.left.e delete 0 end
	    $wi.iconconf.left.down.left.e insert 0 "$iconsrcfile"
	    if {$iconsrcfile != ""} {
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
    
    if {$iconsrcfile != ""} {
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
    
    bind $chicondialog <Key-Return> {popupIconApply $chicondialog $iconsrcfile}
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
    
    if { ![string match -nocase "*.*" $image] } {
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
	    foreach node $nodelist {
		set icon [getCustomIcon $node]
		if { $icon != "" } {
		    removeImageReference $icon $node
		}
		setCustomIcon $node $imgname
		setImageReference $imgname $node
	    }
	} else {
	    foreach node $nodelist {
		set icon [getCustomIcon $node]
		if { $icon != "" } {
		    removeImageReference $icon $node
		}
		setCustomIcon $node $image
		setImageReference $image $node
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
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    foreach node $node_list {
	set icon [getCustomIcon $node]
	if { $icon != "" } {
	    setImageReference $icon $node
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
    global $b iconSize
    set $b [image create photo -file [$b.icon $iconSize]]
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
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global zoom_stops changed
    .button3menu delete 0 end

    set sel_zoom $zoom
    
    foreach z $zoom_stops {
	.button3menu add radiobutton -label [expr {int($z*100)}] \
	  -variable sel_zoom -value $z \
	  -command {
	      upvar 0 ::cf::[set ::curcfg]::zoom zoom
	      set zoom $sel_zoom
	      redrawAll
	      set changed 1
	      updateUndoLog
	  }
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
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
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
	    set node [lindex [.panwin.f1.c gettags [lindex $node_objects 0]] 1]
	    set node_objects [lreplace $node_objects 0 0]
	    setNodeCoords $node "$x $y"
	    set dy 32
	    if { [lsearch {router hub lanswitch rj45} \
		[nodeType $node]] >= 0 } {
		set dy 24
	    }
	    setNodeLabelCoords $node "$x [expr {$y + $dy}]"
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
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global autorearrange_enabled sizex sizey

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
	    set node [lindex [.panwin.f1.c gettags $obj] 1]
	    set coords [.panwin.f1.c coords $obj]
	    set x [expr {[lindex $coords 0] / $zoom}]
	    set y [expr {[lindex $coords 1] / $zoom}]
	    set x_t($node) $x
	    set y_t($node) $y

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
	    set fx_t($node) $fx
	    set fy_t($node) $fy
	}

	foreach obj $objects {
	    set node [lindex [.panwin.f1.c gettags $obj] 1]
	    set i [lsearch -exact $peer_objects $obj]
	    set peer_objects [lreplace $peer_objects $i $i]
	    set x $x_t($node)
	    set y $y_t($node)
	    foreach other_obj $peer_objects {
		set other [lindex [.panwin.f1.c gettags $other_obj] 1]
		set o_x $x_t($other)
		set o_y $y_t($other)
		set dx [expr {$x - $o_x}]
		set dy [expr {$y - $o_y}]
		set d [expr {hypot($dx, $dy)}]
		set d2 [expr {$d * $d}]
		set p_fx [expr {1000.0 * $dx / ($d2 * $d + 100)}]
		set p_fy [expr {1000.0 * $dy / ($d2 * $d + 100)}]
		if {[linkByPeers $node $other] != ""} {
		    set p_fx [expr {$p_fx - $dx * $d2 * .0000000005}]
		    set p_fy [expr {$p_fy - $dy * $d2 * .0000000005}]
		}
		set fx_t($node) [expr {$fx_t($node) + $p_fx}]
		set fy_t($node) [expr {$fy_t($node) + $p_fy}]
		set fx_t($other) [expr {$fx_t($other) - $p_fx}]
		set fy_t($other) [expr {$fy_t($other) - $p_fy}]
	    }

	    foreach link $link_list {
		set nodes [linkPeers $link]
		if { [getNodeCanvas [lindex $nodes 0]] != $curcanvas ||
		  [getNodeCanvas [lindex $nodes 1]] != $curcanvas ||
		  [getLinkMirror $link] != "" } {
		    continue
		}
		set peers [linkPeers $link]
		if {[nodeType [lindex $peers 0]] == "wlan" ||
		  [nodeType [lindex $peers 1]] == "wlan"} {
		    continue
		}
		set coords0 [getNodeCoords [lindex $peers 0]]
		set coords1 [getNodeCoords [lindex $peers 1]]
		set o_x \
		    [expr {([lindex $coords0 0] + [lindex $coords1 0]) * .5}]
		set o_y \
		    [expr {([lindex $coords0 1] + [lindex $coords1 1]) * .5}]
		set dx [expr {$x - $o_x}]
		set dy [expr {$y - $o_y}]
		set d [expr {hypot($dx, $dy)}]
		set d2 [expr {$d * $d}]
		set fx_t($node) \
		    [expr {$fx_t($node) + 500.0 * $dx / ($d2 * $d + 100)}]
		set fy_t($node) \
		    [expr {$fy_t($node) + 500.0 * $dy / ($d2 * $d + 100)}]
	    }
	}

	foreach obj $objects {
	    set node [lindex [.panwin.f1.c gettags $obj] 1]
	    if { [catch "set v_t($node)" v] } {
		set vx 0.0
		set vy 0.0
	    } else {
		set vx [lindex $v_t($node) 0]
		set vy [lindex $v_t($node) 1]
	    }
	    set vx [expr {$vx + 1000.0 * $fx_t($node) * $dt}]
	    set vy [expr {$vy + 1000.0 * $fy_t($node) * $dt}]
	    set dampk [expr {0.5 + ($vx * $vx + $vy * $vy) * 0.00001}]
	    set vx [expr {$vx * exp( - $dampk * $dt)}]
	    set vy [expr {$vy * exp( - $dampk * $dt)}]
	    set dx [expr {$vx * $dt}]
	    set dy [expr {$vy * $dt}]
	    set x [expr {$x_t($node) + $dx}]
	    set y [expr {$y_t($node) + $dy}]
	    set v_t($node) "$vx $vy"

	    setNodeCoords $node "$x $y"
	    set e_dx [expr {$dx * $zoom}]
	    set e_dy [expr {$dy * $zoom}]
	    .panwin.f1.c move $obj $e_dx $e_dy
	    set img [.panwin.f1.c find withtag "selectmark && $node"]
	    .panwin.f1.c move $img $e_dx $e_dy
	    set img [.panwin.f1.c find withtag "nodelabel && $node"]
	    .panwin.f1.c move $img $e_dx $e_dy
	    set x [expr {[lindex [.panwin.f1.c coords $img] 0] / $zoom}]
	    set y [expr {[lindex [.panwin.f1.c coords $img] 1] / $zoom}]
	    setNodeLabelCoords $node "$x $y"
	    .panwin.f1.c addtag need_redraw withtag "link && $node"
	}
	foreach link [.panwin.f1.c find withtag "link && need_redraw"] {
	    redrawLink [lindex [.panwin.f1.c gettags $link] 1]
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
    upvar 0 ::cf::[set ::curcfg]::canvas_list canvas_list
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    global sizex sizey
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

    .panwin.f1.hframe.t delete all
    set x 0
    foreach canvas $canvas_list {
    set text [.panwin.f1.hframe.t create text 0 0 \
	-text "[getCanvasName $canvas]" -tags "text $canvas"]
    set ox [lindex [.panwin.f1.hframe.t bbox $text] 2]
    set oy [lindex [.panwin.f1.hframe.t bbox $text] 3]
    set tab [.panwin.f1.hframe.t create polygon $x 0 [expr {$x + 7}] 18 \
	[expr {$x + 2 * $ox + 17}] 18 [expr {$x + 2 * $ox + 24}] 0 $x 0 \
	-fill #d9d9d9 -tags "tab $canvas"]
    set line [.panwin.f1.hframe.t create line 0 0 $x 0 [expr {$x + 7}] 18 \
	[expr {$x + 2 * $ox + 17}] 18 [expr {$x + 2 * $ox + 24}] 0 999 0 \
	-fill #d9d9d9 -width 2 -tags "line $canvas"]
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
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global animatephase

    catch {.panwin.f1.c itemconfigure "selectmark || selectbox" -dashoffset $animatephase} err
    if { $err != "" } {
	puts "IMUNES was closed unexpectedly before experiment termination was completed."
	puts "Clean all running experiments with the 'cleanupAll' command."
	return;
    }

    incr animatephase 2
    if { $animatephase == 100 } {
	set animatephase 0
    }

    if { $oper_mode == "edit" } {
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
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global zoom_stops
    # set i [lsearch $stops $zoom]
    set minzoom [lindex $zoom_stops 0]
    set maxzoom [lindex $zoom_stops [expr [llength $zoom_stops] - 1]]
    switch -exact -- $dir {
	"down" {
	    if {$zoom > $maxzoom} {
		set zoom $maxzoom
	    } elseif {$zoom < $minzoom} {
		; # leave it unchanged
	    } else {
		set newzoom $minzoom
		foreach z $zoom_stops {
		    if {$zoom <= $z} {
			break
		    } else {
			set newzoom $z
		    }
		}
		set zoom $newzoom 
	    }
	    redrawAll
	}
	"up" {
	    if {$zoom < $minzoom} {
		set zoom $minzoom
	    } elseif {$zoom > $maxzoom} {
		; # leave it unchanged
	    } else {
		foreach z [lrange $zoom_stops 1 end] {
		    set newzoom $z
		    if {$zoom < $z} {
			break
		    }
		}
		set zoom $newzoom 
	    }
	    redrawAll
	}
	default {
	    if { $i < [expr [llength $zoom_stops] - 1] } {
		set zoom [lindex $zoom_stops [expr $i + 1]]
		redrawAll
	    }
	}
    }
}
