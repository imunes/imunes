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

#****f* extelem.tcl/extelem.netlayer
# NAME
#   extelem.netlayer -- layer
# SYNOPSIS
#   set layer [extelem.netlayer]
# FUNCTION
#   Returns the layer on which the extelem operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
    return NETWORK
}

#****f* extelem.tcl/extelem.virtlayer
# NAME
#   extelem.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [extelem.virtlayer]
# FUNCTION
#   Returns the layer on which the extelem is instantiated, i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
    return NATIVE
}

#****f* extelem.tcl/extelem.nodeCreate
# NAME
#   extelem.nodeCreate -- instantiate
# SYNOPSIS
#   extelem.nodeCreate $eid $node_id
# FUNCTION
#   Procedure extelem.nodeCreate creates a new netgraph node of the type extelem.
#   The name of the netgraph node is in form of exprimentId_nodeId.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is extelem)
#****
proc $MODULE.nodeCreate { eid node_id } {
    foreach group [getNodeStolenIfaces $node_id] {
	lassign $group ifc extIfc
	captureExtIfcByName $eid $extIfc
    }
}

#****f* extelem.tcl/extelem.nodeDestroy
# NAME
#   extelem.nodeDestroy -- destroy
# SYNOPSIS
#   extelem.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a extelem. Destroys the netgraph node that represents
#   the extelem by sending a shutdown message.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node (type of the node is extelem)
#****
proc $MODULE.nodeDestroy { eid node_id } {
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
