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
# BUG
# 'Redo' visible after changing the config when not in top undolevel
# Repro:
#  1. add any node
#  2. click Undo
#  3. add any node
# Should reset redolog when changing config from somewhere in undolog
proc updateUndoLog {} {
	global changed showTree

	set undolevel [getFromRunning "undolevel"]

	if { $changed } {
		setToRunning "undolevel" [incr undolevel]
		if { $undolevel == 1 } {
			.menubar.edit entryconfigure "Undo" -state normal
		}

		saveToUndoLevel $undolevel
		setToRunning "redolevel" $undolevel
		set changed 0

		# When some changes are made in the topology, new /etc/hosts files
		# should be generated.
		setToRunning "etc_hosts" ""
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
	global showTree changed nodeNamingBase

	set undolevel [getFromRunning "undolevel"]
	if { [getFromRunning "oper_mode"] == "edit" && $undolevel > 0 } {
		.menubar.edit entryconfigure "Redo" -state normal
		setToRunning "undolevel" [incr undolevel -1]
		if { $undolevel == 0 } {
			.menubar.edit entryconfigure "Undo" -state disabled
		}

		.panwin.f1.c config -cursor watch

		jumpToUndoLevel $undolevel
		switchCanvas none

		if { $showTree } {
			refreshTopologyTree
		}

		foreach node_type [array names nodeNamingBase] {
			recalculateNumType $node_type $nodeNamingBase($node_type)
		}
	}

	if { $changed } {
		redrawAll
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
	global showTree changed nodeNamingBase

	set undolevel [getFromRunning "undolevel"]
	set redolevel [getFromRunning "redolevel"]
	if { [getFromRunning "oper_mode"] == "edit" && $redolevel > $undolevel } {
		setToRunning "undolevel" [incr undolevel]
		if { $undolevel == 1 } {
			.menubar.edit entryconfigure "Undo" -state normal
		}

		if { $redolevel <= $undolevel } {
			.menubar.edit entryconfigure "Redo" -state disabled
		}

		.panwin.f1.c config -cursor watch

		jumpToUndoLevel $undolevel
		switchCanvas none

		if { $showTree } {
			refreshTopologyTree
		}

		foreach node_type [array names nodeNamingBase] {
			recalculateNumType $node_type $nodeNamingBase($node_type)
		}
	}

	if { $changed } {
		redrawAll
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
	set iface_prefix [[getNodeType $lnode_id].ifacePrefix]

	set ifaces {}
	foreach {iface_id iface_cfg} [cfgGet "nodes" $lnode_id "ifaces"] {
		if { [dictGet $iface_cfg "type"] == "phys" } {
			set iface_name [dictGet $iface_cfg "name"]
			if { [regexp "$iface_prefix\[0-9\]+" $iface_name] } {
				lappend ifaces $iface_name
			}
		}
	}

	return [newObjectId $ifaces $iface_prefix]
}

proc _chooseIfaceName { node_cfg } {
	set iface_prefix [[dictGet $node_cfg "type"].ifacePrefix]

	set ifaces {}
	foreach {iface_id iface_cfg} [dictGet $node_cfg "ifaces"] {
		if { [dictGet $iface_cfg "type"] == "phys" } {
			set iface_name [dictGet $iface_cfg "name"]
			if { [regexp "$iface_prefix\[0-9\]+" $iface_name] } {
				lappend ifaces $iface_name
			}
		}
	}

	return [newObjectId $ifaces $iface_prefix]
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
		lassign [logicalPeerByIfc $l2node_id $iface_id] peer_id peer_iface_id
		if { [getIfcLink $peer_id $peer_iface_id] == "" } {
			continue
		}

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
	$w.setzoom.e1 insert 0 [expr {int([getFromRunning "zoom"] * 100)}]
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
	set newzoom [expr [$w.setzoom.e1 get] / 100.0]
	if { $newzoom != [getFromRunning "zoom"] } {
		setToRunning "zoom" $newzoom
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
	$w.selectzoom.e1 insert 0 [expr {int([getFromRunning "zoom"] * 100)}]
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
	if { $newzoom != [getFromRunning "zoom"] } {
		setToRunning "zoom" $newzoom

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
	global changed router_model routerDefaultsModel router_ConfigModel
	global routerRipEnable routerRipngEnable routerOspfEnable routerOspf6Enable routerBgpEnable routerLdpEnable
	global rdconfig

	set rdconfig "$routerRipEnable $routerRipngEnable $routerOspfEnable $routerOspf6Enable $routerBgpEnable $routerLdpEnable"
	set routerDefaultsModel $router_model

	set selected_node_list [selectedNodes]
	if { $selected_node_list == {} } {
		destroy $wi

		return
	}

	foreach node_id $selected_node_list {
		if { [getNodeType $node_id] == "router" } {
			setNodeModel $node_id $router_model

			set router_ConfigModel $router_model
			if { $router_ConfigModel != "static" } {
				lassign $rdconfig ripEnable ripngEnable ospfEnable ospf6Enable bgpEnable ldpEnable
				setNodeProtocol $node_id "rip" $ripEnable
				setNodeProtocol $node_id "ripng" $ripngEnable
				setNodeProtocol $node_id "ospf" $ospfEnable
				setNodeProtocol $node_id "ospf6" $ospf6Enable
				setNodeProtocol $node_id "bgp" $bgpEnable
				setNodeProtocol $node_id "ldp" $ldpEnable
			}
			set changed 1
		}
	}

	if { $changed == 1 } {
		undeployCfg
		deployCfg

		redrawAll
		updateUndoLog
	}

	destroy $wi
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
	set x 0
	set y 0
	foreach node_id [getFromRunning "node_list"] {
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
	global showTree

	set f .panwin.f2
	if { ! $showTree } {
		.panwin forget $f
	}

	if { $showTree } {
		bind . <Right> ""
		bind . <Left> ""
		bind . <Down> ""
		bind . <Up> ""

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
		global nodetags ifacestags

		set nodetags ""
		set ifacestags ""
		$f.tree insert {} end -id nodes -text "Nodes" -open true -tags nodes
		$f.tree focus nodes
		$f.tree selection set nodes
		foreach node_id [lsort -dictionary [getFromRunning "node_list"]] {
			set type [getNodeType $node_id]
			if { $type != "pseudo" } {
				$f.tree insert nodes end -id $node_id -text "[getNodeName $node_id]" -open false -tags $node_id
				lappend nodetags $node_id
				$f.tree set $node_id canvas [getCanvasName [getNodeCanvas $node_id]]
				foreach iface_id [lsort -dictionary [ifcList $node_id]] {
					lappend ifacestags $node_id$iface_id

					$f.tree insert $node_id end -id $node_id$iface_id -text "[getIfcName $node_id $iface_id]" -tags $node_id$iface_id
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
		foreach link_id [lsort -dictionary [getFromRunning "link_list"]] {
			lassign [getLinkPeers $link_id] node1_id node2_id
			$f.tree insert links end -id $link_id -text \
				"From [getNodeName $node1_id] to [getNodeName $node2_id]" -tags $link_id
			lappend linktags $link_id
		}

		global expandtree

		set expandtree 0
		$f.tree heading #0 -command "expandOrCollapseTree"

		bindEventsToTree
	} else {
		# main frame where the canvas .c is
		global mf

		bind . <Right> "$mf.c xview scroll 1 units"
		bind . <Left> "$mf.c xview scroll -1 units"
		bind . <Down> "$mf.c yview scroll 1 units"
		bind . <Up> "$mf.c yview scroll -1 units"

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
	global nodetags ifacestags linktags

	set f .panwin.f2
	bind $f.tree <<TreeviewSelect>> {
		global nodetags ifacestags linktags

		set f .panwin.f2
		set selection [$f.tree selection]
		set item_tags [$f.tree item $selection -tags]
		if { $item_tags in $nodetags } {
			selectNodeFromTree $selection
		} elseif { $item_tags in $ifacestags } {
			# remove ifc from selection to get this node_id
			regsub {ifc[0-9]*} $selection "" selection

			selectNodeFromTree $selection
		} elseif { $item_tags in $linktags } {
			selectLinkPeersFromTree $selection
		}
	}

	# set last argument as empty string
	set tmp_command [list apply {
		{ nodetags_length selected_node } {
			if { $nodetags_length != 0 } {
				selectNodeFromTree $selected_node
			}
		}
	} \
		[llength $nodetags] \
		""
	]

	# replace last argument for each binding
	$f.tree tag bind nodes <Key-Down> \
		[lreplace $tmp_command end end [lindex $nodetags 0]]
	$f.tree tag bind links <Key-Up> \
		[lreplace $tmp_command end end [lindex $nodetags end]]

	set tmp_command [list apply {
		{ linktags_length selected_link } {
			if { $linktags_length != 0 } {
				selectLinkPeersFromTree $selected_link
			}
		}
	} \
		[llength $linktags] \
		[lindex $linktags end]
	]
	$f.tree tag bind links <Key-Down> $tmp_command

	set tmp_command \
		".panwin.f1.c dtag node selected; \
		.panwin.f1.c delete -withtags selectmark"
	$f.tree tag bind nodes <1> $tmp_command
	$f.tree tag bind links <1> $tmp_command

	foreach node_id $nodetags {
		global selectedIfc

		set type [getNodeType $node_id]
		set tmp_command \
			"$f.tree item $node_id -open false; \
			$type.configGUI .panwin.f1.c $node_id"
		$f.tree tag bind $node_id <Double-1> $tmp_command
		$f.tree tag bind $node_id <Key-Return> $tmp_command

		foreach iface_id [lsort -dictionary [ifcList $node_id]] {
			set tmp_command \
				"set selectedIfc $iface_id; \
				$type.configGUI .panwin.f1.c $node_id; \
				set selectedIfc \"\""
			$f.tree tag bind $node_id$iface_id <Double-1> $tmp_command
			$f.tree tag bind $node_id$iface_id <Key-Return> $tmp_command
		}
	}

	foreach link_id $linktags {
		set tmp_command "link.configGUI .panwin.f1.c $link_id"
		$f.tree tag bind $link_id <Double-1> $tmp_command
		$f.tree tag bind $link_id <Key-Return> $tmp_command
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
	setToRunning "curcanvas" [getNodeCanvas $node_id]
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
	lassign [getLinkPeers $link_id] node1_id node2_id
	setToRunning "curcanvas" [getNodeCanvas $node1_id]
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
	global nodetags ifacestags linktags

	set f .panwin.f2
	set selected [$f.tree selection]

	$f.tree heading #0 -text "(Expand All)"

	$f.tree delete { nodes links }

	set nodetags ""
	set ifacestags ""
	$f.tree insert {} end -id nodes -text "Nodes" -open true -tags nodes
	foreach node_id [lsort -dictionary [getFromRunning "node_list"]] {
		set type [getNodeType $node_id]
		if { $type != "pseudo" } {
			$f.tree insert nodes end -id $node_id -text "[getNodeName $node_id]" -tags $node_id
			lappend nodetags $node_id
			$f.tree set $node_id canvas [getCanvasName [getNodeCanvas $node_id]]
			foreach iface_id [lsort -dictionary [ifcList $node_id]] {
				lappend ifacestags $node_id$iface_id

				$f.tree insert $node_id end -id $node_id$iface_id -text "[getIfcName $node_id $iface_id]" -tags $node_id$iface_id
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
	foreach link_id [lsort -dictionary [getFromRunning "link_list"]] {
		lassign [getLinkPeers $link_id] node1_id node2_id
		$f.tree insert links end -id $link_id -text \
			"From [getNodeName $node1_id] to [getNodeName $node2_id]" -tags $link_id
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
	global selected_experiment runtimeDir

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
		$tree insert {} end \
			-id $exp \
			-text [list $exp "-" [getExperimentNameFromFile $exp]] \
			-values [list $timestamp] \
			-tags "$exp"
	}

	set set_selected_experiment_command {
		{ prevcan exp } {
			if { $exp == "" } {
				return
			}

			global runtimeDir selected_experiment

			updateScreenshotPreview $prevcan $runtimeDir/$exp/screenshot.png
			set selected_experiment $exp
		}
	}

	foreach exp [getResumableExperiments] {
		set tmp_command [list apply $set_selected_experiment_command \
			$prevcan \
			$exp
		]
		$tree tag bind $exp <1> $tmp_command

		set tmp_command [list apply $set_selected_experiment_command \
			$prevcan \
			[$tree prev $exp]
		]
		$tree tag bind $exp <Key-Up> $tmp_command

		set tmp_command [list apply $set_selected_experiment_command \
			$prevcan \
			[$tree next $exp]
		]
		$tree tag bind $exp <Key-Down> $tmp_command

		$tree tag bind $exp <Double-1> "resumeAndDestroy"
	}

	set first [lindex [getResumableExperiments] 0]
	$tree selection set $first
	$tree focus $first
	set selected_experiment $first

	if { $selected_experiment != "" } {
		updateScreenshotPreview $prevcan $runtimeDir/$selected_experiment/screenshot.png
	}

	ttk::frame $wi.buttons
	pack $wi.buttons -side bottom -fill x -pady 2m
	ttk::button $wi.buttons.resume -text "Resume selected experiment" -command "resumeAndDestroy"
	ttk::button $wi.buttons.cancel -text "Cancel" -command "destroy $ateDialog"
	pack $wi.buttons.cancel $wi.buttons.resume -side right -expand 1

	bind $ateDialog <Key-Return> "resumeAndDestroy"
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
	global selected_experiment

	if { $selected_experiment != "" } {
		resumeSelectedExperiment $selected_experiment
	}

	destroy .attachToExperimentDialog
	toggleAutoExecutionGUI [getFromRunning "auto_execution"]
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

#****f* editor.tcl/setActiveToolGroup
# NAME
#   setActiveToolGroup -- set active tool group
# SYNOPSIS
#   setActiveToolGroup $group
# FUNCTION
#   Sets the active tool group to $group and enables/disables
#   the TopoGen submenus.
# INPUTS
#   * group -- active tool group to set
#****
proc setActiveToolGroup { group } {
	global active_tool_group active_tools tool_groups
	global all_modules_list mf ROOTDIR LIBDIR

	set tool [lindex [dict get $tool_groups $group] [dict get $active_tools $group]]

	$mf.left.$active_tool_group state !selected
	set active_tool_group $group
	$mf.left.$active_tool_group state selected

	if { [llength [dict get $tool_groups $group]] > 1 } {
		set image [image create photo -file [$tool.icon toolbar]]
		# TODO: Create an arrow image programatically
		set arrow_source "$ROOTDIR/$LIBDIR/icons/tiny/l2.gif"
		set arrow_image [image create photo -file $arrow_source]
		$image copy $arrow_image -from 29 30 40 40 -to 29 30 40 40 -compositingrule overlay
		$mf.left.$group configure -image $image
		$mf.left.$group state selected
	}

	if { $tool in $all_modules_list } {
		set state normal
	} else {
		set state disabled
	}

	for { set i 0 } { $i <= [.menubar.t_g index last] } { incr i } {
		.menubar.t_g entryconfigure $i -state $state
	}
}

#****f* editor.tcl/setActiveTool
# NAME
#   setActiveTool -- set active tool group
# SYNOPSIS
#   setActiveTool $group $tool
# FUNCTION
#   Sets the active tool group to $group and active tool to $tool.
# INPUTS
#   * group -- active tool group to set
#   * tool -- active tool to set
#****
proc setActiveTool { group tool } {
	global tool_groups active_tools

	dict set active_tools $group [lsearch [dict get $tool_groups $group] $tool]
	setActiveToolGroup $group
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

proc toggleAutoExecutionGUI { { new_value "" } } {
	if { $new_value == "" } {
		toggleAutoExecution
	}

	for { set index 0 } { $index <= [.menubar.experiment index last] } { incr index } {
		catch { .menubar.experiment entrycget $index -label } label_str
		if { $label_str == "Pause execution" } {
			if { $new_value != "" && $new_value } {
				break
			}

			.menubar.experiment entryconfigure $index -label "Resume execution" -underline 3
			if { [getFromRunning "cfg_deployed"] } {
				.bottom.oper_mode configure -text "paused"
				.bottom.oper_mode configure -foreground "red"
			}

			break
		} elseif { $label_str == "Resume execution" } {
			if { $new_value != "" && ! $new_value } {
				break
			}

			.menubar.experiment entryconfigure $index -label "Pause execution" -underline 2
			redrawAll
			if { [getFromRunning "cfg_deployed"] } {
				.bottom.oper_mode configure -text "exec mode"
				.bottom.oper_mode configure -foreground "black"
			}

			break
		}
	}
}

#****f* editor.tcl/cycleToolGroup
# NAME
#   cycleToolGroup -- bind
# SYNOPSIS
#   cycleToolGroup $group
# FUNCTION
#   Sets the active tool group to $group.
#   If the active tool group already was set to $group
#   it will cycle through tools withing the group.
# INPUTS
#   * group -- tool group to which should be activated
#****
proc cycleToolGroup { group } {
	global active_tool_group active_tools tool_groups runnable_node_types show_unsupported_nodes
	global newnode newlink newoval newrect newtext newfree

	if { "$newnode$newlink$newoval$newrect$newtext$newfree" != "" } {
		return
	}

	set tools [dict get $tool_groups $group]
	if { [llength $tools] == 0 } {
		return
	}

	if { $active_tool_group == $group && [llength [dict get $tool_groups $group]] > 1} {
		set tool_count [llength [dict get $tool_groups $active_tool_group]]
		set start_index [dict get $active_tools $active_tool_group]
		set index [expr ($start_index + 1) % $tool_count]
		if { ! $show_unsupported_nodes } {
			while { [lindex $tools $index] ni $runnable_node_types } {
				set index [expr ($index + 1) % $tool_count]
				if { $index == $start_index } {
					break
				}
			}
		}
		dict set active_tools $group $index
	}

	setActiveToolGroup $group
}

#****f* editor.tcl/getActiveTool
# NAME
#   getActiveTool -- get active tool
# SYNOPSIS
#   getActiveTool
# FUNCTION
#   Returns the currently active tool.
#****
proc getActiveTool {} {
	global active_tool_group tool_groups active_tools

	return [lindex [dict get $tool_groups $active_tool_group] [dict get $active_tools $active_tool_group]]
}

#****f* editor.tcl/addTool
# NAME
#   addTool -- add tool to a tool group
# SYNOPSIS
#   addTool $group $tool
# FUNCTION
#   Adds a tool $tool to a tool group $group.
# INPUTS
#   * group -- tool group to which to add to
#   * tool -- tool which to add
#****
proc addTool { group tool } {
	global active_tools tool_groups

	try {
		set old_tools [dict get $tool_groups $group]
	} on error {} {
		set old_tools {}
		dict set active_tools $group 0
	}

	dict set tool_groups $group [lappend old_tools {*}$tool]
}
