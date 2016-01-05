#
# Copyright 2005-2013 University of Zagreb.
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

# $Id: ext.tcl 63 2013-10-03 12:17:50Z valter $


#****h* imunes/ext.tcl
# NAME
#  ext.tcl -- defines pc specific procedures
# FUNCTION
#  This module is used to define all the pc specific procedures.
# NOTES
#  Procedures in this module start with the keyword pc and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE ext

registerModule $MODULE

#****f* ext.tcl/ext.confNewIfc
# NAME
#   ext.confNewIfc -- configure new interface
# SYNOPSIS
#   ext.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    global changeAddressRange changeAddressRange6 mac_byte4 mac_byte5
    set changeAddressRange 0
    set changeAddressRange6 0
    autoIPv4addr $node $ifc
    autoIPv6addr $node $ifc
    randomizeMACbytes
    autoMACaddr $node $ifc
    autoIPv4defaultroute $node $ifc
    autoIPv6defaultroute $node $ifc
}

#****f* ext.tcl/ext.confNewNode
# NAME
#   ext.confNewNode -- configure new node
# SYNOPSIS
#   ext.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node

    set nconfig [list \
	"hostname [getNewNodeNameType ext ext]" \
	! ]
    lappend $node "network-config [list $nconfig]"
    
    #setLogIfcType $node lo0 lo 
    #setIfcIPv4addr $node lo0 "127.0.0.1/24"
    #setIfcIPv6addr $node lo0 "::1/128"
}

#****f* ext.tcl/ext.icon
# NAME
#   ext.icon -- icon
# SYNOPSIS
#   ext.icon $size
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
	return $ROOTDIR/$LIBDIR/icons/normal/ext.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/ext.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/ext.gif
      }
    }
}

#****f* ext.tcl/ext.toolbarIconDescr
# NAME
#   ext.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   ext.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new External interface"
}

#****f* ext.tcl/ext.notebookDimensions
# NAME
#   ext.notebookDimensions -- notebook dimensions
# SYNOPSIS
#   ext.notebookDimensions $wi
# FUNCTION
#   Returns the specified notebook height and width.
# INPUTS
#   * wi -- widget
# RESULT
#   * size -- notebook size as {height width}
#****
proc $MODULE.notebookDimensions { wi } {
    set h 210
    set w 507
    
    #if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	#== "Configuration" } {
	#set w 507
    #}
    if { [string trimleft [$wi.nbook select] "$wi.nbook.nf"] \
	== "Interfaces" } {
	set h 370
	set w 507
    }

    return [list $h $w] 
}

#****f* ext.tcl/ext.calcDxDy
# NAME
#   ext.calcDxDy -- calculate dx and dy
# SYNOPSIS
#   ext.calcDxDy
# FUNCTION
#   Calculates distances for nodelabels.
# RESULT
#   * label distance as a list {x y}
#****
proc $MODULE.calcDxDy {} {
    upvar 0 ::cf::[set ::curcfg]::zoom zoom
    global showIfIPaddrs showIfIPv6addrs
    if { $showIfIPaddrs || $showIfIPv6addrs } {
	set x [expr {1.1 / $zoom}]
    } else {
	set x [expr {1.4 / $zoom}]
    }
    set y [expr {1.5 / $zoom}]
    return [list $x $y]
}

#****f* ext.tcl/ext.ifcName
# NAME
#   ext.ifcName -- interface name
# SYNOPSIS
#   ext.ifcName
# FUNCTION
#   Returns pc interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return [l3IfcName $l $r]
}

#****f* ext.tcl/ext.IPAddrRange
# NAME
#   ext.IPAddrRange -- IP address range
# SYNOPSIS
#   ext.IPAddrRange
# FUNCTION
#   Returns pc IP address range
# RESULT
#   * range -- pc IP address range
#****
proc $MODULE.IPAddrRange {} {
    return 20
}

#****f* ext.tcl/ext.layer
# NAME
#   ext.layer -- layer
# SYNOPSIS
#   set layer [ext.layer]
# FUNCTION
#   Returns the layer on which the pc communicates, i.e. returns NETWORK. 
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* ext.tcl/ext.virtlayer
# NAME
#   ext.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [ext.virtlayer]
# FUNCTION
#   Returns the layer on which the pc is instantiated i.e. returns VIMAGE. 
# RESULT
#   * layer -- set to VIMAGE
#****
proc $MODULE.virtlayer {} {
    return VIMAGE
}

#****f* ext.tcl/ext.shellcmds
# NAME
#   ext.shellcmds -- shell commands
# SYNOPSIS
#   set shells [ext.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the pc node
#****
proc $MODULE.shellcmds {} {
    return
}

#****f* ext.tcl/ext.instantiate
# NAME
#   ext.instantiate -- instantiate
# SYNOPSIS
#   ext.instantiate $eid $node
# FUNCTION
#   Procedure instantiate creates a new virtaul node
#   for a given node in imunes.
#   Procedure ext.instantiate cretaes a new virtual node with
#   all the interfaces and CPU parameters as defined in imunes. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.instantiate { eid node } {
    createNodePhysIfcs $node
}

#****f* ext.tcl/ext.start
# NAME
#   ext.start -- start
# SYNOPSIS
#   ext.start $eid $node
# FUNCTION
#   Starts a new ext. The node can be started if it is instantiated.
#   Simulates the booting proces of a pc, by calling l3node.start procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.start { eid node } {
    startExternalIfc $eid $node
}

#****f* ext.tcl/ext.shutdown
# NAME
#   ext.shutdown -- shutdown
# SYNOPSIS
#   ext.shutdown $eid $node
# FUNCTION
#   Shutdowns a ext. Simulates the shutdown proces of a pc, 
#   by calling the l3node.shutdown procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.shutdown { eid node } {
    l3node.shutdown $eid $node
}

#****f* ext.tcl/ext.destroy
# NAME
#   ext.destroy -- destroy
# SYNOPSIS
#   ext.destroy $eid $node
# FUNCTION
#   Destroys a ext. Destroys all the interfaces of the pc 
#   and the vimage itself by calling l3node.destroy procedure. 
# INPUTS
#   * eid -- experiment id
#   * node -- node id (type of the node is pc)
#****
proc $MODULE.destroy { eid node } {
    l3node.destroy $eid $node
}

#****f* ext.tcl/ext.nghook
# NAME
#   ext.nghook -- nghook
# SYNOPSIS
#   ext.nghook $eid $node $ifc 
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the 
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    return [l3node.nghook $eid $node $ifc]
}

#****f* ext.tcl/ext.configGUI
# NAME
#   ext.configGUI -- configuration GUI
# SYNOPSIS
#   ext.configGUI $c $node
# FUNCTION
#   Defines the structure of the pc configuration window by calling
#   procedures for creating and organising the window, as well as
#   procedures for adding certain modules to that window.
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
    wm title $wi "ext configuration"
    configGUI_nodeName $wi $node "Node name:"

    configGUI_externalIfcs $wi $node

    configGUI_buttonsACNode $wi $node
}

#****f* ext.tcl/ext.maxLinks
# NAME
#   ext.maxLinks -- maximum number of links
# SYNOPSIS
#   ext.maxLinks
# FUNCTION
#   Returns ext node maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 1
}
