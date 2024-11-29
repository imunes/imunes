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

#****h* imunes/editor.tcl
# NAME
#  editor.tcl -- file used for defining functions that can be used in
#  edit mode as well as all the functions which change the appearance
#  of the imunes GUI.
# FUNCTION
#  This module is used for defining all possible actions in imunes
#  edit mode. It is also used for all the GUI related actions.
#****

#****f* editor.tcl/updateUndoLog
# NAME
#   updateUndoLog -- update the undo log
# SYNOPSIS
#   updateUndoLog
# FUNCTION
#   Updates the undo log. Writes the current configuration to the
#   undolog array and updates the undolevel variable.
#****
proc updateUndoLog {} {
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
    upvar 0 ::cf::[set ::curcfg]::undolog undolog
    upvar 0 ::cf::[set ::curcfg]::etchosts etchosts
    global changed showTree

    if { $changed } {
	global t_undolog

	set t_undolog ""
	dumpCfg string t_undolog

	incr undolevel
	if { $undolevel == 1 } {
	    .menubar.edit entryconfigure "Undo" -state normal
	}

	set undolog($undolevel) $t_undolog
	set redolevel $undolevel
	set changed 0

	# When some changes are made in the topology, new /etc/hosts files
	# should be generated.
	set etchosts ""
	if { $showTree } {
	    refreshTopologyTree
	}
    }
}

#****f* editor.tcl/undo
# NAME
#   undo -- undo function
# SYNOPSIS
#   undo
# FUNCTION
#   Undo the change. Reads the undolog and updates the current
#   configuration. Reduces the value of undolevel.
#****
proc undo {} {
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::undolog undolog
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global showTree

    if { $oper_mode == "edit" && $undolevel > 0 } {
	.menubar.edit entryconfigure "Redo" -state normal
	incr undolevel -1
	if { $undolevel == 0 } {
	    .menubar.edit entryconfigure "Undo" -state disabled
	}

	.panwin.f1.c config -cursor watch

	loadCfgLegacy $undolog($undolevel)
	switchCanvas none

	if { $showTree } {
	    refreshTopologyTree
	}
    }
}

#****f* editor.tcl/redo
# NAME
#   redo -- redo function
# SYNOPSIS
#   redo
# FUNCTION
#   Redo the change if possible (redolevel is greater than
#   undolevel). Reads the configuration from undolog and
#   updates the current configuration. Increases the value
#   of undolevel.
#****
proc redo {} {
    upvar 0 ::cf::[set ::curcfg]::undolevel undolevel
    upvar 0 ::cf::[set ::curcfg]::redolevel redolevel
    upvar 0 ::cf::[set ::curcfg]::undolog undolog
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global showTree

    if { $oper_mode == "edit" && $redolevel > $undolevel } {
	incr undolevel
	if { $undolevel == 1 } {
	    .menubar.edit entryconfigure "Undo" -state normal
	}

	if { $redolevel <= $undolevel } {
	    .menubar.edit entryconfigure "Redo" -state disabled
	}

	.panwin.f1.c config -cursor watch

	loadCfgLegacy $undolog($undolevel)
	switchCanvas none

	if { $showTree } {
	    refreshTopologyTree
	}
    }
}

#****f* editor.tcl/chooseIfName
# NAME
#   chooseIfName -- choose interface name
# SYNOPSIS
#   set ifc_name [chooseIfName $local_node $remote_node]
# FUNCTION
#   Choose a node-specific interface base name.
# INPUTS
#   * lnode_id -- id of a "local" node
#   * rnode_id -- id of a "remote" node
# RESULT
#   * ifc_name -- the name of the interface
#****
proc chooseIfName { lnode_id rnode_id } {
    return [[getNodeType $lnode_id].ifacePrefix $lnode_id $rnode_id]
}

#****f* editor.tcl/l3IfcName
# NAME
#   l3IfcName -- default interface name picker for l3 nodes
# SYNOPSIS
#   set ifc_name [l3IfcName $local_node $remote_node]
# FUNCTION
#   Pick a default interface base name for a L3 node.
# INPUTS
#   * lnode_id -- id of a "local" node
#   * rnode_id -- id of a "remote" node
# RESULT
#   * ifc_name -- the name of the interface
#****
proc l3IfcName { lnode_id rnode_id } {
    if { [getNodeType $lnode_id] in "ext extnat" } {
	return "ext"
    }

    if { [getNodeType $rnode_id] == "wlan" } {
	return "wlan"
    } else {
	return "eth"
    }
}

#****f* editor.tcl/listLANNodes
# NAME
#   listLANNodes -- list LAN nodes
# SYNOPSIS
#   set l2peers [listLANNodes $l2node_id $l2peers]
# FUNCTION
#   Recursive function for finding all link layer nodes that are
#   connected to node l2node. Returns the list of all link layer
#   nodes that are on the same LAN as l2node.
# INPUTS
#   * l2node_id -- node id of a link layer node
#   * l2peers -- old link layer nodes on the same LAN
# RESULT
#   * l2peers -- new link layer nodes on the same LAN
#****
proc listLANNodes { l2node_id l2peers } {
    lappend l2peers $l2node_id
    foreach iface_id [ifcList $l2node_id] {
	lassign [logicalPeerByIfc $l2node_id $iface_id] peer_id -
	if { [[getNodeType $peer_id].netlayer] == "LINK" && [getNodeType $peer_id] != "rj45" } {
	    if { $peer_id ni $l2peers } {
		set l2peers [listLANNodes $peer_id $l2peers]
	    }
	}
    }

    return $l2peers
}

#****f* editor.tcl/checkIntRange
# NAME
#   checkIntRange -- check integer range
# SYNOPSIS
#   set check [checkIntRange $str $low $high]
# FUNCTION
#   This procedure checks the input string to see if it is
#   an integer between the low and high value.
# INPUTS
#   str -- string to check
#   low -- the bottom value
#   high -- the top value
# RESULT
#   * check -- set to 1 if the str is string between low and high
#   value, 0 otherwise.
#****
proc checkIntRange { str low high } {
    if { $str == "" } {
	return 1
    }

    set str [string trimleft $str 0]
    if { $str == "" } {
	set str 0
    }

    if { ! [string is integer $str] } {
	return 0
    }

    if { $str < $low || $str > $high } {
	return 0
    }

    return 1
}

#****f* editor.tcl/focusAndFlash
# NAME
#   focusAndFlash -- focus and flash
# SYNOPSIS
#   focusAndFlash $W $count
# FUNCTION
#   This procedure sets the focus on the bad entry field
#   and on this field it provides an effect of flashing
#   for approximately 1 second.
# INPUTS
#   * W -- textbox field that caused the bad entry
#   * count -- the parameter that causes flashes.
#   It can be left blank.
#****
proc focusAndFlash { W { count 9 } } {
    global badentry

    set fg black
    set bg white

    if { $badentry == -1 } {
	return
    } else {
	set badentry 1
    }

    try {
	focus -force $W
    } on ok {} {
	if { $count < 1 } {
	    $W configure -foreground $fg -background $bg
	    set badentry 0
	} else {
	    if { $count % 2 } {
		$W configure -foreground $bg -background $fg
	    } else {
		$W configure -foreground $fg -background $bg
	    }

	    after 200 [list focusAndFlash $W [expr {$count - 1}]]
	}
    } on error {} {}
}

#****f* editor.tcl/setZoom
# NAME
#   setZoom -- set zoom
# SYNOPSIS
#   setZoom $x $y
# FUNCTION
#   Creates a dialog to set zoom.
# INPUTS
#   * x -- zoom x coordinate
#   * y -- zoom y coordinate
#****
proc setZoom { x y } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    upvar 0 ::cf::[set ::curcfg]::zoom zoom

    set w .entry1
    catch { destroy $w }
    toplevel $w -takefocus 1

    if { $x == 0 && $y == 0 } {
	set screen [wm maxsize .]
	set x [expr {[lindex $screen 0] / 2}]
	set y [expr {[lindex $screen 1] / 2}]
    } else {
	set x [expr {$x + 10}]
	set y [expr {$y - 90}]
    }
    wm geometry $w +$x+$y
    wm title $w "Set zoom %"
    wm iconname $w "Set zoom %"

    ttk::frame $w.setzoom
    pack $w.setzoom -fill both -expand 1

    update
    grab $w
    ttk::label $w.setzoom.msg -wraplength 5i -justify left -text "Zoom percentage:"
    pack $w.setzoom.msg -side top

    ttk::frame $w.setzoom.buttons
    pack $w.setzoom.buttons -side bottom -fill x -pady 2m
    ttk::button $w.setzoom.buttons.print -text "Apply" -command "setZoomApply $w"
    ttk::button $w.setzoom.buttons.cancel -text "Cancel" -command "destroy $w"
    pack $w.setzoom.buttons.print $w.setzoom.buttons.cancel -side left -expand 1

    bind $w <Key-Escape> "destroy $w"
    bind $w <Key-Return> "setZoomApply $w"

    ttk::entry $w.setzoom.e1
    $w.setzoom.e1 insert 0 [expr {int($zoom * 100)}]
    pack $w.setzoom.e1 -side top -pady 5 -padx 10 -fill x
}

#****f* editor.tcl/setZoomApply
# NAME
#   setZoomApply -- set zoom apply
# SYNOPSIS
#   setZoomApply $w
# FUNCTION
#   This procedure is called by clicking on apply button in set
#   zoom popup dialog box. It zooms to a specific point.
# INPUTS
#   * w -- tk widget (set zoom popup dialog box)
#****
proc setZoomApply { w } {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom

    set newzoom [expr [$w.setzoom.e1 get] / 100.0]
    if { $newzoom != $zoom } {
	set zoom $newzoom
	redrawAll
    }

    destroy $w
}

#****f* editor.tcl/selectZoom
# NAME
#   selectZoom -- select zoom
# SYNOPSIS
#   selectZoom $x $y
# FUNCTION
#   Creates a dialog to select zoom.
# INPUTS
#   * x -- zoom x coordinate
#   * y -- zoom y coordinate
#****
proc selectZoom { x y } {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom

    global zoom_stops

    set values {}
    foreach z $zoom_stops {
	lappend values [expr {int($z*100)}]
    }

    set w .entry1
    catch { destroy $w }
    toplevel $w -takefocus 1

    if { $x == 0 && $y == 0 } {
	set screen [wm maxsize .]
	set x [expr {[lindex $screen 0] / 2}]
	set y [expr {[lindex $screen 1] / 2}]
    } else {
	set x [expr {$x + 10}]
	set y [expr {$y - 90}]
    }
    wm geometry $w +$x+$y
    wm title $w "Select zoom %"
    wm iconname $w "Select zoom %"

    #dodan glavni frame "selectzoom"
    ttk::frame $w.selectzoom
    pack $w.selectzoom -fill both -expand 1

    ttk::frame $w.selectzoom.buttons
    pack $w.selectzoom.buttons -side bottom -fill x -pady 2m
    ttk::button $w.selectzoom.buttons.print -text "Apply" -command "selectZoomApply $w"
    ttk::button $w.selectzoom.buttons.cancel -text "Cancel" -command "destroy $w"
    pack $w.selectzoom.buttons.print $w.selectzoom.buttons.cancel -side left -expand 1

    bind $w <Key-Escape> "destroy $w"
    bind $w <Key-Return> "selectZoomApply $w"

    ttk::combobox $w.selectzoom.e1 -values $values
    $w.selectzoom.e1 insert 0 [expr {int($zoom * 100)}]
    pack $w.selectzoom.e1 -side top -pady 5 -padx 10 -fill x

    update
    focus $w.selectzoom.e1
    grab $w
}

#****f* editor.tcl/selectZoomApply
# NAME
#   selectZoomApply -- applies zoom values when they are selected
# SYNOPSIS
#   selectZoomApply $w
# FUNCTION
#   This procedure is called by clicking on apply button in select
#   zoom popup dialog box.
# INPUTS
#   * w -- tk widget (select zoom popup dialog box)
#****
proc selectZoomApply { w } {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global hasIM changed

    set tempzoom [$w.selectzoom.e1 get]
    if { ! $hasIM } {
	global zoom_stops

	set values {}
	foreach z $zoom_stops {
	    lappend values [expr {int($z*100)}]
	}

	if { $tempzoom > 400 || $tempzoom < 10 } {
	    set tempzoom 100
	}

	if { [lsearch $values $tempzoom] == -1 } {
	    set tempzoom [expr int($tempzoom/10)*10]
	}
    }

    set newzoom [ expr $tempzoom / 100.0]
    if { $newzoom != $zoom } {
	set zoom $newzoom

	redrawAll
	set changed 1
	updateUndoLog
    }

    destroy $w
}

#****f* editor.tcl/routerDefaultsApply
# NAME
#   routerDefaultsApply-- router defaults apply
# SYNOPSIS
#   routerDefaultsApply $wi
# FUNCTION
#   This procedure is called when the button apply is pressed in
#   popup router defaults dialog box.
# INPUTS
#   * wi -- widget
#****
proc routerDefaultsApply { wi } {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    global changed router_model routerDefaultsModel router_ConfigModel
    global routerRipEnable routerRipngEnable routerOspfEnable routerOspf6Enable routerBgpEnable
    global rdconfig

    lset rdconfig 0 $routerRipEnable
    lset rdconfig 1 $routerRipngEnable
    lset rdconfig 2 $routerOspfEnable
    lset rdconfig 3 $routerOspf6Enable
    lset rdconfig 4 $routerBgpEnable
    set routerDefaultsModel $router_model

    set selected_node_list [selectedNodes]
    if { $selected_node_list != {} } {
	foreach node_id $selected_node_list {
	    if { $oper_mode == "edit" && [getNodeType $node_id] == "router" } {
		setNodeModel $node_id $router_model

		set router_ConfigModel $router_model
		if { $router_ConfigModel != "static" } {
		    set ripEnable [lindex $rdconfig 0]
		    set ripngEnable [lindex $rdconfig 1]
		    set ospfEnable [lindex $rdconfig 2]
		    set ospf6Enable [lindex $rdconfig 3]
		    set bgpEnable [lindex $rdconfig 4]
		    setNodeProtocolRip $node_id $ripEnable
		    setNodeProtocolRipng $node_id $ripngEnable
		    setNodeProtocolOspfv2 $node_id $ospfEnable
		    setNodeProtocolOspfv3 $node_id $ospf6Enable
		    setNodeProtocolBgp $node_id $bgpEnable
		} else {
		    $wi.nbook.nf1.protocols.rip configure -state disabled
		    $wi.nbook.nf1.protocols.ripng configure -state disabled
		    $wi.nbook.nf1.protocols.ospf configure -state disabled
		    $wi.nbook.nf1.protocols.ospf6 configure -state disabled
		    $wi.nbook.nf1.protocols.bgp configure -state disabled
		}
		set changed 1
	    }
	}
    } else {
	foreach node_id $node_list {
	    if { $oper_mode == "edit" && [getNodeType $node_id] == "router" } {
		setNodeModel $node_id $router_model

		set router_ConfigModel $router_model
		if { $router_ConfigModel != "static" } {
		    set ripEnable [lindex $rdconfig 0]
		    set ripngEnable [lindex $rdconfig 1]
		    set ospfEnable [lindex $rdconfig 2]
		    set ospf6Enable [lindex $rdconfig 3]
		    setNodeProtocolRip $node_id  $ripEnable
		    setNodeProtocolRipng $node_id $ripngEnable
		    setNodeProtocolOspfv2 $node_id $ospfEnable
		    setNodeProtocolOspfv3 $node_id $ospf6Enable
		    setNodeProtocolBgp $node_id $bgpEnable
		} else {
		    $wi.nbook.nf1.protocols.rip configure -state disabled
		    $wi.nbook.nf1.protocols.ripng configure -state disabled
		    $wi.nbook.nf1.protocols.ospf configure -state disabled
		    $wi.nbook.nf1.protocols.ospf6 configure -state disabled
		    $wi.nbook.nf1.protocols.bgp configure -state disabled
		}
		set changed 1
	    }
	}
    }

    if { $changed == 1 } {
	redrawAll
	updateUndoLog
    }

    destroy $wi
}

#****f* editor.tcl/setCustomIcon
# NAME
#   setCustomIcon -- set custom icon
# SYNOPSIS
#   setCustomIcon $node_id $icon_name
# FUNCTION
#   Sets the custom icon to a node.
# INPUTS
#   * node_id -- node to change
#   * icon_name -- icon name
#****
proc setCustomIcon { node_id icon_name } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global $icon_name

    set i [lsearch [set $node_id] "customIcon *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i "customIcon $icon_name"]
    } else {
	set $node_id [linsert [set $node_id] end "customIcon $icon_name"]
    }
}

#****f* editor.tcl/getCustomIcon
# NAME
#   getCustomIcon -- get custom icon
# SYNOPSIS
#   getCustomIcon $node_id
# FUNCTION
#   Returns the custom icon from a node.
# INPUTS
#   * node_id -- node to get the icon from
#****
proc getCustomIcon { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    return [lindex [lsearch -inline [set $node_id] "customIcon *"] 1]
}

#****f* editor.tcl/removeCustomIcon
# NAME
#   removeCustomIcon -- remove custom icon
# SYNOPSIS
#   removeCustomIcon $node_id
# FUNCTION
#   Removes the custom icon from a node.
# INPUTS
#   * node_id -- node to remove the icon from
#****
proc removeCustomIcon { node_id } {
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id

    set i [lsearch [set $node_id] "customIcon *"]
    if { $i >= 0 } {
	set $node_id [lreplace [set $node_id] $i $i]
    }
}

#****f* editor.tcl/getMostDistantNodeCoordinates
# NAME
#   getMostDistantNodeCoordinates -- get most distant node coordinates
# SYNOPSIS
#   getMostDistantNodeCoordinates
# FUNCTION
#   Returns the most distant node coordinates.
#****
proc getMostDistantNodeCoordinates {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    set x 0
    set y 0
    foreach node_id $node_list {
	set coords [getNodeCoords $node_id]
	if { [lindex $coords 0] > $x } {
	    set x [lindex $coords 0]
	}
	if { [lindex $coords 1] > $y } {
	    set y [lindex $coords 1]
	}
    }

    set x [expr $x + 25]
    set y [expr $y + 30]

    return [list $x $y]
}


#****f* editor.tcl/topologyElementsTree
# NAME
#   topologyElementsTree -- topology elements tree
# SYNOPSIS
#   topologyElementsTree
# FUNCTION
#   Creates the tree with all network elements form the topology.
#****
proc topologyElementsTree {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    global showTree

    set f .panwin.f2
    if { ! $showTree } {
        .panwin forget $f
    }

    if { $showTree } {
	.panwin add $f
	ttk::frame $f.treegrid
	ttk::treeview $f.tree -selectmode browse \
	    -xscrollcommand "$f.hscroll set"\
	    -yscrollcommand "$f.vscroll set"
	ttk::scrollbar $f.hscroll -orient horizontal -command "$f.tree xview"
	ttk::scrollbar $f.vscroll -orient vertical -command "$f.tree yview"

	focus $f.tree

	pack $f.treegrid -side right -fill y
	grid $f.tree $f.vscroll -in $f.treegrid -sticky nsew
        grid $f.hscroll -in $f.treegrid -sticky nsew
	grid columnconfig $f.treegrid 0 -weight 1
	grid rowconfigure $f.treegrid 0 -weight 1

	$f.tree configure -columns { state nat MAC IPv4 IPv6 canvas }
	$f.tree column #0 -width 200 -stretch 0
	$f.tree column state -width 60 -anchor center -stretch 0
	$f.tree column nat -width 40 -anchor center -stretch 0
        $f.tree column MAC -width 120 -anchor center -stretch 0
	$f.tree column IPv4 -width 100 -anchor center -stretch 0
	$f.tree column IPv6 -width 100 -anchor center -stretch 0
	$f.tree column canvas -width 60 -anchor center -stretch 0
	$f.tree heading #0 -text "(Expand All)"
	$f.tree heading state -text "State"
	$f.tree heading nat -text "NAT"
        $f.tree heading MAC -text "MAC address"
	$f.tree heading IPv4 -text "IPv4 address"
	$f.tree heading IPv6 -text "IPv6 address"
	$f.tree heading canvas -text "Canvas"

	# filling the tree with node info
        global nodetags

	set nodetags ""
	$f.tree insert {} end -id nodes -text "Nodes" -open true -tags nodes
	$f.tree focus nodes
	$f.tree selection set nodes
	foreach node_id [lsort -dictionary $node_list] {
	    set type [getNodeType $node_id]
	    if { $type != "pseudo" } {
		$f.tree insert nodes end -id $node_id -text "[getNodeName $node_id]" -open false -tags $node_id
		lappend nodetags $node_id
		$f.tree set $node_id canvas [getCanvasName [getNodeCanvas $node_id]]
		foreach iface_id [lsort -dictionary [ifcList $node_id]] {
		    $f.tree insert $node_id end -id $node_id$iface_id -text "$iface_id" -tags $node_id$iface_id
		    $f.tree set $node_id$iface_id state [getIfcOperState $node_id $iface_id]
		    $f.tree set $node_id$iface_id nat [getIfcNatState $node_id $iface_id]
		    $f.tree set $node_id$iface_id IPv4 [join [getIfcIPv4addrs $node_id $iface_id] ";"]
		    $f.tree set $node_id$iface_id IPv6 [join [getIfcIPv6addrs $node_id $iface_id] ";"]
                    $f.tree set $node_id$iface_id MAC [getIfcMACaddr $node_id $iface_id]
		}
	    }
	}

	# filling the tree with link info
	global linktags

	set linktags ""
	$f.tree insert {} end -id links -text "Links" -open false -tags links
	foreach link_id [lsort -dictionary $link_list] {
	    set node1_id [lindex [getLinkPeers $link_id] 0]
	    set node2_id [lindex [getLinkPeers $link_id] 1]
	    set name0 [getNodeName $node1_id]
	    set name1 [getNodeName $node2_id]
	    $f.tree insert links end -id $link_id -text "From $name0 to $name1" -tags $link_id
	    lappend linktags $link_id
	}

	global expandtree
	set expandtree 0
	$f.tree heading #0 -command \
	    "expandOrCollapseTree"

	bindEventsToTree
    } else {
	destroy $f.treegrid
	destroy $f.tree $f.vscroll
	destroy $f.tree $f.hscroll
	destroy $f.buttons
	destroy $f.tree
    }
}

#****f* editor.tcl/expandOrCollapseTree
# NAME
#   expandOrCollapseTree -- expand or collapse tree
# SYNOPSIS
#   expandOrCollapseTree
# FUNCTION
#   Expands or collapses all tree items.
#****
proc expandOrCollapseTree {} {
    global expandtree

    if { $expandtree == 0 } {
	set expandtree 1
	set f .panwin.f2
	$f.tree heading #0 -text "(Collapse All)"
	$f.tree item nodes -open true
	$f.tree item links -open true
	foreach node_id [$f.tree children nodes] {
	    $f.tree item $node_id -open true
	}
    } else {
	set expandtree 0
	set f .panwin.f2
	$f.tree heading #0 -text "(Expand All)"
	$f.tree item nodes -open false
	$f.tree item links -open false
	foreach node_id [$f.tree children nodes] {
	    $f.tree item $node_id -open false
	}
    }
}

#****f* editor.tcl/bindEventsToTree
# NAME
#   bindEventsToTree -- bind events to tree
# SYNOPSIS
#   bindEventsToTree
# FUNCTION
#   Adds a Tk binding script for the specified
#   event sequence to the specified tag.
#****
proc bindEventsToTree {} {
    global nodetags linktags
    set f .panwin.f2
    $f.tree tag bind nodes <Key-Down> \
	"if { [llength $nodetags] != 0 } {
	    selectNodeFromTree [lindex $nodetags 0]
	}"

    $f.tree tag bind links <Key-Up> \
	"if { [llength $nodetags] != 0 } {
	    selectNodeFromTree [lindex $nodetags end]
	}"

    $f.tree tag bind links <Key-Down> \
	"if { [llength $linktags] != 0 } {
	    selectLinkPeersFromTree [lindex $linktags 0]
	}"

    $f.tree tag bind nodes <1> \
	  ".panwin.f1.c dtag node selected; \
	    .panwin.f1.c delete -withtags selectmark"

    $f.tree tag bind links <1> \
	  ".panwin.f1.c dtag node selected; \
	    .panwin.f1.c delete -withtags selectmark"

    foreach node_id $nodetags {
	set type [getNodeType $node_id]
	global selectedIfc
	$f.tree tag bind $node_id <1> \
	      "selectNodeFromTree $node_id"
	$f.tree tag bind $node_id <Key-Up> \
	    "if { ! [string equal {} [$f.tree prev $node_id]] } {
		selectNodeFromTree [$f.tree prev $node_id]
	    } else {
		.panwin.f1.c dtag node selected
		.panwin.f1.c delete -withtags selectmark
	    }"
	$f.tree tag bind $node_id <Key-Down> \
	    "if { ! [string equal {} [$f.tree next $node_id]] } {
		selectNodeFromTree [$f.tree next $node_id]
	    } else {
		.panwin.f1.c dtag node selected
		.panwin.f1.c delete -withtags selectmark
	    }"
	$f.tree tag bind $node_id <Double-1> \
	    "$type.configGUI .panwin.f1.c $node_id"
	$f.tree tag bind $node_id <Key-Return> \
	    "$type.configGUI .panwin.f1.c $node_id"
	foreach iface_id [lsort -dictionary [ifcList $node_id]] {
	    $f.tree tag bind $node_id$iface_id <Double-1> \
		"set selectedIfc $iface_id; \
		  $type.configGUI .panwin.f1.c $node_id; \
		  set selectedIfc \"\""
	    $f.tree tag bind $node_id$iface_id <Key-Return> \
		"set selectedIfc $iface_id; \
		  $type.configGUI .panwin.f1.c $node_id; \
		  set selectedIfc \"\""
	}
    }

    foreach link_id $linktags {
	$f.tree tag bind $link_id <1> \
	    "selectLinkPeersFromTree $link_id"
	$f.tree tag bind $link_id <Key-Up> \
	    "if { ! [string equal {} [$f.tree prev $link_id]] } {
		selectLinkPeersFromTree [$f.tree prev $link_id]
	    } else {
		.panwin.f1.c dtag node selected
		.panwin.f1.c delete -withtags selectmark
	    }"
	$f.tree tag bind $link_id <Key-Down> \
	    "if { ! [string equal {} [$f.tree next $link_id]] } {
		selectLinkPeersFromTree [$f.tree next $link_id]
	    }"
	$f.tree tag bind $link_id <Double-1> \
	    "link.configGUI .panwin.f1.c $link_id"
	$f.tree tag bind $link_id <Key-Return> \
	    "link.configGUI .panwin.f1.c $link_id"
    }
}

#****f* editor.tcl/selectNodeFromTree
# NAME
#   selectNodeFromTree -- select node from tree
# SYNOPSIS
#   selectNodeFromTree
# FUNCTION
#   Selects icon of the node selected in the topology tree.
#****
proc selectNodeFromTree { node_id } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas

    set canvas_id [getNodeCanvas $node_id]
    set curcanvas $canvas_id
    switchCanvas none

    .panwin.f1.c dtag node selected
    .panwin.f1.c delete -withtags selectmark

    set obj [.panwin.f1.c find withtag "node && $node_id"]
    selectNode .panwin.f1.c $obj
}

#****f* editor.tcl/selectLinkPeersFromTree
# NAME
#   selectLinkPeersFromTree -- select link peers from tree
# SYNOPSIS
#   selectLinkPeersFromTree
# FUNCTION
#   Selects icons of nodes that are endnodes
#   of the link selected in the topology tree.
#****
proc selectLinkPeersFromTree { link_id } {
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas

    set node1_id [lindex [getLinkPeers $link_id] 0]
    set node2_id [lindex [getLinkPeers $link_id] 1]
    set canvas_id [getNodeCanvas $node1_id]
    set curcanvas $canvas_id
    switchCanvas none

    .panwin.f1.c dtag node selected
    .panwin.f1.c delete -withtags selectmark

    set obj0 [.panwin.f1.c find withtag "node && $node1_id"]
    set obj1 [.panwin.f1.c find withtag "node && $node2_id"]
    selectNode .panwin.f1.c $obj0
    selectNode .panwin.f1.c $obj1
}

#****f* editor.tcl/refreshTopologyTree
# NAME
#   refreshTopologyTree -- refresh topology tree
# SYNOPSIS
#   refreshTopologyTree
# FUNCTION
#   Refreshes the topology tree.
#****
proc refreshTopologyTree {} {
    upvar 0 ::cf::[set ::curcfg]::node_list node_list
    upvar 0 ::cf::[set ::curcfg]::link_list link_list
    global nodetags linktags

    set f .panwin.f2
    set selected [$f.tree selection]

    $f.tree heading #0 -text "(Expand All)"

    $f.tree delete { nodes links }

    set nodetags ""
    $f.tree insert {} end -id nodes -text "Nodes" -open true -tags nodes
    foreach node_id [lsort -dictionary $node_list] {
	set type [getNodeType $node_id]
	if { $type != "pseudo" } {
	    $f.tree insert nodes end -id $node_id -text "[getNodeName $node_id]" -tags $node_id
	    lappend nodetags $node_id
	    $f.tree set $node_id canvas [getCanvasName [getNodeCanvas $node_id]]
	    foreach iface_id [lsort -dictionary [ifcList $node_id]] {
		    $f.tree insert $node_id end -id $node_id$iface_id -text "$iface_id" -tags $node_id$iface_id
		    $f.tree set $node_id$iface_id state [getIfcOperState $node_id $iface_id]
		    $f.tree set $node_id$iface_id nat [getIfcNatState $node_id $iface_id]
		    $f.tree set $node_id$iface_id IPv4 [join [getIfcIPv4addrs $node_id $iface_id] ";"]
		    $f.tree set $node_id$iface_id IPv6 [join [getIfcIPv6addrs $node_id $iface_id] ";"]
                    $f.tree set $node_id$iface_id MAC [getIfcMACaddr $node_id $iface_id]
	    }
	}
    }

    set linktags ""
    $f.tree insert {} end -id links -text "Links" -open false -tags links
    foreach link_id [lsort -dictionary $link_list] {
	set node1_id [lindex [getLinkPeers $link_id] 0]
	set node2_id [lindex [getLinkPeers $link_id] 1]
	set name0 [getNodeName $node1_id]
	set name1 [getNodeName $node2_id]
	$f.tree insert links end -id $link_id -text "From $name0 to $name1" -tags $link_id
	lappend linktags $link_id
    }

    if { [$f.tree exists $selected] } {
	$f.tree focus $selected
	$f.tree selection set $selected
    } else {
	$f.tree focus nodes
	$f.tree selection set nodes
    }

    bindEventsToTree
}

#****f* editor.tcl/attachToExperimentPopup
# NAME
#   attachToExperimentPopup -- attach to experiment popup
# SYNOPSIS
#   attachToExperimentPopup
# FUNCTION
#   Creates a popup dialog box to attach to experiment.
#****
proc attachToExperimentPopup {} {
    global selectedExperiment runtimeDir

    set ateDialog .attachToExperimentDialog
    catch { destroy $ateDialog }

    toplevel $ateDialog
    wm transient $ateDialog .
    wm resizable $ateDialog 0 0
    wm title $ateDialog "Attach to experiment"
    wm iconname $ateDialog "Attach to experiment"

    set wi [ttk::frame $ateDialog.mainframe]

    ttk::panedwindow $wi.expChooser -orient horizontal
    pack $wi.expChooser -fill both

    #left and right pane
    ttk::frame $wi.expChooser.left -relief groove -borderwidth 3
    pack  $wi.expChooser.left
    ttk::frame $wi.expChooser.right -relief groove -borderwidth 3
    pack  $wi.expChooser.right

    #right pane definition
    set prevcan [canvas $wi.expChooser.right.pc -bd 0 -relief sunken -highlightthickness 0 \
    		-width 300 -height 210 -background white]
    pack $prevcan -anchor center
    $prevcan create text 150 105 -text "(Preview)" -tags "preview"

    $wi.expChooser add $wi.expChooser.left
    $wi.expChooser add $wi.expChooser.right
    pack $wi

    ttk::frame $wi.expChooser.left.grid
    pack $wi.expChooser.left.grid -expand 1 -fill both

    set tree $wi.expChooser.left.tree
    ttk::treeview $tree -columns "type" -height 5 -selectmode browse \
    	-xscrollcommand "$wi.expChooser.left.hscroll set"\
        -yscrollcommand "$wi.expChooser.left.vscroll set"
    ttk::scrollbar $wi.expChooser.left.hscroll -orient horizontal -command "$wi.expChooser.left.tree xview"
    ttk::scrollbar $wi.expChooser.left.vscroll -orient vertical -command "$wi.expChooser.left.tree yview"

    grid $wi.expChooser.left.tree $wi.expChooser.left.vscroll -in $wi.expChooser.left.grid -sticky nsew
    #disabled for now, if the addition of new columns happens it will be useful
    #grid $wi.expChooser.left.up.hscroll -in $wi.expChooser.left.up.grid -sticky nsew
    grid columnconfig $wi.expChooser.left.grid 0 -weight 1
    grid rowconfigure $wi.expChooser.left.grid 0 -weight 1

    $tree heading #0 -text "Experiment ID"
    $tree column #0 -width 240 -minwidth 100
    $tree heading type -text "Timestamp"
    $tree column type -width 200 -stretch 0 -minwidth 90
    focus $tree

    foreach exp [getResumableExperiments] {
	set timestamp [getExperimentTimestampFromFile $exp]
	$tree insert {} end -id $exp -text [list $exp "-" [getExperimentNameFromFile $exp]] -values [list $timestamp] \
	          -tags "$exp"
	$tree tag bind $exp <1> \
	  "updateScreenshotPreview $prevcan $runtimeDir/$exp/screenshot.png
	   set selectedExperiment $exp"
    }

    foreach exp [getResumableExperiments] {
	$tree tag bind $exp <Key-Up> \
	"if { ! [string equal {} [$tree prev $exp]] } {
	    updateScreenshotPreview $prevcan $runtimeDir/[$tree prev $exp]/screenshot.png
	    set selectedExperiment [$tree prev $exp]
	}"
	$tree tag bind $exp <Key-Down> \
	"if { ! [string equal {} [$tree next $exp]] } {
	    updateScreenshotPreview $prevcan $runtimeDir/[$tree next $exp]/screenshot.png
	    set selectedExperiment [$tree next $exp]
	}"
	$tree tag bind $exp <Double-1> "resumeAndDestroy"
    }

    set first [lindex [getResumableExperiments] 0]
    $tree selection set $first
    $tree focus $first
    set selectedExperiment $first

    if { $selectedExperiment != "" } {
	updateScreenshotPreview $prevcan $runtimeDir/$selectedExperiment/screenshot.png
    }

    ttk::frame $wi.buttons
    pack $wi.buttons -side bottom -fill x -pady 2m
    ttk::button $wi.buttons.resume -text "Resume selected experiment" -command "resumeAndDestroy"
    ttk::button $wi.buttons.cancel -text "Cancel" -command "destroy $ateDialog"
    pack $wi.buttons.cancel $wi.buttons.resume -side right -expand 1

    bind $ateDialog <Key-Return> { resumeSelectedExperiment $selectedExperiment; destroy .attachToExperimentDialog }
    bind $ateDialog <Key-Escape> "destroy $ateDialog"
}

#****f* editor.tcl/resumeAndDestroy
# NAME
#   resumeAndDestroy -- resume experiment and destroy dialog
# SYNOPSIS
#   resumeAndDestroy
# FUNCTION
#   Resumes selected experiment and destroys a "Resume experiment" dialog.
#****
proc resumeAndDestroy {} {
    global selectedExperiment

    if { $selectedExperiment != "" } {
	resumeSelectedExperiment $selectedExperiment
    }

    destroy .attachToExperimentDialog
}

#****f* editor.tcl/updateScreenshotPreview
# NAME
#   updateScreenshotPreview -- update screenshot preview
# SYNOPSIS
#   updateScreenshotPreview $pc $image
# FUNCTION
#   Updates the screenshot preview.
# INPUTS
#   * pc -- selected pc
#   * image -- image file
#****
proc updateScreenshotPreview { pc image } {
    $pc delete "preview"
    if { [file exists $image] } {
	image create photo screenshot -file $image
	$pc create image 150 105 -image screenshot -tags "preview"
    } else {
	$pc create text 150 100 -text "No screenshot available." -tags "preview"
    }
}

#****f* editor.tcl/setActiveTool
# NAME
#   setActiveTool -- set active tool
# SYNOPSIS
#   setActiveTool $tool
# FUNCTION
#   Sets the active tool to $tool and enables/disables
#   the TopoGen submenus.
# INPUTS
#   * tool -- active tool to set
#****
proc setActiveTool { tool } {
    global activetool mf ROOTDIR LIBDIR

    set ungrouped "select link rectangle oval freeform text"
    if { $activetool in $ungrouped } {
	$mf.left.$activetool state !selected
    } elseif { [$activetool.netlayer] == "LINK" } {
	$mf.left.link_layer state !selected
    } elseif { [$activetool.netlayer] == "NETWORK" } {
	$mf.left.net_layer state !selected
    }

    if { $tool in $ungrouped } {
	$mf.left.$tool state selected
    } elseif { [$tool.netlayer] == "LINK" } {
	set image [image create photo -file [$tool.icon toolbar]]
	set arrowimage [image create photo -file "$ROOTDIR/$LIBDIR/icons/tiny/l2.gif"]
	$image copy $arrowimage -from 29 30 40 40 -to 29 30 40 40 -compositingrule overlay
	$mf.left.link_layer configure -image $image
	$mf.left.link_layer state selected
    } elseif { [$tool.netlayer] == "NETWORK" } {
	set image [image create photo -file [$tool.icon toolbar]]
	set arrowimage [image create photo -file "$ROOTDIR/$LIBDIR/icons/tiny/l3.gif"]
	$image copy $arrowimage -from 29 30 40 40 -to 29 30 40 40 -compositingrule overlay
	$mf.left.net_layer configure -image $image
	$mf.left.net_layer state selected
    }

    set activetool $tool

    if { $tool in "router pc host" } {
	set state normal
    } else {
	set state disabled
    }

    for { set i 0 } { $i <= [.menubar.t_g index last] } { incr i } {
	.menubar.t_g entryconfigure $i -state $state
    }
}

proc launchBrowser { url } {
    global tcl_platform env

    if { $tcl_platform(platform) eq "windows" } {
	set command [list {*}[auto_execok start] {}]
	set url [string map {& ^&} $url]
    } elseif { $tcl_platform(os) eq "Darwin" } {
	set command [list open]
    } else {
	set command [list xdg-open]
    }

    if { $tcl_platform(platform) eq "windows" } {
	catch { exec {*}$command $url }
    } elseif { "SUDO_USER" in [array names env] } {
	catch { exec su - $env(SUDO_USER) /bin/sh -c "$command $url" > /dev/null 2> /dev/null & }
    } else {
	catch { exec {*}$command $url > /dev/null 2> /dev/null & }
    }
}
