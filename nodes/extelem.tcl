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

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

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
    upvar 0 ::cf::[set ::curcfg]::$node_id $node_id
    global nodeNamingBase

    set nconfig [list \
	"hostname [getNewNodeNameType extelem $nodeNamingBase(extelem)]" \
	! ]
    lappend $node_id "network-config [list $nconfig]"
}

#****f* extelem.tcl/extelem.confNewIfc
# NAME
#   extelem.confNewIfc -- configure new interface
# SYNOPSIS
#   extelem.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
    set old [getNodeStolenIfaces $node_id]
    lappend old [list $iface_id "UNASSIGNED"]
    setNodeStolenIfaces $node_id $old
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
}

proc $MODULE.generateConfig { node_id } {
}

proc $MODULE.generateUnconfig { node_id } {
}

#****f* extelem.tcl/extelem.ifacePrefix
# NAME
#   extelem.ifacePrefix -- interface name
# SYNOPSIS
#   extelem.ifacePrefix
# FUNCTION
#   Returns extelem interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
    return "x"
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

#****f* extelem.tcl/extelem.nghook
# NAME
#   extelem.nghook
# SYNOPSIS
#   extelem.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. Netgraph node name is in
#   format experimentId_nodeId and the netgraph hook is in the form of linkN,
#   where N is interface number.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
    lassign [lindex [lsearch -index 0 -all -inline -exact [getNodeStolenIfaces $node_id] $iface_id] 0] iface_id extIfc

    return [list $extIfc lower]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* extelem.tcl/extelem.prepareSystem
# NAME
#   extelem.prepareSystem -- prepare system
# SYNOPSIS
#   extelem.prepareSystem
# FUNCTION
#   Loads ng_extelem into the kernel.
#****
proc $MODULE.prepareSystem {} {
    catch { exec kldload ng_ether }
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
#   * node_id -- id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
}

#****f* extelem.tcl/extelem.nodeNamespaceSetup
# NAME
#   extelem.nodeNamespaceSetup -- extelem node nodeNamespaceSetup
# SYNOPSIS
#   extelem.nodeNamespaceSetup $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node_id } {
}

#****f* extelem.tcl/extelem.nodeInitConfigure
# NAME
#   extelem.nodeInitConfigure -- extelem node nodeInitConfigure
# SYNOPSIS
#   extelem.nodeInitConfigure $eid $node_id
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeInitConfigure { eid node_id } {
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
    foreach iface_id [allIfcList $node_id] {
	set link_id [getIfcLink $node_id $iface_id]
	if { $link_id != "" && [getLinkDirect $link_id] } {
	    # do direct link stuff
	    captureExtIfc $eid $node_id $iface_id
	} else {
	    captureExtIfc $eid $node_id $iface_id
	}
    }
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

#****f* extelem.tcl/extelem.nodeIfacesConfigure
# NAME
#   extelem.nodeIfacesConfigure -- configure extelem node interfaces
# SYNOPSIS
#   extelem.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a extelem. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
}

#****f* extelem.tcl/extelem.nodeConfigure
# NAME
#   extelem.nodeConfigure -- configure extelem node
# SYNOPSIS
#   extelem.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new extelem. Simulates the booting proces of a node, starts all the
#   services, etc.
#   This procedure can be called if it is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeConfigure { eid node_id } {
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* extelem.tcl/extelem.nodeIfacesUnconfigure
# NAME
#   extelem.nodeIfacesUnconfigure -- unconfigure extelem node interfaces
# SYNOPSIS
#   extelem.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a extelem to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
    foreach iface_id [allIfcList $node_id] {
	set link_id [getIfcLink $node_id $iface_id]
	if { $link_id != "" && [getLinkDirect $link_id] } {
	    # do direct link stuff
	    releaseExtIfc $eid $node_id $iface_id
	} else {
	    releaseExtIfc $eid $node_id $iface_id
	}
    }
}

proc $MODULE.nodeUnconfigure { eid node_id } {
}

#****f* extelem.tcl/extelem.nodeShutdown
# NAME
#   extelem.nodeShutdown -- layer 3 node nodeShutdown
# SYNOPSIS
#   extelem.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a extelem node.
#   Simulates the shutdown proces of a node, kills all the services and
#   processes.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
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
#   * node_id -- id of the node
#****
proc $MODULE.nodeDestroy { eid node_id } {
}
