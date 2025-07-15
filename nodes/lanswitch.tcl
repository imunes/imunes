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

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* lanswitch.tcl/lanswitch.confNewNode
# NAME
#   lanswitch.confNewNode -- configure new node
# SYNOPSIS
#   lanswitch.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
	global nodeNamingBase

	setNodeName $node_id [getNewNodeNameType lanswitch $nodeNamingBase(lanswitch)]
}

#****f* lanswitch.tcl/lanswitch.confNewIfc
# NAME
#   lanswitch.confNewIfc -- configure new interface
# SYNOPSIS
#   lanswitch.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
}

proc $MODULE.generateConfig { node_id } {
}

proc $MODULE.generateUnconfig { node_id } {
}

#****f* lanswitch.tcl/lanswitch.ifacePrefix
# NAME
#   lanswitch.ifacePrefix -- interface name
# SYNOPSIS
#   lanswitch.ifacePrefix
# FUNCTION
#   Returns lanswitch interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
	return "e"
}

#****f* lanswitch.tcl/lanswitch.IPAddrRange
# NAME
#   lanswitch.IPAddrRange -- IP address range
# SYNOPSIS
#   lanswitch.IPAddrRange
# FUNCTION
#   Returns lanswitch IP address range
# RESULT
#   * range -- lanswitch IP address range
#****
proc $MODULE.IPAddrRange {} {
}

#****f* lanswitch.tcl/lanswitch.netlayer
# NAME
#   lanswitch.netlayer -- layer
# SYNOPSIS
#   set layer [lanswitch.netlayer]
# FUNCTION
#   Returns the layer on which the lanswitch operates, i.e. returns LINK.
# RESULT
#   * layer -- set to LINK
#****
proc $MODULE.netlayer {} {
	return LINK
}

#****f* lanswitch.tcl/lanswitch.virtlayer
# NAME
#   lanswitch.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [lanswitch.virtlayer]
# FUNCTION
#   Returns the layer on which the lanswitch node is instantiated
#   i.e. returns NATIVE.
# RESULT
#   * layer -- set to NATIVE
#****
proc $MODULE.virtlayer {} {
	return NATIVE
}

proc $MODULE.bootcmd { node_id } {
}

proc $MODULE.shellcmds {} {
}

#****f* lanswitch.tcl/lanswitch.nghook
# NAME
#   lanswitch.nghook -- nghook
# SYNOPSIS
#   set nghook [lanswitch.nghook $eid $node_id $iface_id]
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. Netgraph node name is in
#   format experimentId_nodeId and the netgraph hook is in the form of linkN,
#   where N is an interface number.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * iface_id -- interface name
# RESULT
#   * nghook -- the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
	set ifunit [expr [string range $iface_id 3 end] + 1]
	if { ! [getNodeVlanFiltering $node_id] } {
		return [list $node_id link$ifunit]
	}

	if { [getIfcVlanType $node_id $iface_id] == "trunk" } {
		set hook_name "downstream"
	} else {
		set vlantag [getIfcVlanTag $node_id $iface_id]
		set hook_name "v$vlantag"
	}

	return [list "$node_id-$hook_name" "link$ifunit"]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* lanswitch.tcl/lanswitch.prepareSystem
# NAME
#   lanswitch.prepareSystem -- prepare system
# SYNOPSIS
#   lanswitch.prepareSystem
# FUNCTION
#   Loads ng_bridge into the kernel.
#****
proc $MODULE.prepareSystem {} {
	catch { exec sysctl net.bridge.bridge-nf-call-arptables=0 }
	catch { exec sysctl net.bridge.bridge-nf-call-iptables=0 }
	catch { exec sysctl net.bridge.bridge-nf-call-ip6tables=0 }

	catch { exec kldload ng_bridge }
	catch { exec kldload ng_vlan }
}

#****f* lanswitch.tcl/lanswitch.nodeCreate
# NAME
#   lanswitch.nodeCreate -- instantiate
# SYNOPSIS
#   lanswitch.nodeCreate $eid $node_id
# FUNCTION
#   Procedure lanswitch.nodeCreate creates a new netgraph node of the type
#   bridge. The name of the netgraph node is in the form of exprimentId_nodeId.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node
#****
proc $MODULE.nodeCreate { eid node_id } {
	l2node.nodeCreate $eid $node_id
}

proc $MODULE.nodeNamespaceSetup { eid node_id } {
	createNamespace $eid-$node_id
}

#****f* lanswitch.tcl/lanswitch.nodeInitConfigure
# NAME
#   lanswitch.nodeInitConfigure -- lanswitch node nodeInitConfigure
# SYNOPSIS
#   lanswitch.nodeInitConfigure $eid $node_id
# FUNCTION
#   Runs initial L2 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeInitConfigure { eid node_id } {
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
	nodePhysIfacesCreate $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
}

#****f* lanswitch.tcl/lanswitch.nodeIfacesConfigure
# NAME
#   lanswitch.nodeIfacesConfigure -- configure lanswitch node interfaces
# SYNOPSIS
#   lanswitch.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a lanswitch. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
	if { ! [getNodeVlanFiltering $node_id] } {
		return
	}

	foreach iface_id $ifaces {
		execSetIfcVlanConfig $node_id $iface_id
	}
}

#****f* lanswitch.tcl/lanswitch.nodeConfigure
# NAME
#   lanswitch.nodeConfigure -- configure lanswitch node
# SYNOPSIS
#   lanswitch.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new lanswitch. Simulates the booting proces of a node, starts all the
#   services, etc.
#   This procedure can be called if it is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeConfigure { eid node_id } {
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* lanswitch.tcl/lanswitch.nodeIfacesUnconfigure
# NAME
#   lanswitch.nodeIfacesUnconfigure -- unconfigure lanswitch node interfaces
# SYNOPSIS
#   lanswitch.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a lanswitch to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
	if { ! [getNodeVlanFiltering $node_id] } {
		return
	}

	foreach iface_id $ifaces {
		execDelIfcVlanConfig $eid $node_id $iface_id
	}
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
	nodeIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
}

#****f* lanswitch.tcl/lanswitch.nodeShutdown
# NAME
#   lanswitch.nodeShutdown -- layer 2 node shutdown
# SYNOPSIS
#   lanswitch.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a lanswitch node.
#   Simulates the shutdown proces of a node, kills all the services and
#   processes.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
}

#****f* lanswitch.tcl/lanswitch.nodeDestroy
# NAME
#   lanswitch.nodeDestroy -- destroy
# SYNOPSIS
#   lanswitch.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a lanswitch. Destroys the netgraph node that represents
#   the lanswitch by sending a shutdown message.
# INPUTS
#   * eid -- experiment id
#   * node_id -- id of the node
#****
proc $MODULE.nodeDestroy { eid node_id } {
	l2node.nodeDestroy $eid $node_id
}
