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

# $Id: hub.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/hub.tcl
# NAME
#  hub.tcl -- defines hub specific procedures
# FUNCTION
#  This module is used to define all the hub specific procedures.
# NOTES
#  Procedures in this module start with the keyword hub and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE hub

registerModule $MODULE

#****f* hub.tcl/hub.prepareSystem
# NAME
#   hub.prepareSystem -- prepare system
# SYNOPSIS
#   hub.prepareSystem
# FUNCTION
#   Loads ng_hub into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_hub }
}

#****f* hub.tcl/hub.confNewIfc
# NAME
#   hub.confNewIfc -- configure new interface
# SYNOPSIS
#   hub.confNewIfc $node_id $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node_id ifc } {
}

#****f* hub.tcl/hub.confNewNode
# NAME
#   hub.confNewNode -- configure new node
# SYNOPSIS
#   hub.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node } {
    upvar 0 ::cf::[set ::curcfg]::$node $node
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType hub $nodeNamingBase(hub)]" \
	! ]
    lappend $node "network-config [list $nconfig]"
}

#****f* hub.tcl/hub.icon
# NAME
#   hub.icon -- icon
# SYNOPSIS
#   hub.icon $size
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
	    return $ROOTDIR/$LIBDIR/icons/normal/hub.gif
	}
	small {
	    return $ROOTDIR/$LIBDIR/icons/small/hub.gif
	}
	toolbar {
	    return $ROOTDIR/$LIBDIR/icons/tiny/hub.gif
	}
    }
}

#****f* hub.tcl/hub.toolbarIconDescr
# NAME
#   hub.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   hub.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new Hub"
}

#****f* hub.tcl/hub.ifacePrefix
# NAME
#   hub.ifacePrefix -- interface name
# SYNOPSIS
#   hub.ifacePrefix
# FUNCTION
#   Returns hub interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix { l r } {
    return e
}

#****f* hub.tcl/hub.netlayer
# NAME
#   hub.netlayer -- layer
# SYNOPSIS
#   set layer [hub.netlayer]
# FUNCTION
#   Returns the layer on which the hub operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return LINK
}

#****f* hub.tcl/hub.virtlayer
# NAME
#   hub.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [hub.virtlayer]
# FUNCTION
#   Returns the layer on which the hub is instantiated, i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

#****f* hub.tcl/hub.nodeCreate
# NAME
#   hub.nodeCreate -- instantiate
# SYNOPSIS
#   hub.nodeCreate $eid $node_id
# FUNCTION
#   Procedure hub.nodeCreate creates a new netgraph node of the type hub.
#   The name of the netgraph node is in form of exprimentId_nodeId.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is hub)
#****
proc $MODULE.nodeCreate { eid node_id } {
    l2node.nodeCreate $eid $node_id
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
    l2node.nodeNamespaceSetup $eid $node_id
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifcs } {
    l2node.nodePhysIfacesCreate $eid $node_id $ifcs
}

proc $MODULE.destroyIfcs { eid node_id ifcs } {
    l2node.destroyIfcs $eid $node_id $ifcs
}

#****f* hub.tcl/hub.destroy
# NAME
#   hub.destroy -- destroy
# SYNOPSIS
#   hub.destroy $eid $node_id
# FUNCTION
#   Destroys a hub. Destroys the netgraph node that represents
#   the hub by sending a shutdown message.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is hub)
#****
proc $MODULE.destroy { eid node_id } {
    l2node.destroy $eid $node_id
}

#****f* hub.tcl/hub.nghook
# NAME
#   hub.nghook
# SYNOPSIS
#   hub.nghook $eid $node_id $ifc
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. Netgraph node name is in
#   format experimentId_nodeId and the netgraph hook is in the form of linkN,
#   where N is interface number.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifc -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id ifc } {
    set ifunit [string range $ifc 1 end]
    return [list $node_id link$ifunit]
}


#****f* hub.tcl/hub.configGUI
# NAME
#   hub.configGUI -- configuration GUI
# SYNOPSIS
#   hub.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the hub configuration window by calling
#   procedures for creating and organising the window, as well as procedures
#   for adding certain modules to that window.
# INPUTS
#   * c -- tk canvas
#   * node_id -- node id
#****
proc $MODULE.configGUI { c node_id } {
    global wi
    global guielements treecolumns
    set guielements {}

    configGUI_createConfigPopupWin $c
    wm title $wi "hub configuration"
    configGUI_nodeName $wi $node_id "Node name:"

    configGUI_addPanedWin $wi
    set treecolumns { "QLen Queue len" "QDisc Queue disc" "QDrop Queue drop" }
    configGUI_addTree $wi $node_id

    configGUI_buttonsACNode $wi $node_id
}

#****f* hub.tcl/hub.configInterfacesGUI
# NAME
#   hub.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   hub.configInterfacesGUI $wi $node_id $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the hub configuration window. It is done by calling procedures for adding
#   certain modules to the window.
# INPUTS
#   * wi -- widget
#   * node_id -- node id
#   * ifc -- interface id
#****
proc $MODULE.configInterfacesGUI { wi node_id ifc } {
    global guielements

    configGUI_ifcQueueConfig $wi $node_id $ifc
}
