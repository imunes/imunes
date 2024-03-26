# 2019-2020 Sorbonne University
# In this version of imunes we added a full integration of emulation of 
# Linux namespaces and CISCO routers, saving of parameters, VLANs, WiFi 
# emulation and other features
# This work was developed by Benadji Hanane and Oulad Said Chawki
# Supervised and maintained by Naceur Malouch - LIP6/SU
#
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
# modification for namespace 
proc showCfg { c node } {
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::showConfig showCfg
    upvar 0 ::cf::[set ::curcfg]::eid eid
    upvar 0 ::lastObservedNode lastObservedNode

    #Show only if in exec mode
    if { $oper_mode != "exec" } {
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
    if {$showCfg == "None" || $showCfg == "route" || $node == "" } {
    	$c delete -withtag showCfgPopup
	return
    }
    #Dont show popup window if the node virtlayer is different from VIMAGE NAMESPACE and DYNAMIPS
    if { [[typemodel $node].virtlayer] != "VIMAGE" && [[typemodel $node].virtlayer] != "NAMESPACE" && [[typemodel $node].virtlayer] != "WIFIAP" && [[typemodel $node].virtlayer] != "WIFISTA"} {
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
    set box [$c bbox $popup]
    set x1 [expr {[lindex $box 0] - 5}]
    set y1 [expr {[lindex $box 1] - 5}]
    set x2 [expr {[lindex $box 2] + 5}]
    set y2 [expr {[lindex $box 3] + 5}]
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
    upvar 0 ::cf::[set ::curcfg]::curcanvas curcanvas
    set sizex [lindex [getCanvasSize $curcanvas] 0]
    set sizey [lindex [getCanvasSize $curcanvas] 1]

    set nodeX [lindex [getNodeCoords $node] 0]
    set nodeY [lindex [getNodeCoords $node] 1]

    set canvasRegion [$c cget -scrollregion]
    set rx1 [lindex $canvasRegion 0]    
    set ry1 [lindex $canvasRegion 1]    
    set rx2 [lindex $canvasRegion 2]    
    set ry2 [lindex $canvasRegion 3]

    set vx1 [expr {round ([lindex [$c xview] 0]*($rx2-$rx1)+$rx1)}]
    set vx2 [expr {round ([lindex [$c xview] 1]*($rx2-$rx1)+$rx1)}]
    set vy1 [expr {round ([lindex [$c yview] 0]*($ry2-$ry1)+$ry1)}]
    set vy2 [expr {round ([lindex [$c yview] 1]*($ry2-$ry1)+$ry1)}]
    
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
    
    if {$nodeX > [expr {$newX-$shift}] && $nodeX < [expr {$newX+$width+$shift}] \
	&& $nodeY > [expr {$newY-$shift}] && $nodeY < \
	[expr {$newY+$height+$shift}] } {
	return
    }

    if {$x2 > $vx2 || $y2 > $vy2} {
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
    global activetool
    upvar 0 ::showConfig showCfg
    upvar 0 ::traceRouteTime traceRouteTime  
    upvar 0 ::cf::[set ::curcfg]::oper_mode oper_mode
    upvar 0 ::cf::[set ::curcfg]::eid eid
    #Route can only be drawn in exec mode
    if {$oper_mode != "exec"} {
	    return
    }
    #Determine selected node
    set selected {}
    foreach obj [.panwin.f1.c find withtag "node && selected"] {
	lappend selected [lindex [.panwin.f1.c gettags $obj] 1]
    }
    #Draw route only if 'Route' option is selected form 'Show' menu
    if { $showCfg == "route"} {
	#Draw route only if one node is selected
    	if {[llength $selected] != 1} {
		if {[llength $selected] != 0} {
	    	    set line "To show route, only one node can be selected."
	    	    .bottom.textbox config -text "$line"
    		}
	} else {
	    set node1 $selected
	    #Draw route only if both nodes work on network layer
	    set type1 [[typemodel $node1].layer]
	    set type2 [[typemodel $node2].layer]
	    if { $node1 != $node2 && $type1 == "NETWORK" && $type2 == "NETWORK"} {
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
		set nodeId "$eid.$node1"
		set hopIP ""
		set hop 0
		set n1 $node1
		set n2 $node1
		set timeExcedeed No
		set cntr 0
		set errDet 0
		while {$hopIP != $ipAddr} {
		    incr hop
		    set cmd [concat "nexec jexec " $nodeId ping -n -c 1 -m $hop -t 1 -o -s 56 $ipAddr]
		    catch {
			eval $cmd 
	    	    } result
		    set adBeg [string first "from" $result]
		    incr adBeg 5
		    set adEnd [string last ":" $result]
		    incr adEnd -1
		    set hopIP [string range $result $adBeg $adEnd]
		    set n1 $n2
		    set n2 [findNode $c $hopIP]
		    if {$n1 == $n2 || $n2 == "" } {
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
    	set type [[typemodel $node].layer]
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
    set xy1 [getNodeCoords $node1]
    set x1 [lindex $xy1 0]
    set y1 [lindex $xy1 1]				
    set xy2 [getNodeCoords $node2]
    set x2 [lindex $xy2 0]
    set y2 [lindex $xy2 1]
    $c create line $x1 $y1 $x2 $y2 -fill green \
    	-width 3 -tags "route"
    raiseAll $c
    after 5 {set t 1}
    vwait t
}
