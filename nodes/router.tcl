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

namespace eval $MODULE {
	# Define all node-specific procedures. All non-defined procedures will call
	# genericL3.* procedures from nodes/generic_l3.tcl
	namespace import ::genericL3::*
	namespace export *

	################################################################################
	########################### CONFIGURATION PROCEDURES ###########################
	################################################################################

	proc namingBase {} {
		return "router"
	}

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
	proc confNewNode { node_id } {
		invokeTypeProc "genericL3" "confNewNode" $node_id

		setNodeModel $node_id [getActiveOption "routerDefaultsModel"]

		set protocols {
			"rip	routerRipEnable"
			"ripng	routerRipngEnable"
			"ospf	routerOspfEnable"
			"ospf6	routerOspf6Enable"
			"bgp	routerBgpEnable"
			"ldp	routerLdpEnable"
			"isis	routerIsisEnable"
		}

		foreach item $protocols {
			lassign $item protocol var_name

			setNodeProtocol $node_id $protocol [getActiveOption $var_name]
		}
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
	proc confNewIfc { node_id iface_id } {
		invokeTypeProc "genericL3" "confNewIfc" $node_id $iface_id

		lassign [logicalPeerByIfc $node_id $iface_id] peer_id -
		if {
			$peer_id != "" &&
			[getNodeType $peer_id] == "ext" &&
			[getNodeNATIface $peer_id] != "UNASSIGNED"
		} {
			setIfcNatState $node_id $iface_id "on"
		}
	}

	proc generateConfigIfaces { node_id ifaces } {
		# sort physical ifaces before logical ones (because of vlans)
		set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"

		if { $ifaces == "*" } {
			set ifaces $all_ifaces
		} else {
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

	proc generateUnconfigIfaces { node_id ifaces } {
		# sort physical ifaces before logical ones (because of vlans)
		set all_ifaces "[ifcList $node_id] [logIfcList $node_id]"

		if { $ifaces == "*" } {
			set ifaces $all_ifaces
		} else {
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
	proc generateConfig { node_id } {
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

	proc generateUnconfig { node_id } {
		set cfg {}

		if { [getNodeCustomEnabled $node_id] != true } {
			foreach protocol { rip ripng ospf ospf6 } {
				set cfg [concat $cfg [getRouterProtocolUnconfig $node_id $protocol]]
			}
		}

		set cfg [concat $cfg [routerRoutesUncfggen $node_id]]

		return $cfg
	}

	proc transformNode { node_id to_type } {
		if { $to_type ni "pc host" } {
			return
		}

		# replace type
		setNodeType $node_id $to_type

		setNodeModel $node_id {}
		cfgUnset "nodes" $node_id "router_config"
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
	proc IPAddrRange {} {
		return 1
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
	proc shellcmds {} {
		return "csh bash vtysh sh tcsh"
	}

	################################################################################
	############################ INSTANTIATE PROCEDURES ############################
	################################################################################

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
	proc nodeInitConfigure { eid node_id } {
		global isOSlinux isOSfreebsd

		if { $isOSlinux } {
			array set sysctl_ipfwd {
				net.ipv6.conf.all.forwarding	1
				net.ipv4.conf.all.forwarding	1
				net.ipv4.conf.default.rp_filter	0
				net.ipv4.conf.all.rp_filter		0
			}
		}

		if { $isOSfreebsd } {
			array set sysctl_ipfwd {
				net.inet.ip.forwarding		1
				net.inet6.ip6.forwarding	1
			}
		}

		foreach {name val} [array get sysctl_ipfwd] {
			lappend cmd "sysctl $name=$val"
		}
		set cmds [join $cmd "; "]

		set os_cmd [invokeNodeProc $node_id "getExecCommand" $eid $node_id "-d"]
		pipesExec "$os_cmd sh -c '$cmds'" "hold"

		startRoutingDaemons $node_id

		return [invokeTypeProc "genericL3" "nodeInitConfigure" $eid $node_id]
	}

	################################################################################
	############################# TERMINATE PROCEDURES #############################
	################################################################################
}
