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
# This work was supported in part by Croatian Ministry of Science
# and Technology through the research contract #IP-2003-143.
#

# $Id: lanswitch.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/lanswitch.tcl
# NAME
#  lanswitch.tcl -- defines lanswitch specific procedures
# FUNCTION
#  This module is used to define all the lanswitch specific procedures.
# NOTES
#  Procedures in this module start with the keyword lanswitch and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE lanswitch

registerModule $MODULE

#****f* lanswitch.tcl/lanswitch.prepareSystem
# NAME
#   lanswitch.prepareSystem -- prepare system
# SYNOPSIS
#   lanswitch.prepareSystem
# FUNCTION
#   Loads ng_bridge into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_bridge }
}

#****f* lanswitch.tcl/lanswitch.confNewIfc
# NAME
#   lanswitch.confNewIfc -- configure new interface
# SYNOPSIS
#   lanswitch.confNewIfc $node $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node ifc } {
    foreach l2node [listLANnodes $node ""] {
	foreach ifc [ifcList $l2node] {
	    set peer [peerByIfc $l2node $ifc]
	    if { ! [isNodeRouter $peer] &&
		[[typemodel $peer].layer] == "NETWORK" } {
		set ifname [ifcByPeer $peer $l2node]
		autoIPv4defaultroute $peer $ifname
		autoIPv6defaultroute $peer $ifname
	    }
	}
    }
}

#****f* lanswitch.tcl/lanswitch.confNewNode
# NAME
#   lanswitch.confNewNode -- configure new node
# SYNOPSIS
#   lanswitch.confNewNode $node
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase
    
    set nconfig [list \
	"hostname [getNewNodeNameType lanswitch $nodeNamingBase(lanswitch)]" \
	! ]
    lappend $node "network-config [list $nconfig]"
}

#****f* lanswitch.tcl/lanswitch.icon
# NAME
#   lanswitch.icon -- 
# SYNOPSIS
#   lanswitch.icon $size
# FUNCTION
#   Returns path to node icon, depending on the specified size.
# INPUTS
#   * size -- "normal", "small" or "toolbar"
# RESULT
#   * path -- path to icon
#****
proc $MODULE.icon {size} {
    global ROOTDIR LIBDIR
    switch $size {
      normal {
	return $ROOTDIR/$LIBDIR/icons/normal/lanswitch.gif
      }
      small {
	return $ROOTDIR/$LIBDIR/icons/small/lanswitch.gif
      }
      toolbar {
	return $ROOTDIR/$LIBDIR/icons/tiny/lanswitch.gif
      }
    }
}

#****f* lanswitch.tcl/lanswitch.toolbarIconDescr
# NAME
#   lanswitch.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   lanswitch.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new LAN switch"
}

#****f* lanswitch.tcl/lanswitch.ifcName
# NAME
#   lanswitch.ifcName -- interface name
# SYNOPSIS
#   lanswitch.ifcName
# FUNCTION
#   Returns lanswitch interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return e
}

#****f* lanswitch.tcl/lanswitch.layer
# NAME
#   lanswitch.layer -- layer
# SYNOPSIS
#   set layer [lanswitch.layer]
# FUNCTION
#   Returns the layer on which the lanswitch operates, i.e. returns LINK. 
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.layer {} {
    return LINK
}

#****f* lanswitch.tcl/lanswitch.virtlayer
# NAME
#   lanswitch.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [lanswitch.virtlayer]
# FUNCTION
#   Returns the layer on which the lanswitch node is instantiated 
#   i.e. returns NETGRAPH. 
# RESULT
#   * layer -- set to NETGRAPH
#****
proc $MODULE.virtlayer {} {
    return NETGRAPH
}

#****f* lanswitch.tcl/lanswitch.instantiate
# NAME
#   lanswitch.instantiate -- instantiate
# SYNOPSIS
#   lanswitch.instantiate $eid $node
# FUNCTION
#   Procedure lanswitch.instantiate creates a new netgraph node of the type
#   bridge. The name of the netgraph node is in the form of exprimentId_nodeId.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node (type of the node is lanswitch)
#****
proc $MODULE.instantiate { eid node } {
    l2node.instantiate $eid $node
}

#****f* lanswitch.tcl/lanswitch.destroy
# NAME
#   lanswitch.destroy -- destroy
# SYNOPSIS
#   lanswitch.destroy $eid $node
# FUNCTION
#   Destroys a lanswitch. Destroys the netgraph node that represents 
#   the lanswitch by sending a shutdown message.
# INPUTS
#   * eid -- experiment id
#   * node -- id of the node (type of the node is lanswitch)
#****
proc $MODULE.destroy { eid node } {
    l2node.destroy $eid $node
}

#****f* lanswitch.tcl/lanswitch.nghook
# NAME
#   lanswitch.nghook -- nghook
# SYNOPSIS
#   set nghook [lanswitch.nghook $eid $node $ifc] 
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. Netgraph node name is in
#   format experimentId_nodeId and the netgraph hook is in the form of linkN,
#   where N is an interface number.
# INPUTS
#   * eid -- experiment id
#   * node -- node id
#   * ifc -- interface name 
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node ifc } {
    set ifunit [string range $ifc 1 end]
    return [list $eid\.$node link$ifunit]
}

#****f* lanswitch.tcl/lanswitch.configGUI
# NAME
#   lanswitch.configGUI -- configuration GUI
# SYNOPSIS
#   lanswitch.configGUI $c $node
# FUNCTION
#   Defines the structure of the lanswitch configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node -- node id
#****
# modification for VLAN
proc $MODULE.configGUI { c node } {
    global wi

    
    global guielements treecolumns Vlancolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "lanswitch configuration"  
    	set type [nodeType $node]
   if {$type == "lanswitch"} {
    wm minsize $wi 400 450
    wm resizable $wi 1 1  
    set Vlancolumns {"VlanTag" "VlanMode" "InterfaceType" "VlanRange"}
}
    configGUI_nodeName $wi $node "Node name:"

    configGUI_addPanedWin $wi

    set treecolumns {"QLen Queue len" "QDisc Queue disc" "QDrop Queue drop"}

    configGUI_addTree $wi $node

    configGUI_buttonsACNode $wi $node
}

#****f* lanswitch.tcl/lanswitch.configInterfacesGUI
# NAME
#   lanswitch.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   lanswitch.configInterfacesGUI $wi $node $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the lanswitch configuration window. It is done by calling procedures for
#   adding certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node -- node id
#   * ifc -- interface id
#****
proc $MODULE.configInterfacesGUI { wi node ifc } {
    global guielements

    configGUI_ifcQueueConfig $wi $node $ifc
}

#****f* lanswitch.tcl/lanswitch.maxLinks
# NAME
#   lanswitch.maxLinks -- maximum number of links
# SYNOPSIS
#   lanswitch.maxLinks
# FUNCTION
#   Returns lanswitch maximum number of links.
# RESULT
#   * maximum number of links.
#****
proc $MODULE.maxLinks {} {
    return 32
}
