#****f* editor.tcl/showCfg
# NAME
#   showCfg -- show configuration
# SYNOPSIS
#   showCfg $node_id
# FUNCTION
#   This procedure shows popup with configuration selected in
#   Show menu of the node above wich is the mouse pointer
# INPUTS
#   * node_id -- node id
#****
proc showCfg { node_id } {
	global main_canvas_elem

	upvar 0 ::showConfig showCfg
	upvar 0 ::lastObservedNode lastObservedNode

	#Show only if in exec mode
	if { ! [isRunningNode $node_id] } {
		return
	}

	#Dont draw again if cursor did not move
	if { [winfo pointerxy .] == $lastObservedNode } {
		return
	}

	set lastObservedNode [winfo pointerxy .]
	#Dont show popup window if 'None' or 'Route' is selected from
	#the 'Show' menu
	#Also, dont show popup window if there is no node
	if { $showCfg == "None" || $showCfg == "route" || $node_id == "" } {
		$main_canvas_elem delete -withtag showCfgPopup

		return
	}

	#Dont show popup window if the node virtlayer is different from VIRTUALIZED
	if { [invokeNodeProc $node_id "virtlayer"] != "VIRTUALIZED" } {
		return
	}

	#Determine node coordinates
	set coords [getNodeCoords $node_id]
	set x [expr [lindex $coords 0] + 30]
	set y [expr [lindex $coords 1] + 30]

	#Execute command on selected node and save the command output
	set output [execCmdNode $node_id "timeout 0.1 $showCfg"]
	set title "$node_id# $showCfg\n"
	append title $output

	#Call showCfgPopup
	showCfgPopup $node_id $title $x $y
}

#****f* editor.tcl/showCfgPopup
# NAME
#   showCfgPopup -- show configure popup
# SYNOPSIS
#   showCfg $node_id $title $x $y
# FUNCTION
#   This procedure shows popup window
# INPUTS
#   * node_id -- node id
#   * title -- text that is going to be displayed
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc showCfgPopup { node_id title x y } {
	global defaultFontSize main_canvas_elem

	#Therecan be shown only one popup at the time
	$main_canvas_elem delete -withtag showCfgPopup
	#Show command output
	set popup [$main_canvas_elem create text $x $y \
		-text $title -tag "showCfgPopup" \
		-font "Courier $defaultFontSize" -justify left -anchor nw]

	#Create frame for the command output
	lassign [$main_canvas_elem bbox $popup] x1 y1 x2 y2
	set x1 [expr {$x1 - 5}]
	set y1 [expr {$y1 - 5}]
	set x2 [expr {$x2 + 5}]
	set y2 [expr {$y2 + 5}]
	$main_canvas_elem create rectangle $x1 $y1 $x2 $y2 -fill "#CECECE" -tag "showCfgPopup"
	$main_canvas_elem raise $popup

	#If popup goes beyond the canvas borders move it up and/or left
	set width [expr {abs($x2 - $x1)}]
	set height [expr {abs($y2 - $y1)}]
	set maxRight [winfo width $main_canvas_elem]
	set maxDown [winfo height $main_canvas_elem]
	set change 0
	set newX $x
	set newY $y

	lassign [getCanvasSize [getFromRunning_gui "curcanvas"]] sizex sizey
	lassign [getNodeCoords $node_id] nodeX nodeY
	lassign [$main_canvas_elem cget -scrollregion] rx1 ry1 rx2 ry2

	lassign [lmap n [$main_canvas_elem xview] {expr {round($n * ($rx2 - $rx1) + $rx1)}}] vx1 vx2
	lassign [lmap n [$main_canvas_elem yview] {expr {round($n * ($ry2 - $ry1) + $ry1)}}] vy1 vy2

	set vwidth [expr {abs($vx2 - $vx1)}]
	set vheight [expr {abs($vy2 - $vy1)}]

	set shift 40

	if { $nodeX > [expr {$vx1 + $vwidth/2 + 10}] } {
		set newX [expr {$vx1+$shift}]
	} else {
		set newX [expr {$vx2-$width-$shift}]
	}

	if { $nodeY > [expr {$vy1 + $vheight/2 + 10}] } {
		set newY [expr {$vy1+$shift}]
	} else {
		set newY [expr {$vy2-$height-$shift}]
	}

	if {
		$nodeX > [expr {$newX-$shift}] &&
		$nodeX < [expr {$newX+$width+$shift}] &&
		$nodeY > [expr {$newY-$shift}] &&
		$nodeY < [expr {$newY+$height+$shift}]
	} {
		return
	}

	if { $x2 > $vx2 || $y2 > $vy2 } {
		deleteAndShowPopup $title $newX $newY

		return
	}
}

#****f* editor.tcl/deleteAndShowPopup
# NAME
#   deleteAndShowPopup -- delete and show popup
# SYNOPSIS
#   deleteAndShowPopup $title $x $y
# FUNCTION
#   Deletes configuration popup and creates it again.
# INPUTS
#   * title -- text that is going to be displayed
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc deleteAndShowPopup { title x y } {
	global defaultFontSize main_canvas_elem

	$main_canvas_elem delete -withtag showCfgPopup
	#Show command output
	set popup [$main_canvas_elem create text $x $y \
		-text $title -tag "showCfgPopup" \
		-font "Courier $defaultFontSize" -justify left -anchor nw]

	#Create frame for the command output
	set box [$main_canvas_elem bbox $popup]
	set x1 [expr {[lindex $box 0] - 5}]
	set y1 [expr {[lindex $box 1] - 5}]
	set x2 [expr {[lindex $box 2] + 5}]
	set y2 [expr {[lindex $box 3] + 5}]
	$main_canvas_elem create rectangle $x1 $y1 $x2 $y2 -fill "#CECECE" -tag "showCfgPopup"
	$main_canvas_elem raise $popup
}

#****f* editor.tcl/showRoute
# NAME
#   showRoute -- show route
# SYNOPSIS
#   showRoute $node2_id
# FUNCTION
#   This procedure shows/draws route between two selected nodes.
#   First node is being selected by clicking on it and second is
#   selected by cursor enter. Route is drawn in green color.
# INPUTS
#   * node2_id -- second node
#****
proc showRoute { node2_id } {
	global main_canvas_elem

	upvar 0 ::showConfig showCfg
	upvar 0 ::traceRouteTime traceRouteTime

	#Route can only be drawn in exec mode
	if { [getFromRunning "oper_mode"] != "exec" } {
		return
	}

	#Determine selected node
	set selected {}
	foreach obj [$main_canvas_elem find withtag "node && selected"] {
		lappend selected [lindex [$main_canvas_elem gettags $obj] 1]
	}

	#Draw route only if 'Route' option is selected form 'Show' menu
	if { $showCfg == "route" } {
		#Draw route only if one node is selected
		if { [llength $selected] != 1 } {
			if { [llength $selected] != 0 } {
				set line "To show route, only one node can be selected."
				.bottom.textbox config -text "$line" -foreground "black"
			}
		} else {
			set node1_id $selected

			#Draw route only if both nodes work on network layer
			if {
				$node1_id != $node2_id &&
				[invokeNodeProc $node1_id "netlayer"] == "NETWORK" &&
				[invokeNodeProc $node2_id "netlayer"] == "NETWORK"
			} {
				#User notification
				set line "Please wait. Route is being calculated."
				.bottom.textbox config -text "$line" -foreground "black"
				after 5 { set t 1 }
				vwait t

				#Get second nodes list of interfaces
				set ifaces [lsort -dictionary [ifcList $node2_id]]

				#Make your own traceroute
				set iface_id [lindex $ifaces 0]
				set ip [lindex [getIfcIPv4addrs $node2_id $iface_id] 0]
				set slashPlace [string first "/" $ip]
				set ipAddr [string range $ip 0 [expr $slashPlace-1]]
				set node_id "[getFromRunning "eid"].$node1_id"
				set hopIP ""
				set hop 0
				set n1 $node1_id
				set n2 $node1_id
				set timeExcedeed No
				set cntr 0
				set errDet 0
				while { $hopIP != $ipAddr } {
					incr hop
					set cmd [concat "exec jexec " $node_id ping -n -c 1 -m $hop -t 1 -o -s 56 $ipAddr]
					catch { eval $cmd } result

					set adBeg [string first "from" $result]
					incr adBeg 5
					set adEnd [string last ":" $result]
					incr adEnd -1
					set hopIP [string range $result $adBeg $adEnd]
					set n1 $n2
					set n2 [findNode $hopIP]

					if { $n1 == $n2 || $n2 == "" } {
						set errDet 1
						incr hop -1
						incr cntr
						if { $cntr == 3 } break
					} else {
						set cntr 0
						set errDet 0
					}

					if { $errDet == 0 } {
						drawLine $n1 $n2
					}
				}

				#User notification
				set line "Route calculation finished."
				.bottom.textbox config -text "$line" -foreground "black"
			}
		}
	}
}

#****f* editor.tcl/findNode
# NAME
#   findNode -- find node
# SYNOPSIS
#   findNode $ipAddr
# FUNCTION
#   Finds the node with the specified IP address.
# INPUTS
#   * ipAddr -- IP address
#****
proc findNode { ipAddr } {
	global main_canvas_elem

	#Get list of all network layer nodes
	set i 0
	set nodeList {}
	foreach obj [$main_canvas_elem find withtag node] {
		set node_id [lindex [$main_canvas_elem gettags $obj] 1]
		if { [invokeNodeProc $node_id "netlayer"] == "NETWORK" } {
			lappend nodeList $node_id
			incr i
		}
	}

	set nodesNum $i
	#Find node with specified IP address
	for { set j 0 } { $j < $nodesNum } { incr j } {
		set node_id [lindex $nodeList $j]
		set ifaces [lsort -dictionary [ifcList $node_id]]
		foreach iface_id $ifaces {
			set ip [lindex [getIfcIPv4addrs $node_id $iface_id] 0]
			set slashPlace [string first "/" $ip]
			set addr [string range $ip 0 [expr $slashPlace-1]]
			if { $addr == $ipAddr } {
				return $node_id
			}
		}
	}
}

#****f* editor.tcl/drawLine
# NAME
#   drawLine -- draw line
# SYNOPSIS
#   drawLine $node1_id $node2_id
# FUNCTION
#   Draws the line between two nodes.
# INPUTS
#   * node1_id -- first node
#   * node2_id -- second node
#****
proc drawLine { node1_id node2_id } {
	global main_canvas_elem

	lassign [getNodeCoords $node1_id] x1 y1
	lassign [getNodeCoords $node2_id] x2 y2
	$main_canvas_elem create line $x1 $y1 $x2 $y2 -fill green \
		-width 3 -tags "route"

	raiseAll
	after 5 { set t 1 }
	vwait t
}
