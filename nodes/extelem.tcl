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

# $Id: extelem.tcl 129 2015-02-13 11:14:44Z valter $


#****h* imunes/extelem.tcl
# NAME
#  extelem.tcl -- defines extelem specific procedures
# FUNCTION
#  This module is used to define all the extelem specific procedures.
# NOTES
#  Procedures in this module start with the keyword extelem and
#  end with function specific part that is the same for all the
#  node types that work on the same layer.
#****

set MODULE extelem

registerModule $MODULE

#****f* extelem.tcl/extelem.prepareSystem
# NAME
#   extelem.prepareSystem -- prepare system
# SYNOPSIS
#   extelem.prepareSystem
# FUNCTION
#   Loads ng_extelem into the kernel.
#****
proc $MODULE.prepareSystem {} {
}

#****f* extelem.tcl/extelem.confNewIfc
# NAME
#   extelem.confNewIfc -- configure new interface
# SYNOPSIS
#   extelem.confNewIfc $node_id $ifc
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * ifc -- interface name
#****
proc $MODULE.confNewIfc { node_id ifc } {
    setIfcType $node_id $ifc "stolen"
    setIfcStolenIfc $node_id $ifc "UNASSIGNED"
}

#****f* extelem.tcl/extelem.confNewNode
# NAME
#   extelem.confNewNode -- configure new node
# SYNOPSIS
#   extelem.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
    global nodeNamingBase

    setNodeName $node_id [getNewNodeNameType extelem $nodeNamingBase(extelem)]
}

#****f* extelem.tcl/extelem.icon
# NAME
#   extelem.icon -- icon
# SYNOPSIS
#   extelem.icon $size
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

#****f* extelem.tcl/extelem.toolbarIconDescr
# NAME
#   extelem.toolbarIconDescr -- toolbar icon description
# SYNOPSIS
#   extelem.toolbarIconDescr
# FUNCTION
#   Returns this module's toolbar icon description.
# RESULT
#   * descr -- string describing the toolbar icon
#****
proc $MODULE.toolbarIconDescr {} {
    return "Add new External element"
}

#****f* extelem.tcl/extelem.ifcName
# NAME
#   extelem.ifcName -- interface name
# SYNOPSIS
#   extelem.ifcName
# FUNCTION
#   Returns extelem interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifcName {l r} {
    return x
}

#****f* extelem.tcl/extelem.layer
# NAME
#   extelem.layer -- layer
# SYNOPSIS
#   set layer [extelem.layer]
# FUNCTION
#   Returns the layer on which the extelem operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.layer {} {
    return NETWORK
}

#****f* extelem.tcl/extelem.virtlayer
# NAME
#   extelem.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [extelem.virtlayer]
# FUNCTION
#   Returns the layer on which the extelem is instantiated, i.e. returns NETGRAPH.
# RESULT
#   * layer -- set to NETGRAPH
#****
proc $MODULE.virtlayer {} {
    return NETGRAPH
}

#****f* extelem.tcl/extelem.instantiate
# NAME
#   extelem.instantiate -- instantiate
# SYNOPSIS
#   extelem.instantiate $eid $node_id
# FUNCTION
#   Procedure extelem.instantiate creates a new netgraph node of the type extelem.
#   The name of the netgraph node is in form of exprimentId_nodeId.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is extelem)
#****
proc $MODULE.instantiate { eid node_id } {
    foreach group [getNodeStolenIfaces $node_id] {
	lassign $group ifc extIfc
	captureExtIfcByName $eid $extIfc
    }
}

#****f* extelem.tcl/extelem.destroy
# NAME
#   extelem.destroy -- destroy
# SYNOPSIS
#   extelem.destroy $eid $node_id
# FUNCTION
#   Destroys a extelem. Destroys the netgraph node that represents
#   the extelem by sending a shutdown message.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is extelem)
#****
proc $MODULE.destroy { eid node_id } {
    foreach group [getNodeStolenIfaces $node_id] {
	lassign $group ifc extIfc
	releaseExtIfcByName $eid $extIfc
    }
}

#****f* extelem.tcl/extelem.nghook
# NAME
#   extelem.nghook
# SYNOPSIS
#   extelem.nghook $eid $node_id $ifc
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
    lassign [lindex [lsearch -index 0 -all -inline -exact [getNodeStolenIfaces $node_id] $ifc] 0] ifc extIfc
    return [list $extIfc lower]
}

#****f* extelem.tcl/extelem.configGUI
# NAME
#   extelem.configGUI -- configuration GUI
# SYNOPSIS
#   extelem.configGUI $c $node_id
# FUNCTION
#   Defines the structure of the extelem configuration window by calling
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
    set treecolumns {}

    configGUI_createConfigPopupWin $c
    wm title $wi "External element configuration"
    configGUI_nodeName $wi $node_id "External element name:"

    configGUI_addPanedWin $wi
    configGUI_rj45s $wi $node_id

    configGUI_buttonsACNode $wi $node_id
}

#****f* extelem.tcl/extelem.configInterfacesGUI
# NAME
#   extelem.configInterfacesGUI -- configuration of interfaces GUI
# SYNOPSIS
#   extelem.configInterfacesGUI $wi $node_id $ifc
# FUNCTION
#   Defines which modules for changing interfaces parameters are contained in
#   the extelem configuration window. It is done by calling procedures for adding
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
