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

# $Id: router.tcl 128 2014-12-19 11:59:09Z denis $


#****h* imunes/router.tcl
# NAME
#  router.tcl -- defines specific procedures for router
#  using frr/quagga/static routing model
# FUNCTION
#  This module defines all the specific procedures for a router
#  which uses any routing model.
# NOTES
#  Procedures in this module start with the keyword router and
#  end with function specific part that is the same for all the node
#  types that work on the same layer.
#****

set MODULE router
registerModule $MODULE

################################################################################
########################### CONFIGURATION PROCEDURES ###########################
################################################################################

#****f* router.tcl/router.confNewNode
# NAME
#   router.confNewNode -- configure new node
# SYNOPSIS
#   router.confNewNode $node_id
# FUNCTION
#   Configures new node with the specified id.
# INPUTS
#   * node_id -- node id
#****
proc $MODULE.confNewNode { node_id } {
	global ripEnable ripngEnable ospfEnable ospf6Enable bgpEnable ldpEnable
	global router_ConfigModel
	global nodeNamingBase

	set router_ConfigModel [getActiveOption "routerDefaultsModel"]
	set ripEnable [getActiveOption "routerRipEnable"]
	set ripngEnable [getActiveOption "routerRipngEnable"]
	set ospfEnable [getActiveOption "routerOspfEnable"]
	set ospf6Enable [getActiveOption "routerOspf6Enable"]
	set bgpEnable [getActiveOption "routerBgpEnable"]
	set ldpEnable [getActiveOption "routerLdpEnable"]

	setNodeName $node_id [getNewNodeNameType router $nodeNamingBase(router)]
	setNodeModel $node_id [getActiveOption "routerDefaultsModel"]

	setNodeProtocol $node_id "rip" $ripEnable
	setNodeProtocol $node_id "ripng" $ripngEnable
	setNodeProtocol $node_id "ospf" $ospfEnable
	setNodeProtocol $node_id "ospf6" $ospf6Enable
	setNodeProtocol $node_id "bgp" $bgpEnable
	setNodeProtocol $node_id "ldp" $ldpEnable

	setNodeAutoDefaultRoutesStatus $node_id "enabled"

	set logiface_id [newLogIface $node_id "lo"]
	setIfcIPv4addrs $node_id $logiface_id "127.0.0.1/8"
	setIfcIPv6addrs $node_id $logiface_id "::1/128"
}

#****f* router.tcl/router.confNewIfc
# NAME
#   router.confNewIfc -- configure new interface
# SYNOPSIS
#   router.confNewIfc $node_id $iface_id
# FUNCTION
#   Configures new interface for the specified node.
# INPUTS
#   * node_id -- node id
#   * iface_id -- interface name
#****
proc $MODULE.confNewIfc { node_id iface_id } {
	autoIPv4addr $node_id $iface_id
	autoIPv6addr $node_id $iface_id
	autoMACaddr $node_id $iface_id

	lassign [logicalPeerByIfc $node_id $iface_id] peer_id -
	if { $peer_id != "" && [getNodeType $peer_id] == "ext" && [getNodeNATIface $peer_id] != "UNASSIGNED" } {
		setIfcNatState $node_id $iface_id "on"
	}
}

proc $MODULE.generateConfigIfaces { node_id ifaces } {
	set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"
	if { $ifaces == "*" } {
		set ifaces $all_ifaces
	} else {
		# sort physical ifaces before logical ones (because of vlans)
		set negative_ifaces [removeFromList $all_ifaces $ifaces]
		set ifaces [removeFromList $all_ifaces $negative_ifaces]
	}

	set cfg {}
	foreach iface_id $ifaces {
		set cfg [concat $cfg [routerCfggenIfc $node_id $iface_id]]

		lappend cfg ""
	}

	return $cfg
}

proc $MODULE.generateUnconfigIfaces { node_id ifaces } {
	set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"
	if { $ifaces == "*" } {
		set ifaces $all_ifaces
	} else {
		# sort physical ifaces before logical ones
		set negative_ifaces [removeFromList $all_ifaces $ifaces]
		set ifaces [removeFromList $all_ifaces $negative_ifaces]
	}

	set cfg {}
	foreach iface_id $ifaces {
		set cfg [concat $cfg [routerUncfggenIfc $node_id $iface_id]]

		lappend cfg ""
	}

	return $cfg
}

#****f* router.tcl/router.generateConfig
# NAME
#   router.generateConfig -- configuration generator
# SYNOPSIS
#   set config [router.generateConfig $node_id]
# FUNCTION
#   Generates configuration. This configuration represents the default
#   configuration loaded on the booting time of the virtual nodes and it is
#   closly related to the procedure router.bootcmd.
#   Generated configuration comprises the ip addresses (both ipv4 and ipv6)
#   and interface states (up or down) for each interface of a given node.
#   Static routes are also included.
# INPUTS
#   * node_id - node id
# RESULT
#   * config -- generated configuration
#****
proc $MODULE.generateConfig { node_id } {
	set cfg {}
	if {
		[getNodeCustomEnabled $node_id] != true ||
		[getNodeCustomConfigSelected $node_id "NODE_CONFIG"] in "\"\" DISABLED"
	} {
		foreach protocol { rip ripng ospf ospf6 } {
			set cfg [concat $cfg [getRouterProtocolCfg $node_id $protocol]]
		}
	}

	set subnet_gws {}
	set nodes_l2data [dict create]
	if { [getNodeAutoDefaultRoutesStatus $node_id] == "enabled" } {
		lassign [getDefaultGateways $node_id $subnet_gws $nodes_l2data] my_gws subnet_gws nodes_l2data
		lassign [getDefaultRoutesConfig $node_id $my_gws] all_routes4 all_routes6

		setDefaultIPv4routes $node_id $all_routes4
		setDefaultIPv6routes $node_id $all_routes6
	} else {
		setDefaultIPv4routes $node_id {}
		setDefaultIPv6routes $node_id {}
	}

	set cfg [concat $cfg [routerRoutesCfggen $node_id]]

	return $cfg
}

proc $MODULE.generateUnconfig { node_id } {
	set cfg {}

	if { [getNodeCustomEnabled $node_id] != true } {
		foreach protocol { rip ripng ospf ospf6 } {
			set cfg [concat $cfg [getRouterProtocolUnconfig $node_id $protocol]]
		}
	}

	set cfg [concat $cfg [routerRoutesUncfggen $node_id]]

	return $cfg
}

#****f* router.tcl/router.ifacePrefix
# NAME
#   router.ifacePrefix -- interface name
# SYNOPSIS
#   router.ifacePrefix
# FUNCTION
#   Returns router interface name prefix.
# RESULT
#   * name -- name prefix string
#****
proc $MODULE.ifacePrefix {} {
	return "eth"
}

#****f* router.tcl/router.IPAddrRange
# NAME
#   router.IPAddrRange -- IP address range
# SYNOPSIS
#   router.IPAddrRange
# FUNCTION
#   Returns router IP address range
# RESULT
#   * range -- router IP address range
#****
proc $MODULE.IPAddrRange {} {
	return 1
}

#****f* router.tcl/router.netlayer
# NAME
#   router.netlayer -- layer
# SYNOPSIS
#   set layer [router.netlayer]
# FUNCTION
#   Returns the layer on which the router operates, i.e. returns NETWORK.
# RESULT
#   * layer -- set to NETWORK
#****
proc $MODULE.netlayer {} {
	return NETWORK
}

#****f* router.tcl/router.virtlayer
# NAME
#   router.virtlayer -- virtual layer
# SYNOPSIS
#   set layer [router.virtlayer]
# FUNCTION
#   Returns the layer on which the router is instantiated, i.e. returns
#   VIRTUALIZED.
# RESULT
#   * layer -- set to VIRTUALIZED
#****
proc $MODULE.virtlayer {} {
	return VIRTUALIZED
}

#****f* router.tcl/router.bootcmd
# NAME
#   router.bootcmd -- boot command
# SYNOPSIS
#   set appl [router.bootcmd $node_id]
# FUNCTION
#   Procedure bootcmd returns the defaut application that reads and employes
#   the configuration generated in router.generateConfig.
# INPUTS
#   * node_id - node id
# RESULT
#   * appl -- application that reads the configuration
#****
proc $MODULE.bootcmd { node_id } {
	return "/bin/sh"
}

#****f* router.tcl/router.shellcmds
# NAME
#   router.shellcmds -- shell commands
# SYNOPSIS
#   set shells [router.shellcmds]
# FUNCTION
#   Procedure shellcmds returns the shells that can be opened
#   as a default shell for the system.
# RESULT
#   * shells -- default shells for the router
#****
proc $MODULE.shellcmds {} {
	return "csh bash vtysh sh tcsh"
}

#****f* router.tcl/router.nghook
# NAME
#   router.nghook -- nghook
# SYNOPSIS
#   router.nghook $eid $node_id $iface_id
# FUNCTION
#   Returns the id of the netgraph node and the name of the netgraph hook
#   which is used for connecting two netgraph nodes. This procedure calls
#   l3node.hook procedure and passes the result of that procedure.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#   * iface_id - interface id
# RESULT
#   * nghook - the list containing netgraph node id and the
#     netgraph hook (ngNode ngHook).
#****
proc $MODULE.nghook { eid node_id iface_id } {
	return [list $node_id-[getIfcName $node_id $iface_id] ether]
}

################################################################################
############################ INSTANTIATE PROCEDURES ############################
################################################################################

#****f* router.tcl/router.prepareSystem
# NAME
#   router.prepareSystem -- prepare system
# SYNOPSIS
#   router.prepareSystem
# FUNCTION
#   Does nothing
#****
proc $MODULE.prepareSystem {} {
	# nothing to do
}

#****f* router.tcl/router.nodeCreate
# NAME
#   router.nodeCreate -- instantiate
# SYNOPSIS
#   router.nodeCreate $eid $node_id
# FUNCTION
#   Creates a new virtual node for a given node in imunes.
#   Procedure router.nodeCreate creates a new virtual node with all
#   the interfaces and CPU parameters as defined in imunes. It sets the
#   net.inet.ip.forwarding and net.inet6.ip6.forwarding kernel variables to 1.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#****
proc $MODULE.nodeCreate { eid node_id } {
	prepareFilesystemForNode $node_id
	createNodeContainer $node_id
}

#****f* router.tcl/router.nodeNamespaceSetup
# NAME
#   router.nodeNamespaceSetup -- router node nodeNamespaceSetup
# SYNOPSIS
#   router.nodeNamespaceSetup $eid $node_id
# FUNCTION
#   Linux only. Attaches the existing Docker netns to a new one.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeNamespaceSetup { eid node_id } {
	attachToL3NodeNamespace $node_id
}

#****f* router.tcl/router.nodeInitConfigure
# NAME
#   router.nodeInitConfigure -- router node nodeInitConfigure
# SYNOPSIS
#   router.nodeInitConfigure $eid $node_id
# FUNCTION
#   Runs initial L3 configuration, such as creating logical interfaces and
#   configuring sysctls.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeInitConfigure { eid node_id } {
	enableIPforwarding $node_id
	startRoutingDaemons $node_id
	configureICMPoptions $node_id
}

proc $MODULE.nodePhysIfacesCreate { eid node_id ifaces } {
	nodePhysIfacesCreate $node_id $ifaces
}

proc $MODULE.nodeLogIfacesCreate { eid node_id ifaces } {
	nodeLogIfacesCreate $node_id $ifaces
}

#****f* router.tcl/router.nodeIfacesConfigure
# NAME
#   router.nodeIfacesConfigure -- configure router node interfaces
# SYNOPSIS
#   router.nodeIfacesConfigure $eid $node_id $ifaces
# FUNCTION
#   Configure interfaces on a router. Set MAC, MTU, queue parameters, assign the IP
#   addresses to the interfaces, etc. This procedure can be called if the node
#   is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesConfigure { eid node_id ifaces } {
	startNodeIfaces $node_id $ifaces
}

#****f* router.tcl/router.nodeConfigure
# NAME
#   router.nodeConfigure -- start
# SYNOPSIS
#   router.nodeConfigure $eid $node_id
# FUNCTION
#   Starts a new router. The node can be started if it is instantiated.
#   Simulates the booting proces of a router.
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#****
proc $MODULE.nodeConfigure { eid node_id } {
	runConfOnNode $node_id
}

################################################################################
############################# TERMINATE PROCEDURES #############################
################################################################################

#****f* router.tcl/router.nodeIfacesUnconfigure
# NAME
#   router.nodeIfacesUnconfigure -- unconfigure router node interfaces
# SYNOPSIS
#   router.nodeIfacesUnconfigure $eid $node_id $ifaces
# FUNCTION
#   Unconfigure interfaces on a router to a default state. Set name to iface_id,
#   flush IP addresses to the interfaces, etc. This procedure can be called if
#   the node is instantiated.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#   * ifaces -- list of interface ids
#****
proc $MODULE.nodeIfacesUnconfigure { eid node_id ifaces } {
	unconfigNodeIfaces $eid $node_id $ifaces
}

proc $MODULE.nodeLogIfacesDestroy { eid node_id ifaces } {
	nodeLogIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeIfacesDestroy { eid node_id ifaces } {
	nodeIfacesDestroy $eid $node_id $ifaces
}

proc $MODULE.nodeUnconfigure { eid node_id } {
	unconfigNode $eid $node_id
}

#****f* router.tcl/router.nodeShutdown
# NAME
#   router.nodeShutdown -- shutdown
# SYNOPSIS
#   router.nodeShutdown $eid $node_id
# FUNCTION
#   Shutdowns a router node.
#   Simulates the shutdown proces of a node, kills all the services and
# INPUTS
#   * eid - experiment id
#   * node_id - node id
#****
proc $MODULE.nodeShutdown { eid node_id } {
	killExtProcess "wireshark.*[getNodeName $node_id].*\\($eid\\)"
	killExtProcess "socat.*$eid/$node_id.*"
	killAllNodeProcesses $eid $node_id
}

#****f* router.tcl/router.nodeDestroy
# NAME
#   router.nodeDestroy -- layer 3 node destroy
# SYNOPSIS
#   router.nodeDestroy $eid $node_id
# FUNCTION
#   Destroys a router node.
#   First, it destroys all remaining virtual ifaces (vlans, tuns, etc).
#   Then, it destroys the jail/container with its namespaces and FS.
# INPUTS
#   * eid -- experiment id
#   * node_id -- node id
#****
proc $MODULE.nodeDestroy { eid node_id } {
	destroyNodeVirtIfcs $eid $node_id
	removeNodeContainer $eid $node_id
}

proc $MODULE.nodeDestroyFS { eid node_id } {
	destroyNamespace $eid-$node_id
	removeNodeFS $eid $node_id
}
