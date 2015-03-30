set MODULE cloud

registerModule $MODULE

#****f* cloud.tcl/cloud.icon
# NAME
#   cloud.icon -- icon
# SYNOPSIS
#   cloud.icon $size
# FUNCTION
#   Returns path to node icon, depending on the specified size.
# INPUTS
#   * size -- "normal", "small" or "toolbar"
# RESULT
#   * path -- path to icon
#****
proc $MODULE.icon { size } {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/cloud.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/cloud.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/cloud.gif
      }
    }
}

#****f* cloud.tcl/cloud.toolbarIconDescr
# NAME
#   cloud.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   cloud.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new Cloud"
}

#****f* cloud.tcl/cloud.calcDxDy
# NAME
#   cloud.calcDxDy -- calculate dx and dy
# SYNOPSIS
#   cloud.calcDxDy
# FUNCTION
#   Calculates distances for nodelabels.
# RESULT
#   * label distance as a list {x y}
#****
proc $MODULE.calcDxDy {} {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    set x [expr {1.5 / $zoom}]
    set y [expr {2.6 / $zoom}]
    return [list $x $y]
}

#****f* cloud.tcl/$MODULE.ifcName
# NAME
#   cloud.ifcName -- interface name
# SYNOPSIS
#   cloud.ifcName
# FUNCTION
#   Returns cloud interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {} {
    return ""
}

#****f* cloud.tcl/cloud.layer
# NAME
#   cloud.layer -- layer
# SYNOPSIS
#   cloud.layer
# FUNCTION
#   Returns the layer on which the clout communicates, i.e. returns LINK. 
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.layer {} {
    return LINK
}

#****f* cloud.tcl/cloud.instantiate
# NAME
#   cloud.instantiate -- instantiate
# SYNOPSIS
#   cloud.instantiate $eid $node
# FUNCTION
#   Not implemented.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is cloud)
#****
proc $MODULE.instantiate { eid node } {
}

#****f* cloud.tcl/cloud.start
# NAME
#   cloud.start -- start
# SYNOPSIS
#   cloud.start $eid $node
# FUNCTION
#   Not implemented.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.start { eid node } {
}

#****f* cloud.tcl/cloud.shutdown
# NAME
#   cloud.shutdown -- shutdown
# SYNOPSIS
#   cloud.shutdown $eid $node
# FUNCTION
#   Not implemented.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.shutdown { eid node } {
}

#****f* cloud.tcl/cloud.destroy
# NAME
#   cloud.destroy -- destroy
# SYNOPSIS
#   cloud.destroy $eid $node
# FUNCTION
#   Not implemented.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#****
proc $MODULE.destroy { eid node } {
}

#****f* cloud.tcl/cloud.configGUI
# NAME
#   cloud.configGUI -- configuration GUI
# SYNOPSIS
#   cloud.configGUI $c $node
# FUNCTION
#   Defines the structure of the cloud configuration window by calling
#   procedures for creating and organising the window, as w2ell as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
proc $MODULE.configGUI { c node } {
    global wi
    global guielements treecolumns
    set guielements {}
    set treecolumns {}

    configGUI_createConfigPopupWin $c
    wm title $wi "cloud configuration"

    configGUI_nodeName $wi $node "Node name:"
    configGUI_cloudConfig $wi $node
    configGUI_buttonsACNode $wi $node
}
