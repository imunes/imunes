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
	global showTree changed all_modules_list main_canvas_elem

	set undolevel [getFromRunning "undolevel"]
	if { [getFromRunning "oper_mode"] == "edit" && $undolevel > 0 } {
		.menubar.edit entryconfigure "Redo" -state normal
		setToRunning "undolevel" [incr undolevel -1]
		if { $undolevel == 0 } {
			.menubar.edit entryconfigure "Undo" -state disabled
		}

		$main_canvas_elem config -cursor watch

		jumpToUndoLevel $undolevel
		switchCanvas none

		if { $showTree } {
			refreshTopologyTree
		}

		foreach node_type $all_modules_list {
			recalculateNumType $node_type [invokeTypeProc $node_type "namingBase"]
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
	global showTree changed all_modules_list main_canvas_elem

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

		$main_canvas_elem config -cursor watch

		jumpToUndoLevel $undolevel
		switchCanvas none

		if { $showTree } {
			refreshTopologyTree
		}

		foreach node_type $all_modules_list {
			recalculateNumType $node_type [invokeTypeProc $node_type "namingBase"]
		}
	}

	if { $changed } {
		redrawAll
	}
}

#****f* editor.tcl/checkLinkColor
# NAME
#   checkLinkColor -- check link color
# SYNOPSIS
#   set check [checkLinkColor $str]
# FUNCTION
#   This procedure checks the input string to see if it matches
#   one of the available link colors.
# INPUTS
#   str -- string to check
# RESULT
#   * check -- set to 1 if the str is one of the link colors 0 otherwise.
#****
proc checkLinkColor { str } {
	global named_colors

	if { $str == "" } {
		return 1
	}

	if { $str ni $named_colors} {
		return 0
	}

	return 1
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
	$w.setzoom.e1 insert 0 [expr {int([getActiveOption "zoom"] * 100)}]
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
	if { $newzoom != [getActiveOption "zoom"] } {
		setGlobalOption "zoom" $newzoom
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
	$w.selectzoom.e1 insert 0 [expr {int([getActiveOption "zoom"] * 100)}]
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
	if { $newzoom != [getActiveOption "zoom"] } {
		setGlobalOption "zoom" $newzoom

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
	global changed

	set router_frame $wi.routerframe

	set oldmodel [getActiveOption "routerDefaultsModel"]
	foreach newmodel "frr quagga static" {
		if { "selected" in [$router_frame.model.$newmodel state] } {
			break
		}
	}

	if { $oldmodel != $newmodel } {
		setGlobalOption "routerDefaultsModel" $newmodel
	}

	set protocols {
		"rip	routerRipEnable"
		"ripng	routerRipngEnable"
		"ospf	routerOspfEnable"
		"ospf6	routerOspf6Enable"
		"bgp	routerBgpEnable"
		"ldp	routerLdpEnable"
		"isis	routerIsisEnable"
	}

	foreach item $protocols {
		lassign $item protocol var_name

		set oldvalue [getActiveOption $var_name]
		set newvalue [expr { "selected" in [$router_frame.protocols.$protocol state] }]
		if { $oldvalue != $newvalue } {
			setGlobalOption $var_name $newvalue
		}
	}

	set selected_node_list [selectedNodes]
	if { $selected_node_list == {} } {
		destroy $wi

		return
	}

	foreach node_id $selected_node_list {
		if { [getNodeType $node_id] == "router" } {
			setNodeModel $node_id [getActiveOption "routerDefaultsModel"]

			foreach item $protocols {
				lassign $item protocol var_name
				setNodeProtocol $node_id $protocol [getActiveOption $var_name]
			}
			set changed 1
		}
	}

	if { $changed == 1 } {
		if { [getFromRunning "stop_sched"] } {
			redeployCfg
		}

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
	set curcanvas [getFromRunning_gui "curcanvas"]

	set x 0
	set y 0
	foreach node_id [getFromRunning "node_list"] {
		if { [getNodeCanvas $node_id] != $curcanvas } {
			continue
		}

		set coords [getNodeCoords $node_id]
		if { [lindex $coords 0] > $x } {
			set x [lindex $coords 0]
		}

		if { [lindex $coords 1] > $y } {
			set y [lindex $coords 1]
		}
	}

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
			if { [getNodeType $node_id] != "pseudo" } {
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
		global mf

		bind . <Right> "$mf.canvas_elem xview scroll 1 units"
		bind . <Left> "$mf.canvas_elem xview scroll -1 units"
		bind . <Down> "$mf.canvas_elem yview scroll 1 units"
		bind . <Up> "$mf.canvas_elem yview scroll -1 units"

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
	global nodetags ifacestags linktags main_canvas_elem

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
		"$main_canvas_elem dtag node selected; \
		$main_canvas_elem delete -withtags selectmark"
	$f.tree tag bind nodes <1> $tmp_command
	$f.tree tag bind links <1> $tmp_command

	foreach node_id $nodetags {
		global selectedIfc

		set node_type [getNodeType $node_id]
		set tmp_command \
			"$f.tree item $node_id -open false; \
			invokeTypeProc $node_type gui::configGUI $node_id"
		$f.tree tag bind $node_id <Double-1> $tmp_command
		$f.tree tag bind $node_id <Key-Return> $tmp_command

		foreach iface_id [lsort -dictionary [ifcList $node_id]] {
			set tmp_command \
				"set selectedIfc $iface_id; \
				invokeTypeProc $node_type gui::configGUI $node_id; \
				set selectedIfc \"\""
			$f.tree tag bind $node_id$iface_id <Double-1> $tmp_command
			$f.tree tag bind $node_id$iface_id <Key-Return> $tmp_command
		}
	}

	foreach link_id $linktags {
		set tmp_command "link.configGUI $link_id"
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
	global main_canvas_elem

	setToRunning_gui "curcanvas" [getNodeCanvas $node_id]
	switchCanvas none

	$main_canvas_elem dtag node selected
	$main_canvas_elem delete -withtags selectmark

	set obj [$main_canvas_elem find withtag "node && $node_id"]
	selectNode $obj
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
	global main_canvas_elem

	lassign [getLinkPeers $link_id] node1_id node2_id
	setToRunning_gui "curcanvas" [getNodeCanvas $node1_id]
	switchCanvas none

	$main_canvas_elem dtag node selected
	$main_canvas_elem delete -withtags selectmark

	set obj0 [$main_canvas_elem find withtag "node && $node1_id"]
	set obj1 [$main_canvas_elem find withtag "node && $node2_id"]
	selectNode $obj0
	selectNode $obj1
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
		if { [getNodeType $node_id] != "pseudo" } {
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
	global selected_experiment runtimeDir gui

	catch { rexec id -u } uid
	if { $uid != "0" } {
		set err "Error: To attach to experiments, run IMUNES with root permissions."

		if { $gui } {
			after idle { .dialog1.msg configure -wraplength 5i }
			tk_dialog .dialog1 "IMUNES error" \
				$err \
				info 0 Dismiss
		} else {
			sputs stderr $err
		}

		return
	}

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

	set exp_list [getResumableExperiments]
	foreach exp $exp_list {
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

	foreach exp $exp_list {
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

	set first [lindex $exp_list 0]
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

	switchCanvas none
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

	set tools [dict get $tool_groups $group]
	set tool [lindex $tools [dict get $active_tools $group]]

	set visible_tools [visibleTools $group $tools]
	set visible_count [llength $visible_tools]

	$mf.left.$active_tool_group state !selected
	if { $visible_count > 0 } {
		set active_tool_group $group
	} elseif { $active_tool_group == $group } {
		set active_tool_group select
	}
	$mf.left.$active_tool_group state selected

	if { [llength $tools] > 1 } {
		if { $visible_count == 0 || $tool ni $visible_tools } {
			if { $group == "link_layer" } {
				set image [image create photo -file $ROOTDIR/$LIBDIR/icons/tiny/l2.gif]
			} else {
				set image [image create photo -file $ROOTDIR/$LIBDIR/icons/tiny/l3.gif]
			}
		} else {
			set image [image create photo -file [invokeTypeProc $tool "gui::icon" "toolbar"]]
		}
		# TODO: Create an arrow image programatically
		set arrow_source "$ROOTDIR/$LIBDIR/icons/tiny/l2.gif"
		set arrow_image [image create photo -file $arrow_source]
		$image copy $arrow_image -from 29 30 40 40 -to 29 30 40 40 -compositingrule overlay
		$mf.left.$group configure -image $image
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
			.menubar.events entryconfigure "Start scheduling" -state disabled
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
			.menubar.events entryconfigure "Start scheduling" -state normal
			redrawAll
			if { [getFromRunning "cfg_deployed"] } {
				.bottom.oper_mode configure -text "exec mode"
				.bottom.oper_mode configure -foreground "black"
			}

			break
		}
	}
}

proc visibleTools { group tools } {
	global runnable_node_types

	set hidden_node_types [getActiveOption "hidden_node_types"]
	set show_unsupported_nodes [getActiveOption "show_unsupported_nodes"]

	if { $group in "link_layer net_layer" } {
		set visible_tools {}
		foreach tool $tools {
			if {
				($show_unsupported_nodes || $tool in $runnable_node_types) &&
				$tool ni $hidden_node_types
			} {
				lappend visible_tools $tool
			}
		}

		return $visible_tools
	}

	return $tools
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
	global active_tool_group active_tools tool_groups runnable_node_types
	global newnode newlink newoval newrect newtext newfree
	global resizemode

	if { "$newnode$newlink$newoval$newrect$newtext$newfree" != "" || $resizemode != "false" } {
		return
	}

	set tools [dict get $tool_groups $group]
	if { [llength $tools] == 0 } {
		return
	}

	set visible_tools [visibleTools $group $tools]
	set index [dict get $active_tools $group]
	set tool [lindex $tools $index]
	if { $active_tool_group == $group || $tool ni $visible_tools } {
		set tool_count [llength $tools]

		set start_index $index
		set index [expr ($index + 1) % $tool_count]
		while { [lindex $tools $index] ni $visible_tools } {
			set index [expr ($index + 1) % $tool_count]
			if { $index == $start_index } {
				break
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

proc checkAndPromptSave { { cfg_to_check "" } } {
	global curcfg cfg_list

	if { $cfg_to_check != "" } {
		set cfgs $cfg_to_check
	} else {
		set cfgs $cfg_list
	}

	foreach cfg $cfgs {
		set curcfg $cfg
		set fname [getFromRunning "current_file" $cfg]
		if { $fname == "" } {
			set fname "untitled[string range $cfg 3 end]"
		}

		switchProject

		if { [getFromRunning "modified"] != true } {
			continue
		}

		after idle { .dialog1.msg configure -wraplength 4i }
		set answer [tk_dialog .dialog1 "Save changes?" \
			"Topology '$fname' not saved. Save?" \
			questhead 0 Yes No "Cancel"]

		switch -- $answer {
			0 {
				try {
					fileSaveDialogBox
				} on error msg {
					after idle { .dialog1.msg configure -wraplength 4i }
					tk_dialog .dialog1 "IMUNES error" \
						"Got error while saving:\n'$msg'" \
						info 0 Dismiss

					return -1
				}
			}

			1 {}

			2 {
				return 1
			}
		}
	}

	if { $cfg_to_check == "" } {
		exit
	}

	return 0
}

proc refreshHiddenNodes { content_frame } {
	global all_modules_list custom_override

	if { "hidden_node_types" in $custom_override } {
		return
	}

	set hidden_node_types {}
	foreach node_type $all_modules_list {
		set toolbar_location [invokeTypeProc $node_type "gui::toolbarLocation"]
		if {
			($toolbar_location == "link_layer" &&
			"selected" in [$content_frame.link_frame.cb$node_type state]) ||
			($toolbar_location == "net_layer" &&
			"selected" in [$content_frame.network_frame.cb$node_type state])
		} {
			lappend hidden_node_types $node_type
		}
	}

	if { $hidden_node_types == {} } {
		set hidden_node_types "none"
	}

	setGlobalOption "hidden_node_types" $hidden_node_types
	refreshToolBarNodes
}

proc _invokeNodeProc { node_cfg proc_name args } {
	return [invokeTypeProc [_getNodeType $node_cfg] $proc_name {*}$args]
}

#****f* editor.tcl/checkDoubleRange
# NAME
#   checkDoubleRange -- check float range
# SYNOPSIS
#   set check [checkDoubleRange $str $low $high]
# FUNCTION
#   This procedure checks the input string to see if it is
#   an float between the low and high value.
# INPUTS
#   str -- string to check
#   low -- the bottom value
#   high -- the top value
# RESULT
#   * check -- set to 1 if the str is string between low and high
#   value, 0 otherwise.
#****
proc checkDoubleRange { str low high } {
	if { $str == "" } {
		return 1
	}

	set str [string trimleft $str 0]
	if { $str == "" } {
		set str 0
	}

	if { ! [string is double $str] } {
		return 0
	}

	if { $str < $low || $str > $high } {
		return 0
	}

	return 1
}

proc editorPreferences_gui {} {
	global all_options all_gui_options default_options
	global current_tab_elem
	global custom_options custom_override

	global tmp_custom_options tmp_topology_options

	set tmp_custom_options [dictUnset $custom_options "custom_override"]
	set custom_override [dictGet $custom_options "custom_override"]

	set tmp_topology_options [dict create]
	foreach {option_name default_value} $default_options {
		if { $option_name in $all_options } {
			set gui_suffix ""
		} elseif { $option_name in $all_gui_options } {
			set gui_suffix "_gui"
		} else {
			continue
		}

		set tmp [getOption$gui_suffix $option_name]
		if { $tmp != "" } {
			dict set tmp_topology_options $option_name $tmp
		}
	}

	set wi .editor_preferences

	catch { destroy $wi }
	tk::toplevel $wi

	try {
		grab $wi
	} on error {} {
		catch { destroy $wi }
		return
	}

	wm title $wi "Editor Preferences"
	wm minsize $wi 1034 645
	wm resizable $wi 0 0

	set notebook $wi.notebook
	ttk::notebook $notebook

	bind $notebook <<NotebookTabChanged>> "editorPreferencesGUI_changeTab %W \[%W select]"

	# Active options tab
	set active_tab_elem $notebook.active_tab_elem
	ttk::frame $active_tab_elem
	$notebook add $active_tab_elem -text "Active options"
	set current_tab_elem $active_tab_elem

	# redraw header and existing elements
	editorPreferencesGUI_refreshGUI $active_tab_elem "active" $custom_override

	# Custom options tab
	set custom_tab_elem $notebook.custom_tab_elem
	ttk::frame $custom_tab_elem
	$notebook add $custom_tab_elem -text "Custom options"

	# redraw header and existing elements
	editorPreferencesGUI_refreshGUI $custom_tab_elem "custom" $custom_override

	# Topology options tab
	set topology_tab_elem $notebook.topology_tab_elem
	ttk::frame $topology_tab_elem
	$notebook add $topology_tab_elem -text "Topology options"

	# redraw header and existing elements
	editorPreferencesGUI_refreshGUI $topology_tab_elem "topology" $custom_override

	# Custom preferences information
	set info_label_frame $wi.info_label_frame
	ttk::frame $info_label_frame -relief groove -borderwidth 2

	set info_label $info_label_frame.info_label
	ttk::label $info_label \
		-text "Preview of currently active options combining Custom, Topology and Default options - prioritized in that order" \
		-foreground "red"
	getHelpLabel $info_label "Editor Preferences"

	# Buttons
	set bottom $wi.bottom
	ttk::frame $bottom
	set buttons $bottom.buttons
	ttk::frame $buttons -borderwidth 2

	#ttk::button $buttons.fetch -text "Fetch from active" -command \
	#	"
	#global current_tab_elem

	#lassign \[editorPreferencesGUI_fetchTabOptions \$current_tab_elem \"fetch_from_active\"] curtab_options curtab_override

	#editorPreferencesGUI_refreshGUI \$current_tab_elem \$curtab_options \$curtab_override \"fetched\"
	#"

	set tmp_command [list apply {
		{ wi } {
			global current_tab_elem

			set current_option_source [lindex [split [winfo name $current_tab_elem] "_"] 0]
			lassign [editorPreferencesGUI_contentChanged $current_tab_elem] - curtab_options curtab_override

			editorPreferencesGUI_saveContent $current_option_source $curtab_options $curtab_override

			if { $wi != "" } {
				destroy $wi
			}
		}
	} \
		""
	]
	ttk::button $buttons.apply -text "Apply" \
		-command $tmp_command
	ttk::button $buttons.applyClose -text "Apply and Close" \
		-command [lreplace $tmp_command end end $wi]

	ttk::button $buttons.cancel \
		-text "Cancel" \
		-command "destroy $wi"

	#grid $buttons.fetch -row 0 -column 1 -sticky swe -padx 2 -columnspan 3
	grid $buttons.apply -row 1 -column 1 -sticky swe -padx 2
	grid $buttons.applyClose -row 1 -column 2 -sticky swe -padx 2
	grid $buttons.cancel -row 1 -column 3 -sticky swe -padx 2

	pack $notebook -fill both -expand 1
	pack $info_label_frame -fill both
	pack $info_label -pady 2
	pack $bottom -fill both -side bottom
	pack $buttons -pady 2
}

proc editorPreferencesGUI_contentChanged { tab_elem } {
	global custom_options global_override

	set current_option_source [lindex [split [winfo name $tab_elem] "_"] 0]

	lassign [editorPreferencesGUI_fetchTabOptions $tab_elem] curtab_options curtab_override
	if { $current_option_source == "active" } {
		return [list 0 $curtab_options $curtab_override]
	}

	global tmp_${current_option_source}_options

	dict for {key value} [dictDiff [set tmp_${current_option_source}_options] $curtab_options] {
		if { $value == "copy" } {
			continue
		}

		if { $key in $global_override } {
			continue
		}

		return [list 1 $curtab_options $curtab_override]
	}

	if { $current_option_source == "custom" } {
		if { [lsort [dictGet $custom_options "custom_override"]] != [lsort $curtab_override] } {
			return [list 1 $curtab_options $curtab_override]
		}
	}

	return [list 0 $curtab_options $curtab_override]
}

proc editorPreferencesGUI_changeTab { notebook to_tab_elem } {
	global current_tab_elem

	lassign [editorPreferencesGUI_contentChanged $current_tab_elem] diff curtab_options curtab_override
	set to_option_source [lindex [split [winfo name $to_tab_elem] "_"] 0]

	if { $diff } {
		set answer [tk_messageBox -message \
			"Changes pending, do you want to apply them?" \
			-icon warning -type yesno ]

		switch -- $answer {
			yes {
				set current_option_source [lindex [split [winfo name $current_tab_elem] "_"] 0]
				editorPreferencesGUI_saveContent $current_option_source $curtab_options $curtab_override
			}

			no {}
		}
	}

	editorPreferencesGUI_refreshGUI $to_tab_elem $to_option_source $curtab_override

	lassign [split $notebook "."] - widget_elem
	set info_label ".$widget_elem.info_label_frame.info_label"

	switch -exact $to_option_source {
		"active" {
			set info_string "Preview of currently active options combining Custom, Topology and Default options - prioritized in that order"
		}

		"custom" {
			global last_config_file config_override

			set info_string "Options loaded from .rc files - will be saved to '$last_config_file'"
			if { $config_override } {
				append info_string " (some options overriden from '/etc/imunes/override')"
			}
		}

		"topology" {
			set info_string "Options loaded from, and saved to the .imn file - some options cannot be saved"
		}

		default {
			set info_string ""
		}
	}

	catch { $info_label configure -text "$info_string" }

	set current_tab_elem $to_tab_elem
}

proc editorPreferencesGUI_fetchTabOptions { option_tab_elem { fetch_from_active "" } } {
	global options_defaults gui_options_defaults global_override

	set default_options "$options_defaults $gui_options_defaults"

	set content $option_tab_elem.container.scroll_canvas.content
	set option_source [lindex [split [winfo name $option_tab_elem] "_"] 0]

	set current_options_gui [dict create]
	set custom_override_gui {}
	foreach {option_name option_default option_type option_description topology_disable} $default_options {
		if { $option_name == "custom_override" } {
			continue
		}

		set type [lindex $option_type 0]
		switch -exact $type {
			"bool" {
				# configured column
				set ${option_name}_tmp [expr { "selected" in [$content.w${option_name}_option_value state] }]
			}
			"string" -
			"list" -
			"double" -
			"int" -
			default {
				# configured column
				set ${option_name}_tmp [$content.w${option_name}_option_value get]
			}
		}

		if { "selected" in [$content.w${option_name}_custom_override state] } {
			lappend custom_override_gui $option_name
		}

		if { "selected" in [$content.w${option_name}_from_enabled state] } {
			set current_options_gui [dictSet $current_options_gui $option_name [set ${option_name}_tmp]]
		}
	}

	return [list $current_options_gui $custom_override_gui]
}

proc editorPreferencesGUI_refreshGUI { option_tab_elem options custom_override { fetched "" } } {
	global options_defaults gui_options_defaults options_max_length global_override
	global all_options all_gui_options custom_options
	global isOSmac_gui

	set container $option_tab_elem.container
	catch { destroy $container }

	ttk::frame $container
	# inherit size from parent, defined in editorPreferences_gui
	pack $container -fill both -expand 1

	set header $container.header
	ttk::frame $header
	grid $header -row 0 -column 0 -columnspan 2 -sticky ew

	# ttk::frame is not scrollable, so we create a canvas + scrollbar
	set scroll_canvas $container.scroll_canvas
	canvas $scroll_canvas

	set scrollbar_elem $container.vscroll
	ttk::scrollbar $scrollbar_elem -orient vertical -command "$scroll_canvas yview"
	$scroll_canvas configure -yscrollcommand "$scrollbar_elem set"

	set content $scroll_canvas.content
	ttk::frame $content -relief groove -borderwidth 2 -padding 2

	set tmp_command [list apply {
		{ scroll_canvas } {
			# offset top border/padding by 1
			lassign [$scroll_canvas bbox all] a b c d
			$scroll_canvas configure -scrollregion "$a [incr b] $c $d"
		}
	} \
		$scroll_canvas
	]
	bind $content <Configure> $tmp_command

	bind $content <4> "$scroll_canvas yview scroll -1 units"
	bind $content <5> "$scroll_canvas yview scroll 1 units"

	grid $scroll_canvas -row 1 -column 0 -sticky nsew
	grid $scrollbar_elem -row 1 -column 1 -sticky ns

	grid rowconfigure $container 1 -weight 1
	grid columnconfigure $container 0 -weight 1

	# put the frame inside the canvas
	set canvas_window [$scroll_canvas create window 0 0 -anchor nw -window $content]
	bind $scroll_canvas <Configure> "$scroll_canvas itemconfigure $canvas_window -width %w"

	set padx 10
	set header_color "#5b5b9b"

	set option_source [lindex [split [winfo name $option_tab_elem] "_"] 0]
	if { $option_source == "active" } {
		set from_set_text "Configured from"
	} else {
		set from_set_text "Enabled"
	}

	ttk::label $header.h_option_name -text "Option name" \
		-anchor "center" -foreground $header_color -width [expr $options_max_length + 4]
	ttk::label $header.h_option_default -text "Default value" \
		-anchor "center" -foreground $header_color
	ttk::label $header.h_option_value -text "Configured value" \
		-anchor "center" -foreground $header_color
	ttk::label $header.h_option_from_enabled -text "$from_set_text" -width 16 \
		-anchor "center" -foreground $header_color
	ttk::label $header.h_option_custom_override -text "Custom override" \
		-anchor "center" -foreground $header_color

	grid $header.h_option_name -row 0 -column 0 -in $header -sticky "e" -padx $padx
	grid $header.h_option_default -row 0 -column 1 -in $header -sticky "" -padx $padx
	grid $header.h_option_value -row 0 -column 2 -in $header -sticky "" -padx $padx
	grid $header.h_option_from_enabled -row 0 -column 3 -in $header -sticky "" -padx $padx
	grid $header.h_option_custom_override -row 0 -column 4 -in $header -sticky "" -padx $padx

	set full_default_options "$options_defaults $gui_options_defaults"

	# skip header row
	set row 1
	set checkbutton_dict "0 !selected 1 selected"
	foreach {option_name option_default option_type option_description topology_disable} $full_default_options {
		if { $option_name == "custom_override" } {
			continue
		}

		set option_enabled 0
		switch -exact $options {
			"active" {
				set option_value [getActiveOption $option_name]
			}
			"custom" {
				set tmp [dictGet $custom_options $option_name]
				if { $tmp != "" } {
					set option_value $tmp
					set option_enabled 1
				} else {
					set option_value $option_default
				}
			}
			"topology" {
				if { $option_name in $all_options } {
					set gui_suffix ""
				} elseif { $option_name in $all_gui_options } {
					set gui_suffix "_gui"
				} else {
					continue
				}

				set tmp [getOption$gui_suffix $option_name]
				if { $tmp != "" } {
					set option_value $tmp
					set option_enabled 1
				} else {
					set option_value [getActiveOption $option_name]
				}
			}
		}

		# OPTION NAME
		ttk::label $content.w${option_name} -text "$option_name"

		# make the parent change cursor on hover
		bind $content.w${option_name} <Enter> "$content.w${option_name} config -cursor question_arrow"
		bind $content.w${option_name} <Leave> "$content.w${option_name} config -cursor arrow"

		# on button3 click, open a *_help menu with an option description
		# so that the cursor is inside of it
		menu $content.w${option_name}_help -tearoff 0
		$content.w${option_name}_help add command -label "$option_description"
		if { $isOSmac_gui } {
			bind $content.w${option_name} <Button-2> "tk_popup $content.w${option_name}_help \
				\[expr %X - \[winfo width $content.w${option_name}]/2] \
				\[expr %Y - \[winfo height $content.w${option_name}]/2]"

			bind $content.w${option_name} <Control-Button-1> "tk_popup $content.w${option_name}_help \
				\[expr %X - \[winfo width $content.w${option_name}]/2] \
				\[expr %Y - \[winfo height $content.w${option_name}]/2]"
		} else {
			bind $content.w${option_name} <Button-3> "tk_popup $content.w${option_name}_help \
				\[expr %X - \[winfo width $content.w${option_name}]/2] \
				\[expr %Y - \[winfo height $content.w${option_name}]/2]"
		}

		# destroy the *_help menu when leaving it with the cursor
		bind $content.w${option_name}_help <Leave> "catch { unset $content.w${option_name}_help }"

		# DEFAULT VALUE, CONFIGURED VALUE
		set type [lindex $option_type 0]
		switch -exact $type {
			"bool" {
				# default column
				ttk::checkbutton $content.w${option_name}_default -text "" -state disabled
				set value [dict get $checkbutton_dict $option_default]
				$content.w${option_name}_default state $value

				# configured column
				ttk::checkbutton $content.w${option_name}_option_value -text ""
				if { $option_value != "" } {
					set value [dict get $checkbutton_dict $option_value]
					if {
						$option_source == "active" ||
						($topology_disable && $option_source == "topology")
					} {
						set value "disabled $value"
					}
				} else {
					set value [dict get $checkbutton_dict $option_default]
				}

				$content.w${option_name}_option_value state $value
			}
			"string" {
				# default column
				ttk::label $content.w${option_name}_default -text "\"$option_default\""

				# configured column
				ttk::entry $content.w${option_name}_option_value -width 10
				if { $option_value != "" } {
					set value $option_value
				} else {
					set value $option_default
				}

				$content.w${option_name}_option_value insert 0 "$value"
				if {
					$option_source == "active" ||
					($topology_disable && $option_source == "topology")
				} {
					$content.w${option_name}_option_value state disabled
				}
			}
			"list" {
				set list_options [split [lindex $option_type 1] "|"]
				if { $option_value != "" && $option_value ni $list_options } {
					set option_value [lindex $list_options 0]
				}

				# default column
				ttk::label $content.w${option_name}_default -text "$option_default"

				# configured column
				ttk::combobox $content.w${option_name}_option_value -width 8 -state readonly
				$content.w${option_name}_option_value configure -values $list_options
				if { $option_value != "" } {
					$content.w${option_name}_option_value set $option_value
				} else {
					$content.w${option_name}_option_value set $option_default
				}

				if {
					$option_source == "active" ||
					($topology_disable && $option_source == "topology")
				} {
					$content.w${option_name}_option_value state disabled
				}
			}
			"double" -
			"int" {
				lassign [split [lindex $option_type 1] "|"] min max
				if { $option_value != "" } {
					if { $option_value < $min } {
						set option_value $min
					} elseif { $option_value > $max } {
						set option_value $max
					}
				}

				if { $type == "double" } {
					set check_name "checkDoubleRange"
					set increment 0.1
				} else {
					set check_name "checkIntRange"
					set increment 1
				}

				# default column
				ttk::label $content.w${option_name}_default -text "$option_default \[$min-$max\]"

				# configured column
				ttk::spinbox $content.w${option_name}_option_value -width 6 -validate focus \
					-invalidcommand "focusAndFlash %W"
				if { $option_value != "" } {
					$content.w${option_name}_option_value insert 0 $option_value
				} else {
					$content.w${option_name}_option_value insert 0 $option_default
				}
				$content.w${option_name}_option_value configure \
					-validatecommand "$check_name %P $min $max" \
					-from $min -to $max -increment $increment

				if {
					$option_source == "active" ||
					($topology_disable && $option_source == "topology")
				} {
					$content.w${option_name}_option_value state disabled
				}
			}
			default {
				# default column
				ttk::label $content.w${option_name}_default -text "\"$option_default\""

				# configured column
				if { $option_value != "" } {
					ttk::label $content.w${option_name}_option_value -text "\"$option_value\""
				} else {
					ttk::label $content.w${option_name}_option_value -text "\"$option_default\""
				}
			}
		}

		# CONFIGURED FROM / ENABLED
		if { $option_source == "active" } {
			ttk::label $content.w${option_name}_from_enabled

			if { $option_name in $global_override } {
				$content.w${option_name} configure -foreground red
				$content.w${option_name}_from_enabled configure -text "user" -foreground red
			} else {
				$content.w${option_name}_from_enabled configure -text "[getOptSource $option_name]"
				if { $option_name in $global_override } {
					set global_override [removeFromList $global_override $option_name]
				}
			}
		} else {
			ttk::checkbutton $content.w${option_name}_from_enabled -text ""
			if { $option_source == "topology" && $topology_disable } {
				$content.w${option_name}_from_enabled state disabled
			} else {
				$content.w${option_name}_from_enabled state [dict get $checkbutton_dict $option_enabled]
			}
		}

		# CUSTOM OVERRIDE
		ttk::checkbutton $content.w${option_name}_custom_override -text ""
		$content.w${option_name}_custom_override state \
			[dict get $checkbutton_dict [expr {$option_name in [dictGet $custom_options "custom_override"]}]]

		if { $option_source ni "custom" } {
			$content.w${option_name}_custom_override state disabled
		}

		grid $content.w${option_name} -row $row -column 0 -in $content -sticky "w" -padx $padx
		grid $content.w${option_name}_default -row $row -column 1 -in $content -sticky "" -padx $padx
		grid $content.w${option_name}_option_value -row $row -column 2 -in $content -sticky "" -padx $padx
		grid $content.w${option_name}_from_enabled -row $row -column 3 -in $content -sticky "e" -padx $padx
		grid $content.w${option_name}_custom_override -row $row -column 4 -in $content -sticky "e" -padx $padx

		incr row
	}

	for {set col 0} {$col < 5} {incr col} {
		set max_width 0

		# check width in header
		foreach w [grid slaves $header -column $col] {
			set req [winfo reqwidth $w]
			if { $req > $max_width } {
				set max_width $req
			}
		}

		# check width in content
		foreach w [grid slaves $content -column $col] {
			set req [winfo reqwidth $w]
			if { $req > $max_width } {
				set max_width $req
			}
		}

		grid columnconfigure $header  $col -minsize $max_width
		grid columnconfigure $content $col -minsize $max_width
	}

	update
}

proc editorPreferencesGUI_saveContent { option_source curtab_options curtab_override } {
	global config_dir last_config_file

	switch -exact $option_source {
		"active" {
		}
		"custom" {
			global tmp_custom_options current_tab_elem custom_options

			set custom_options $curtab_options

			#lassign [editorPreferencesGUI_fetchTabOptions $current_tab_elem] curtab_options curtab_override
			set curtab_options [dictSet $curtab_options "custom_override" $curtab_override]

			set json_cfg [createJson "object" $curtab_options]
			if { ! [file exists $config_dir] } {
				file mkdir $config_dir
			}

			try {
				set fd [open $last_config_file w+]
				puts $fd $json_cfg
				close $fd
			} on ok {} {
				readConfigFiles
				set tmp_custom_options [dictUnset $custom_options "custom_override"]

				set severity "INFO"
				set msg "Succesfully saved custom config to '$last_config_file'!"
			} on error err {
				set severity "ERROR"
				set msg "Cannot save to '$last_config_file':\n\n$err"
			}

			after idle { .dialog1.msg configure -wraplength 5i }
			tk_dialog .dialog1 "IMUNES $severity" \
				$msg \
				info 0 Dismiss
		}
		"topology" {
			global all_options all_gui_options default_options tmp_topology_options

			foreach {option_name default_value} $default_options {
				if { $option_name in $all_options } {
					set gui_suffix ""
				} elseif { $option_name in $all_gui_options } {
					set gui_suffix "_gui"
				} else {
					continue
				}

				if { $option_name in [dict keys $curtab_options] } {
					setOption$gui_suffix $option_name [dictGet $curtab_options $option_name]
				} else {
					unsetOption$gui_suffix $option_name
				}
			}

			set tmp_topology_options $curtab_options
			setToRunning "modified" true
		}
	}

	applyOptionsToGUI
	updateIconSize
	redrawAll

	refreshToolBarNodes
}
