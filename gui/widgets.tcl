#****f* editor.tcl/showCfg
# NAME
#   showCfg -- show configuration
# SYNOPSIS
#   showCfg $c $node
# FUNCTION
#   This procedure shows popup with configuration selected in
#   Show menu of the node above wich is the mouse pointer
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc showCfg { c node } {
    upvar 0 ::showConfig showCfg
    upvar 0 ::lastObservedNode lastObservedNode

    #Show only if in exec mode
    if { [getFromRunning "oper_mode"] != "exec" } {
    	return
    }
    #Dont draw again if cursor did not move
    if {[winfo pointerxy .] == $lastObservedNode} {
	    return
    }
    set lastObservedNode [winfo pointerxy .]
    #Dont show popup window if 'None' or 'Route' is selected from
    #the 'Show' menu
    #Also, dont show popup window if there is no node
    if { $showCfg == "None" || $showCfg == "route" || $node == "" } {
    	$c delete -withtag showCfgPopup
	return
    }
    #Dont show popup window if the node virtlayer is different from VIRTUALIZED
    if {[[getNodeType $node].virtlayer] != "VIRTUALIZED"} {
    	return
    }
    #Determine node coordinates
    set coords [getNodeCoords $node]
    set x [expr [lindex $coords 0] + 30]
    set y [expr [lindex $coords 1] + 30]
    #Execute command on selected node and save the command output
    set output [execCmdNode $node $showCfg]
    set title "$node# $showCfg\n"
    append title $output
    #Call showCfgPopup
    showCfgPopup $c $node $title $x $y
}

#****f* editor.tcl/showCfgPopup
# NAME
#   showCfgPopup -- show configure popup
# SYNOPSIS
#   showCfg $c $node $title $x $y
# FUNCTION
#   This procedure shows popup window
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#   * title -- text that is going to be displayed
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc showCfgPopup { c node title x y } {
    global defaultFontSize

    #Therecan be shown only one popup at the time
    $c delete -withtag showCfgPopup
    #Show command output
    set popup [$c create text $x $y \
    			-text $title -tag "showCfgPopup" \
			-font "Courier $defaultFontSize" -justify left -anchor nw]

    #Create frame for the command output
    lassign [$c bbox $popup] x1 y1 x2 y2
    set x1 [expr {$x1 - 5}]
    set y1 [expr {$y1 - 5}]
    set x2 [expr {$x2 + 5}]
    set y2 [expr {$y2 + 5}]
    $c create rectangle $x1 $y1 $x2 $y2 -fill "#CECECE" -tag "showCfgPopup"
    $c raise $popup

    #If popup goes beyond the canvas borders move it up and/or left
    set width [expr {abs($x2 - $x1)}]
    set height [expr {abs($y2 - $y1)}]
    set maxRight [winfo width $c]
    set maxDown [winfo height $c]
    set change 0
    set newX $x
    set newY $y

    lassign [getCanvasSize [getFromRunning "curcanvas"]] sizex sizey
    lassign [getNodeCoords $node] nodeX nodeY
    lassign [$c cget -scrollregion] rx1 ry1 rx2 ry2

    #set vx1 [expr {round ([lindex [$c xview] 0]*($rx2-$rx1)+$rx1)}]
    #set vx2 [expr {round ([lindex [$c xview] 1]*($rx2-$rx1)+$rx1)}]
    lassign [lmap n [$c xview] {expr {round($n * ($rx2 - $rx1) + $rx1)}}] vx1 vx2

    #set vy1 [expr {round ([lindex [$c yview] 0]*($ry2-$ry1)+$ry1)}]
    #set vy2 [expr {round ([lindex [$c yview] 1]*($ry2-$ry1)+$ry1)}]
    lassign [lmap n [$c yview] {expr {round($n * ($ry2 - $ry1) + $ry1)}}] vy1 vy2

    set vwidth [expr {abs($vx2 - $vx1)}]
    set vheight [expr {abs($vy2 - $vy1)}]

    set shift 40

    if {$nodeX > [expr {$vx1 + $vwidth/2 + 10}]} {
	set newX [expr {$vx1+$shift}]
    } else {
	set newX [expr {$vx2-$width-$shift}]
    }

    if {$nodeY > [expr {$vy1 + $vheight/2 + 10}]} {
	set newY [expr {$vy1+$shift}]
    } else {
	set newY [expr {$vy2-$height-$shift}]
    }

    if { $nodeX > [expr {$newX-$shift}] && $nodeX < [expr {$newX+$width+$shift}] && \
	$nodeY > [expr {$newY-$shift}] && $nodeY < [expr {$newY+$height+$shift}] } {

	return
    }

    if { $x2 > $vx2 || $y2 > $vy2 } {
	deleteAndShowPopup $c $title $newX $newY

	return
    }
}

#****f* editor.tcl/deleteAndShowPopup
# NAME
#   deleteAndShowPopup -- delete and show popup
# SYNOPSIS
#   deleteAndShowPopup $c $title $x $y
# FUNCTION
#   Deletes configuration popup and creates it again.
# INPUTS
#   * c -- tk canvas
#   * title -- text that is going to be displayed
#   * x -- x coordinate
#   * y -- y coordinate
#****
proc deleteAndShowPopup { c title x y } {
    global defaultFontSize
    $c delete -withtag showCfgPopup
    #Show command output
    set popup [$c create text $x $y \
    			-text $title -tag "showCfgPopup" \
			-font "Courier $defaultFontSize" -justify left -anchor nw]
    #Create frame for the command output
    set box [$c bbox $popup]
    set x1 [expr {[lindex $box 0] - 5}]
    set y1 [expr {[lindex $box 1] - 5}]
    set x2 [expr {[lindex $box 2] + 5}]
    set y2 [expr {[lindex $box 3] + 5}]
    $c create rectangle $x1 $y1 $x2 $y2 -fill "#CECECE" -tag "showCfgPopup"
    $c raise $popup
}

#****f* editor.tcl/showRoute
# NAME
#   showRoute -- show route
# SYNOPSIS
#   showRoute $c $node2
# FUNCTION
#   This procedure shows/draws route between two selected nodes.
#   First node is being selected by clicking on it and second is
#   selected by cursor enter. Route is drawn in green color.
# INPUTS
#   * c -- tk canvas
#   * node2 -- second node
#****
proc showRoute { c node2 } {
    upvar 0 ::showConfig showCfg
    upvar 0 ::traceRouteTime traceRouteTime
    global activetool

    #Route can only be drawn in exec mode
    if { [getFromRunning "oper_mode"] != "exec"} {
	    return
    }

    #Determine selected node
    set selected {}
    foreach obj [.panwin.f1.c find withtag "node && selected"] {
	lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
    }

    #Draw route only if 'Route' option is selected form 'Show' menu
    if { $showCfg == "route" } {
	#Draw route only if one node is selected
	if { [llength $selected] != 1 } {
	    if { [llength $selected] != 0 } {
		set line "To show route, only one node can be selected."
		.bottom.textbox config -text "$line"
	    }
	} else {
	    set node1 $selected

	    #Draw route only if both nodes work on network layer
	    set type1 [[getNodeType $node1].netlayer]
	    set type2 [[getNodeType $node2].netlayer]
	    if { $node1 != $node2 && $type1 == "NETWORK" && $type2 == "NETWORK" } {
		#User notification
    		set line "Please wait. Route is being calculated."
    		.bottom.textbox config -text "$line"
		after 5 {set t 1}
		vwait t

		#Get second nodes list of interfaces
		set ifcs [lsort -ascii [ifcList $node2]]

		#Make your own traceroute
		set ifc [lindex $ifcs 0]
		set ip [getIfcIPv4addr $node2 $ifc]
		set slashPlace [string first "/" $ip]
		set ipAddr [string range $ip 0 [expr $slashPlace-1]]
		set nodeId "[getFromRunning "eid"].$node1"
		set hopIP ""
		set hop 0
		set n1 $node1
		set n2 $node1
		set timeExcedeed No
		set cntr 0
		set errDet 0
		while { $hopIP != $ipAddr } {
		    incr hop
		    set cmd [concat "exec jexec " $nodeId ping -n -c 1 -m $hop -t 1 -o -s 56 $ipAddr]
		    catch { eval $cmd } result

		    set adBeg [string first "from" $result]
		    incr adBeg 5
		    set adEnd [string last ":" $result]
		    incr adEnd -1
		    set hopIP [string range $result $adBeg $adEnd]
		    set n1 $n2
		    set n2 [findNode $c $hopIP]

		    if { $n1 == $n2 || $n2 == "" } {
			set errDet 1
			incr hop -1
			incr cntr
			if {$cntr == 3} break
	    	    } else {
			set cntr 0
			set errDet 0
		    }

		    if {$errDet == 0} {
			drawLine $c $n1 $n2

	    	    }
		}

	    	#User notification
    		set line "Route calculation finished."
    		.bottom.textbox config -text "$line"
	    }
	}
    }
}

#****f* editor.tcl/findNode
# NAME
#   findNode -- find node
# SYNOPSIS
#   findNode $c $ipAddr
# FUNCTION
#   Finds the node with the specified IP address.
# INPUTS
#   * c -- tk canvas
#   * ipAddr -- IP address
#****
proc findNode { c ipAddr } {
    #Get list of all network layer nodes
    set i 0
    set nodeList {}
    foreach obj [$c find withtag node] {
    	set node [lindex [$c gettags $obj] 1]
	set type [[getNodeType $node].netlayer]
    	if { $type == "NETWORK" } {
	    lappend nodeList $node
	    incr i
    	}
    }
    set nodesNum $i
    #Find node with specified IP address
    for {set j 0} {$j < $nodesNum} {incr j} {
    	set node [lindex $nodeList $j]
    	set ifcs [lsort -ascii [ifcList $node]]
    	foreach ifc $ifcs {
    	set ip [getIfcIPv4addr $node $ifc]
    	set slashPlace [string first "/" $ip]
    	set addr [string range $ip 0 [expr $slashPlace-1]]
    	    if {$addr == $ipAddr} {
		return $node
	    }
    	}
    }

}

#****f* editor.tcl/drawLine
# NAME
#   drawLine -- draw line
# SYNOPSIS
#   drawLine $c $node1 $node2
# FUNCTION
#   Draws the line between two nodes.
# INPUTS
#   * c -- tk canvas.
#   * node1 -- first node
#   * node2 -- second node
#****
proc drawLine { c node1 node2 } {
    global activetool

    lassign [getNodeCoords $node1] x1 y1
    lassign [getNodeCoords $node2] x2 y2
    $c create line $x1 $y1 $x2 $y2 -fill green \
    	-width 3 -tags "route"
    raiseAll $c
    after 5 {set t 1}
    vwait t
}
