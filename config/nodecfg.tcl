#
# Copyright 2004-2013 University of Zagreb.
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

# $Id: nodecfg.tcl 149 2015-03-27 15:50:14Z valter $


#****h* imunes/nodecfg.tcl
# NAME
#  nodecfg.tcl -- file used for manipultaion with nodes in IMUNES
# FUNCTION
#  This module is used to define all the actions used for configuring
#  nodes in IMUNES. The definition of nodes is presented in NOTES
#  section.
#
# NOTES
#  The IMUNES configuration file contains declarations of IMUNES objects.
#  Each object declaration contains exactly the following three fields:
#
#     object_class object_id class_specific_config_string
#
#  Currently only two object classes are supported: node and link. In the
#  future we plan to implement a canvas object, which should allow placing
#  other objects into multiple visual maps.
#
#  "node" objects are further divided by their type, which can be one of
#  the following:
#  * router
#  * host
#  * pc
#  * lanswitch
#  * hub
#  * rj45
#  * pseudo
#
#  The following node types are to be implemented in the future:
#  * frswitch
#  * text
#  * image
#
#
# Routines for manipulation of per-node network configuration files
# IMUNES keeps per-node network configuration in an IOS / Zebra / Quagga
# style format.
#
# Network configuration is embedded in each node's config section via the
# "network-config" statement. The following functions can be used to
# manipulate the per-node network config:
#
# getDefaultGateways { node_id subnet_gws nodes_l2data }
#	Returns a list of all default IPv4/IPv6 routes as {destination
#	gateway} pairs and updates existing subnet gateways and members.
#
# getStatIPv4routes { node_id }
#	Returns a list of all static IPv4 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv4routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getStatIPv6routes { node_id }
#	Returns a list of all static IPv6 routes as a list of
#	{destination gateway {metric}} pairs.
#
# setStatIPv6routes { node_id route_list }
#	Replace all current static route entries with a new one, in form of
#	a list, as described above.
#
# getNodeName { node_id }
#	Returns node's logical name.
#
# setNodeName { node_id name }
#	Sets a new node's logical name.
#
# getNodeType { node_id }
#	Returns node's type.
#
# getNodeModel { node_id }
#	Returns node's optional model identifier.
#
# setNodeModel { node_id model }
#	Sets the node's optional model identifier.
#
# getNodeCanvas { node_id }
#	Returns node's canvas affinity.
#
# setNodeCanvas { node_id canvas_id }
#	Sets the node's canvas affinity.
#
# getNodeCoords { node_id }
#	Return icon coords.
#
# setNodeCoords { node_id coords }
#	Sets the coordinates.
#
# getNodeSnapshot { node_id }
#	Return node's snapshot name.
#
# setNodeSnapshot { node_id coords }
#	Sets node's snapshot name.
#
# getSTPEnabled { node_id }
#	Returns true if STP is enabled.
#
# setSTPEnabled { node_id state }
#	Sets STP state.
#
# getNodeLabelCoords { node_id }
#	Return node label coordinates.
#
# setNodeLabelCoords { node_id coords }
#	Sets the label coordinates.
#
# getNodeCPUConf { node_id }
#	Returns node's CPU scheduling parameters { minp maxp weight }.
#
# setNodeCPUConf { node_id param_list }
#	Sets the node's CPU scheduling parameters.
#
# All of the above functions are independent to any Tk objects. This means
# they can be used for implementing tasks external to GUI, so inside the
# GUI any updating of related Tk objects (such as text labels etc.) will
# have to be implemented by additional Tk code.
#
# Additionally, an alternative configuration can be specified in
# "custom-config" section.
#
# getCustomEnabled { node_id }
#
# setCustomEnabled { node_id state }
#
# getCustomConfigSelected { node_id }
#
# setCustomConfigSelected { node_id conf }
#
# getCustomConfig { node_id id }
#
# setCustomConfig { node_id id cmd config }
#
# removeCustomConfig { node_id id }
#
# getCustomConfigCommand { node_id id }
#
# getCustomConfigIDs { node_id }
#
#****

proc getNodeDir { node_id } {
    set node_dir [getNodeCustomImage $node_id]
    if { $node_dir == "" } {
	set node_dir [getVrootDir]/[getFromRunning "eid"]/$node_id
    }

    return $node_dir
}

#****f* nodecfg.tcl/getCustomEnabled
# NAME
#   getCustomEnabled -- get custom configuration enabled state
# SYNOPSIS
#   set enabled [getCustomEnabled $node_id]
# FUNCTION
#   For input node this procedure returns true if custom configuration is
#   enabled for the specified node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * state -- returns true if custom configuration is enabled
#****
proc getCustomEnabled { node_id } {
    return [cfgGetWithDefault "false" "nodes" $node_id "custom_enabled"]
}

#****f* nodecfg.tcl/setCustomEnabled
# NAME
#   setCustomEnabled -- set custom configuration enabled state
# SYNOPSIS
#   setCustomEnabled $node_id $state
# FUNCTION
#   For input node this procedure enables or disables custom configuration.
# INPUTS
#   * node_id -- node id
#   * state -- true if enabling custom configuration, false if disabling
#****
proc setCustomEnabled { node_id state } {
    cfgSet "nodes" $node_id "custom_enabled" $state

    trigger_nodeRecreate $node_id
}

#****f* nodecfg.tcl/getCustomConfigSelected
# NAME
#   getCustomConfigSelected -- get default custom configuration
# SYNOPSIS
#   getCustomConfigSelected $node_id
# FUNCTION
#   For input node this procedure returns ID of a default configuration
# INPUTS
#   * node_id -- node id
# RESULT
#   * ID -- returns default custom configuration ID
#****
proc getCustomConfigSelected { node_id } {
    return [cfgGet "nodes" $node_id "custom_selected"]
}

#****f* nodecfg.tcl/setCustomConfigSelected
# NAME
#   setCustomConfigSelected -- set default custom configuration
# SYNOPSIS
#   setCustomConfigSelected $node_id
# FUNCTION
#   For input node this procedure sets ID of a default configuration
# INPUTS
#   * node_id -- node id
#   * conf -- custom-config id
#****
proc setCustomConfigSelected { node_id cfg_id } {
    cfgSet "nodes" $node_id "custom_selected" $cfg_id

    if { [getCustomEnabled $node_id] && [getCustomConfigSelected $node_id] == $cfg_id } {
	trigger_nodeRecreate $node_id
    }
}

#****f* nodecfg.tcl/getCustomConfig
# NAME
#   getCustomConfig -- get custom configuration
# SYNOPSIS
#   getCustomConfig $node_id $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration.
# INPUTS
#   * node_id -- node id
#   * id -- configuration id
# RESULT
#   * customConfig -- returns custom configuration
#****
proc getCustomConfig { node_id cfg_id } {
    return [cfgGet "nodes" $node_id "custom_configs" $cfg_id "custom_config"]
}

#****f* nodecfg.tcl/setCustomConfig
# NAME
#   setCustomConfig -- set custom configuration
# SYNOPSIS
#   setCustomConfig $node_id $id $cmd $config
# FUNCTION
#   For input node this procedure sets custom configuration section in input
#   node.
# INPUTS
#   * node_id -- node id
#   * id -- custom-config id
#   * cmd -- custom command
#   * config -- custom configuration section
#****
proc setCustomConfig { node_id cfg_id cmd config } {
    cfgSet "nodes" $node_id "custom_configs" $cfg_id "custom_command" $cmd
    cfgSet "nodes" $node_id "custom_configs" $cfg_id "custom_config" $config

    if { [getCustomEnabled $node_id] && [getCustomConfigSelected $node_id] == $cfg_id } {
	trigger_nodeRecreate $node_id
    }
}

#****f* nodecfg.tcl/removeCustomConfig
# NAME
#   removeCustomConfig -- remove custom configuration
# SYNOPSIS
#   removeCustomConfig $node_id $id
# FUNCTION
#   For input node and configuration ID this procedure removes custom
#   configuration from node.
# INPUTS
#   * node_id -- node id
#   * id -- configuration id
#****
proc removeCustomConfig { node_id cfg_id } {
    cfgUnset "nodes" $node_id "custom_configs" $cfg_id
}

#****f* nodecfg.tcl/getCustomConfigCommand
# NAME
#   getCustomConfigCommand -- get custom configuration boot command
# SYNOPSIS
#   getCustomConfigCommand $node_id $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration boot command.
# INPUTS
#   * node_id -- node id
#   * id -- configuration id
# RESULT
#   * customCmd -- returns custom configuration boot command
#****
proc getCustomConfigCommand { node_id cfg_id } {
    return [cfgGet "nodes" $node_id "custom_configs" $cfg_id "custom_command"]
}

#****f* nodecfg.tcl/getCustomConfigIDs
# NAME
#   getCustomConfigIDs -- get custom configuration IDs
# SYNOPSIS
#   getCustomConfigIDs $node_id
# FUNCTION
#   For input node this procedure returns all custom configuration IDs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * IDs -- returns custom configuration IDs
#****
proc getCustomConfigIDs { node_id } {
    return [dict keys [cfgGet "nodes" $node_id "custom_configs"]]
}

#****f* nodecfg.tcl/getNodeStolenIfaces
# NAME
#   getNodeStolenIfaces -- set node name.
# SYNOPSIS
#   getNodeStolenIfaces $node_id $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node -- node id
#   * name -- logical name of the node
#****
proc getNodeStolenIfaces { node_id } {
    set external_ifaces {}
    foreach {iface_id iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
	if { [dictGet $iface_cfg "type"] == "stolen" } {
	    set stolen_iface [dictGet $iface_cfg "stolen_iface"]
	    lappend external_ifaces "$iface_id $stolen_iface"
	}
    }

    return $external_ifaces
}

#****f* nodecfg.tcl/getDefaultGateways
# NAME
#   getDefaultGateways -- get default IPv4/IPv6 gateways.
# SYNOPSIS
#   lassign [getDefaultGateways $node_id $subnet_gws $nodes_l2data] \
#     my_gws subnets_and_gws
# FUNCTION
#   Returns a list of all default IPv4/IPv6 gateways for the subnets in which
#   this node belongs as a {node_type|gateway4|gateway6} values. Additionally,
#   it refreshes newly discovered gateways and subnet members to the existing
#   $subnet_gws list and $nodes_l2data dictionary.
# INPUTS
#   * node_id -- node id
#   * subnet_gws -- already known {node_type|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node_id iface_id subnet_idx}
#   triplets in this subnet
# RESULT
#   * my_gws -- list of all possible default gateways for the specified node
#   * subnet_gws -- refreshed {node_type|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node_id iface_id subnet_idx} triplets in
#   this subnet
#****
proc getDefaultGateways { node_id subnet_gws nodes_l2data } {
    set node_ifaces [ifcList $node_id]
    if { [llength $node_ifaces] == 0 } {
	return [list {} {} {}]
    }

    # go through all interfaces and collect data for each subnet
    foreach iface_id $node_ifaces {
	if { [dictGet $nodes_l2data $node_id $iface_id] != "" } {
	    continue
	}

	# add new subnet at the end of the list
	set subnet_idx [llength $subnet_gws]
	lassign [logicalPeerByIfc $node_id $iface_id] peer_id peer_iface_id
	if { $peer_id == "" } {
	    continue
	}

	lassign [getSubnetData $peer_id $peer_iface_id \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    # merge all gateways values and return
    set my_gws {}
    if { $nodes_l2data != {} } {
	foreach subnet_idx [lsort -unique [dict values [dictGet $nodes_l2data $node_id]]] {
	    set my_gws [concat $my_gws [lindex $subnet_gws $subnet_idx]]
	}
    }

    return [list $my_gws $subnet_gws $nodes_l2data]
}

#****f* nodecfg.tcl/getSubnetData
# NAME
#   getSubnetData -- get subnet members and its IPv4/IPv6 gateways.
# SYNOPSIS
#   lassign [getSubnetData $this_node $this_ifc \
#     $subnet_gws $nodes_l2data $subnet_idx] \
#     subnet_gws nodes_l2data
# FUNCTION
#   Called when checking L2 network for routers/extnats in order to get all
#   default gateways. Returns all possible default IPv4/IPv6 gateways in this
#   LAN appended to the subnet_gws list and updates the members of this subnet
#   as {node_id iface_id subnet_idx} triplets in the nodes_l2data dictionary.
# INPUTS
#   * this_node -- node id
#   * this_ifc -- node interface
#   * subnet_gws -- already known {node_type|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node_id iface_id subnet_idx}
#   triplets in this subnet
# RESULT
#   * subnet_gws -- refreshed {node_type|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node_id iface_id subnet_idx} triplets in
#   this subnet
#****
proc getSubnetData { this_node_id this_ifc subnet_gws nodes_l2data subnet_idx } {
    set my_gws [lindex $subnet_gws $subnet_idx]

    if { [dict exists $nodes_l2data $this_node_id $this_ifc] } {
	# this node/iface is already a part of this subnet
	set subnet_idx [dict get $nodes_l2data $this_node_id $this_ifc]
	return [list $subnet_gws $nodes_l2data]
    }

    dict set nodes_l2data $this_node_id $this_ifc $subnet_idx

    set this_type [getNodeType $this_node_id]
    if { [$this_type.netlayer] == "NETWORK" } {
	if { $this_type in "router nat64 extnat" } {
	    # this node is a router/extnat, add our IP addresses to lists
	    set gw4 [lindex [split [getIfcIPv4addr $this_node_id $this_ifc] /] 0]
	    set gw6 [lindex [split [getIfcIPv6addr $this_node_id $this_ifc] /] 0]
	    lappend my_gws $this_type|$gw4|$gw6
	    lset subnet_gws $subnet_idx $my_gws
	}

	# first, get this node/iface peer's subnet data in case it is an L2 node
	# and we're not yet gone through it
	lassign [logicalPeerByIfc $this_node_id $this_ifc] peer_id peer_iface_id
	if { $peer_id != "" } {
	    lassign [getSubnetData $peer_id $peer_iface_id \
		$subnet_gws $nodes_l2data $subnet_idx] \
		subnet_gws nodes_l2data
	}

	# this node is done, do nothing else
	if { $subnet_gws == "" } {
	    set subnet_gws "{||}"
	}

	return [list $subnet_gws $nodes_l2data]
    }

    # this node is an L2 node
    # - collect data from all interfaces
    foreach iface_id [ifcList $this_node_id] {
	dict set nodes_l2data $this_node_id $iface_id $subnet_idx

	lassign [logicalPeerByIfc $this_node_id $iface_id] peer_id peer_iface_id
	if { $peer_id == "" } {
	    continue
	}

	lassign [getSubnetData $peer_id $peer_iface_id \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    return [list $subnet_gws $nodes_l2data]
}

#****f* nodecfg.tcl/getStatIPv4routes
# NAME
#   getStatIPv4routes -- get static IPv4 routes.
# SYNOPSIS
#   set routes [getStatIPv4routes $node_id]
# FUNCTION
#   Returns a list of all static IPv4 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv4routes { node_id } {
    return [cfgGet "nodes" $node_id "croutes4"]
}

#****f* nodecfg.tcl/setStatIPv4routes
# NAME
#   setStatIPv4routes -- set static IPv4 routes.
# SYNOPSIS
#   setStatIPv4routes $node_id $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- the node id of the node whose static routes are set.
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv4routes { node_id routes } {
    cfgSet "nodes" $node_id "croutes4" $routes

    trigger_nodeReconfig $node_id
}

#****f* nodecfg.tcl/getDefaultIPv4routes
# NAME
#   getDefaultIPv4routes -- get auto default IPv4 routes.
# SYNOPSIS
#   set routes [getDefaultIPv4routes $node_id]
# FUNCTION
#   Returns a list of all auto default IPv4 routes as a list of
#   {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all IPv4 default routes defined for the specified node
#****
proc getDefaultIPv4routes { node_id } {
    return [cfgGet "nodes" $node_id "default_routes4"]
}

#****f* nodecfg.tcl/setDefaultIPv4routes
# NAME
#   setDefaultIPv4routes -- set auto default IPv4 routes.
# SYNOPSIS
#   setDefaultIPv4routes $node_id $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node_id -- the node id of the node whose default routes are set
#   * routes -- list of all IPv4 default routes defined for the specified node
#****
proc setDefaultIPv4routes { node_id routes } {
    cfgSet "nodes" $node_id "default_routes4" $routes
}

#****f* nodecfg.tcl/getDefaultIPv6routes
# NAME
#   getDefaultIPv6routes -- get auto default IPv6 routes.
# SYNOPSIS
#   set routes [getDefaultIPv6routes $node_id]
# FUNCTION
#   Returns a list of all auto default IPv6 routes as a list of
#   {::/0 gateway} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all IPv6 default routes defined for the specified node
#****
proc getDefaultIPv6routes { node_id } {
    return [cfgGet "nodes" $node_id "default_routes6"]
}

#****f* nodecfg.tcl/setDefaultIPv6routes
# NAME
#   setDefaultIPv6routes -- set auto default IPv6 routes.
# SYNOPSIS
#   setDefaultIPv6routes $node_id $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {::/0 gateway} pairs.
# INPUTS
#   * node_id -- the node id of the node whose default routes are set
#   * routes -- list of all IPv6 default routes defined for the specified node
#****
proc setDefaultIPv6routes { node_id routes } {
    cfgSet "nodes" $node_id "default_routes6" $routes
}

#****f* nodecfg.tcl/getStatIPv6routes
# NAME
#   getStatIPv6routes -- get static IPv6 routes.
# SYNOPSIS
#   set routes [getStatIPv6routes $node_id]
# FUNCTION
#   Returns a list of all static IPv6 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * routes -- list of all static routes defined for the specified node
#****
proc getStatIPv6routes { node_id } {
    return [cfgGet "nodes" $node_id "croutes6"]
}

#****f* nodecfg.tcl/setStatIPv6routes
# NAME
#   setStatIPv6routes -- set static IPv6 routes.
# SYNOPSIS
#   setStatIPv6routes $node_id $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node_id -- node id
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv6routes { node_id routes } {
    cfgSet "nodes" $node_id "croutes6" $routes

    trigger_nodeReconfig $node_id
}

#****f* nodecfg.tcl/getDefaultRoutesConfig
# NAME
#   getDefaultRoutesConfig -- get node default routes in a configuration format
# SYNOPSIS
#   lassign [getDefaultRoutesConfig $node_id $gws] routes4 routes6
# FUNCTION
#   Called when translating IMUNES default gateways configuration to node
#   pre-running configuration. Returns IPv4 and IPv6 routes lists.
# INPUTS
#   * node_id -- node id
#   * gws -- gateway values in the {node_type|gateway4|gateway6} format
# RESULT
#   * all_routes4 -- {0.0.0.0/0 gw4} pairs of default IPv4 routes
#   * all_routes6 -- {0.0.0.0/0 gw6} pairs of default IPv6 routes
#****
proc getDefaultRoutesConfig { node_id gws } {
    set all_routes4 {}
    set all_routes6 {}
    foreach route $gws {
	lassign [split $route "|"] route_type gateway4 gateway6
	if { [getNodeType $node_id] in "router nat64" } {
	    if { $route_type == "extnat" } {
		if { "0.0.0.0/0 $gateway4" ni [list "0.0.0.0/0 " $all_routes4] } {
		    lappend all_routes4 "0.0.0.0/0 $gateway4"
		}

		if { "::/0 $gateway6" ni [list "::/0 " $all_routes6] } {
		    lappend all_routes6 "::/0 $gateway6"
		}
	    }
	} else {
	    if { "0.0.0.0/0 $gateway4" ni [list "0.0.0.0/0 " $all_routes4] } {
		lappend all_routes4 "0.0.0.0/0 $gateway4"
	    }

	    if { "::/0 $gateway6" ni [list "::/0 " $all_routes6] } {
		lappend all_routes6 "::/0 $gateway6"
	    }
	}
    }

    return "\"$all_routes4\" \"$all_routes6\""
}

#****f* nodecfg.tcl/getNodeName
# NAME
#   getNodeName -- get node name.
# SYNOPSIS
#   set name [getNodeName $node_id]
# FUNCTION
#   Returns node's logical name.
# INPUTS
#   * node_id -- node id
# RESULT
#   * name -- logical name of the node
#****
proc getNodeName { node_id } {
    return [cfgGet "nodes" $node_id "name"]
}

#****f* nodecfg.tcl/setNodeName
# NAME
#   setNodeName -- set node name.
# SYNOPSIS
#   setNodeName $node_id $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node_id -- node id
#   * name -- logical name of the node
#****
proc setNodeName { node_id name } {
    cfgSet "nodes" $node_id "name" $name

    set node_type [getNodeType $node_id]
    if { $node_type == "pseudo" } {
	return
    }

    if { [$node_type.virtlayer] == "NATIVE" } {
	if { $node_type in "rj45 extnat" } {
	    trigger_nodeReconfig $node_id
	}

	return
    }

    trigger_nodeRecreate $node_id
}

#****f* nodecfg.tcl/getNodeType
# NAME
#   getNodeType -- get node type.
# SYNOPSIS
#   set type [getNodeType $node_id]
# FUNCTION
#   Returns node's type.
# INPUTS
#   * node_id -- node id
# RESULT
#   * type -- type of the node
#****
proc getNodeType { node_id } {
    return [cfgGet "nodes" $node_id "type"]
}

#****f* nodecfg.tcl/getNodeModel
# NAME
#   getNodeModel -- get node routing model.
# SYNOPSIS
#   set model [getNodeModel $node_id]
# FUNCTION
#   Returns node's optional routing model. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node_id -- node id
# RESULT
#   * model -- routing model of the specified node
#****
proc getNodeModel { node_id } {
    return [cfgGet "nodes" $node_id "model"]
}

#****f* nodecfg.tcl/setNodeModel
# NAME
#   setNodeModel -- set node routing model.
# SYNOPSIS
#   setNodeModel $node_id $model
# FUNCTION
#   Sets an optional routing model to the node. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node_id -- node id
#   * model -- routing model of the specified node
#****
proc setNodeModel { node_id model } {
    cfgSet "nodes" $node_id "model" $model

    trigger_nodeFullReconfig $node_id
}

#****f* nodecfg.tcl/getNodeSnapshot
# NAME
#   getNodeSnapshot -- get node snapshot image name.
# SYNOPSIS
#   set snapshot [getNodeSnapshot $node_id]
# FUNCTION
#   Returns node's snapshot name.
# INPUTS
#   * node_id -- node id
# RESULT
#   * snapshot -- snapshot name for the specified node
#****
proc getNodeSnapshot { node_id } {
    return [cfgGet "nodes" $node_id "snapshot"]
}

#****f* nodecfg.tcl/setNodeSnapshot
# NAME
#   setNodeSnapshot -- set node snapshot image name.
# SYNOPSIS
#   setNodeSnapshot $node_id $snapshot
# FUNCTION
#   Sets node's snapshot name.
# INPUTS
#   * node_id -- node id
#   * snapshot -- snapshot name for the specified node
#****
proc setNodeSnapshot { node_id snapshot } {
    cfgSet "nodes" $node_id "snapshot" $snapshot
}

#****f* nodecfg.tcl/getStpEnabled
# NAME
#   getStpEnabled -- get STP enabled state
# SYNOPSIS
#   set state [getStpEnabled $node_id]
# FUNCTION
#   For input node this procedure returns true if STP is enabled
#   for the specified node.
# INPUTS
#   * node_id -- node id
# RESULT
#   * state -- returns true if STP is enabled
#****
proc getStpEnabled { node_id } {
    return [cfgGet "nodes" $node_id "stp_enabled"]
}

#****f* nodecfg.tcl/setStpEnabled
# NAME
#   setStpEnabled -- set STP enabled state
# SYNOPSIS
#   setStpEnabled $node_id $state
# FUNCTION
#   For input node this procedure enables or disables STP.
# INPUTS
#   * node_id -- node id
#   * state -- true if enabling STP, false if disabling
#****
proc setStpEnabled { node_id state } {
    cfgSet "nodes" $node_id "stp_enabled" $state
}

#****f* nodecfg.tcl/getNodeCoords
# NAME
#   getNodeCoords -- get node icon coordinates.
# SYNOPSIS
#   set coords [getNodeCoords $node_id]
# FUNCTION
#   Returns node's icon coordinates.
# INPUTS
#   * node_id -- node id
# RESULT
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc getNodeCoords { node_id } {
    return [cfgGet "nodes" $node_id "iconcoords"]
}

#****f* nodecfg.tcl/setNodeCoords
# NAME
#   setNodeCoords -- set node's icon coordinates.
# SYNOPSIS
#   setNodeCoords $node_id $coords
# FUNCTION
#   Sets node's icon coordinates.
# INPUTS
#   * node_id -- node id
#   * coords -- coordinates of the node's icon in form of {Xcoord Ycoord}
#****
proc setNodeCoords { node_id coords } {
    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    cfgSet "nodes" $node_id "iconcoords" $roundcoords
}

#****f* nodecfg.tcl/getNodeLabelCoords
# NAME
#   getNodeLabelCoords -- get node's label coordinates.
# SYNOPSIS
#   set coords [getNodeLabelCoords $node_id]
# FUNCTION
#   Returns node's label coordinates.
# INPUTS
#   * node_id -- node id
# RESULT
#   * coords -- coordinates of the node's label in form of {Xcoord Ycoord}
#****
proc getNodeLabelCoords { node_id } {
    return [cfgGet "nodes" $node_id "labelcoords"]
}

#****f* nodecfg.tcl/setNodeLabelCoords
# NAME
#   setNodeLabelCoords -- set node's label coordinates.
# SYNOPSIS
#   setNodeLabelCoords $node_id $coords
# FUNCTION
#   Sets node's label coordinates.
# INPUTS
#   * node_id -- node id
#   * coords -- coordinates of the node's label in form of Xcoord Ycoord
#****
proc setNodeLabelCoords { node_id coords } {
    foreach c $coords {
	set x [expr round($c)]
	lappend roundcoords $x
    }

    cfgSet "nodes" $node_id "labelcoords" $roundcoords
}

#****f* nodecfg.tcl/getNodeCPUConf
# NAME
#   getNodeCPUConf -- get node's CPU configuration
# SYNOPSIS
#   set conf [getNodeCPUConf $node_id]
# FUNCTION
#   Returns node's CPU scheduling parameters { minp maxp weight }.
# INPUTS
#   * node_id -- node id
# RESULT
#   * conf -- node's CPU scheduling parameters { minp maxp weight }
#****
proc getNodeCPUConf { node_id } {
    return [cfgGet "nodes" $node_id "cpu"]
}

#****f* nodecfg.tcl/setNodeCPUConf
# NAME
#   setNodeCPUConf -- set node's CPU configuration
# SYNOPSIS
#   setNodeCPUConf $node_id $param_list
# FUNCTION
#   Sets the node's CPU scheduling parameters.
# INPUTS
#   * node_id -- node id
#   * param_list -- node's CPU scheduling parameters { minp maxp weight }
#****
proc setNodeCPUConf { node_id param_list } {
    cfgSet "nodes" $node_id "cpu" $param_list
}

proc getAutoDefaultRoutesStatus { node_id } {
    return [cfgGetWithDefault "enabled" "nodes" $node_id "auto_default_routes"]
}

proc setAutoDefaultRoutesStatus { node_id state } {
    cfgSet "nodes" $node_id "auto_default_routes" $state

    if { [getCustomEnabled $node_id] == "true" } {
	return
    }

    trigger_nodeReconfig $node_id
}

#****f* nodecfg.tcl/removeNode
# NAME
#   removeNode -- removes the node
# SYNOPSIS
#   removeNode $node_id
# FUNCTION
#   Removes the specified node as well as all the links binding that node to
#   the other nodes.
# INPUTS
#   * node_id -- node id
#****
proc removeNode { node_id { keep_other_ifaces 0 } } {
    trigger_nodeDestroy $node_id

    global nodeNamingBase

    if { [getCustomIcon $node_id] != "" } {
	removeImageReference [getCustomIcon $node_id] $node_id
    }

    foreach iface_id [ifcList $node_id] {
	removeIface $node_id $iface_id
    }

    setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]

    set node_type [getNodeType $node_id]
    if { $node_type in [array names nodeNamingBase] } {
	recalculateNumType $node_type $nodeNamingBase($node_type)
    }

    cfgUnset "nodes" $node_id
    if { [getFromRunning "${node_id}_running"] == "true" } {
	setToRunning "${node_id}_running" delete
    } else {
	unsetRunning "${node_id}_running"
    }
}
#****f* nodecfg.tcl/getNodeCanvas
# NAME
#   getNodeCanvas -- get node canvas id
# SYNOPSIS
#   set canvas [getNodeCanvas $node_id]
# FUNCTION
#   Returns node's canvas affinity.
# INPUTS
#   * node_id -- node id
# RESULT
#   * canvas -- canvas id
#****
proc getNodeCanvas { node_id } {
    return [cfgGet "nodes" $node_id "canvas"]
}

#****f* nodecfg.tcl/setNodeCanvas
# NAME
#   setNodeCanvas -- set node canvas
# SYNOPSIS
#   setNodeCanvas $node_id $canvas
# FUNCTION
#   Sets node's canvas affinity.
# INPUTS
#   * node_id -- node id
#   * canvas -- canvas id
#****
proc setNodeCanvas { node_id canvas_id } {
    cfgSet "nodes" $node_id "canvas" $canvas_id
}

#****f* nodecfg.tcl/newNode
# NAME
#   newNode -- new node
# SYNOPSIS
#   set node_id [newNode $type]
# FUNCTION
#   Returns the node id of a new node of the specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * node_id -- node id of a new node of the specified type
#****
proc newNode { type } {
    set cfg_deployed [getFromRunning "cfg_deployed"]

    global viewid
    catch { unset viewid }

    set node_list [getFromRunning "node_list"]
    set node_id ""
    while { $node_id == "" } {
	set node_id [newObjectId $node_list "n"]
	if { [getFromRunning "${node_id}_running"] != "" } {
	    lappend node_list $node_id
	    set node_id ""
	}
    }

    setNodeType $node_id $type
    if { $type != "pseudo" } {
	setToRunning "${node_id}_running" false
    }

    lappendToRunning "node_list" $node_id

    if { [info procs $type.confNewNode] == "$type.confNewNode" } {
	$type.confNewNode $node_id
    }

    return $node_id
}

#****f* nodecfg.tcl/getNodeMirror
# NAME
#   getNodeMirror -- get node mirror
# SYNOPSIS
#   set mirror_node_id [getNodeMirror $node_id]
# FUNCTION
#   Returns the node id of a mirror pseudo node of the node. Mirror node is
#   the corresponding pseudo node. The pair of pseudo nodes, node and his
#   mirror node, are introduced to form a split in a link. This split can be
#   used for avoiding crossed links or for displaying a link between the nodes
#   on a different canvas.
# INPUTS
#   * node_id -- node id
# RESULT
#   * mirror_node_id -- node id of a mirror node
#****
proc getNodeMirror { node_id } {
    return [cfgGet "nodes" $node_id "mirror"]
}

#****f* nodecfg.tcl/setNodeMirror
# NAME
#   setNodeMirror -- set node mirror
# SYNOPSIS
#   setNodeMirror $node_id $value
# FUNCTION
#   Sets the node id of a mirror pseudo node of the specified node. Mirror
#   node is the corresponding pseudo node. The pair of pseudo nodes, node and
#   his mirror node, are introduced to form a split in a link. This split can
#   be used for avoiding crossed links or for displaying a link between the
#   nodes on a different canvas.
# INPUTS
#   * node_id -- node id
#   * value -- node id of a mirror node
#****
proc setNodeMirror { node_id value } {
    cfgSet "nodes" $node_id "mirror" $value
}

#****f* nodecfg.tcl/getNodeProtocolRip
# NAME
#   getNodeProtocolRip
# SYNOPSIS
#   getNodeProtocolRip $node_id
# FUNCTION
#   Checks if node's current protocol is rip.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- 1 if it is rip, otherwise 0
#****
proc getNodeProtocol { node_id protocol } {
    return [cfgGetWithDefault 0 "nodes" $node_id "router_config" $protocol]
}

proc setNodeProtocol { node_id protocol state } {
    cfgSet "nodes" $node_id "router_config" $protocol $state

    # TODO?
    trigger_nodeRecreate $node_id
}

#****f* nodecfg.tcl/getNodeProtocolRipng
# NAME
#   getNodeProtocolRipng
# SYNOPSIS
#   getNodeProtocolRipng $node_id
# FUNCTION
#   Checks if node's current protocol is ripng.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- 1 if it is ripng, otherwise 0
#****

#****f* nodecfg.tcl/getNodeProtocolOspfv2
# NAME
#   getNodeProtocolOspfv2
# SYNOPSIS
#   getNodeProtocolOspfv2 $node_id
# FUNCTION
#   Checks if node's current protocol is ospfv2.
# INPUTS
#   * node_id -- node id
# RESULT
#   * check -- 1 if it is ospfv2, otherwise 0
#****

proc getRouterInterfaceCfg { node_id } {
    set ospf_enabled [getNodeProtocol $node_id "ospf"]
    set ospf6_enabled [getNodeProtocol $node_id "ospf6"]

    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    foreach iface_id [allIfcList $node_id] {
		lappend cfg "interface [getIfcName $node_id $iface_id]"

		set addrs [getIfcIPv4addrs $node_id $iface_id]
		foreach addr $addrs {
		    if { $addr != "" } {
			lappend cfg " ip address $addr"
		    }
		}

		if { $ospf_enabled } {
		    if { ! [isIfcLogical $node_id $iface_id] } {
			lappend cfg " ip ospf area 0.0.0.0"
		    }
		}

		set addrs [getIfcIPv6addrs $node_id $iface_id]
		foreach addr $addrs {
		    if { $addr != "" } {
			lappend cfg " ipv6 address $addr"
		    }
		}

		if { $model == "frr" && $ospf6_enabled } {
		    if { ! [isIfcLogical $node_id $iface_id] } {
			lappend cfg " ipv6 ospf6 area 0.0.0.0"
		    }
		}

		if { [getIfcOperState $node_id $iface_id] == "down" } {
		    lappend cfg " shutdown"
		}

		lappend cfg "!"
	    }
	}
	"static" {
	    foreach iface_id [allIfcList $node_id] {
		set cfg [concat $cfg [nodeCfggenIfcIPv4 $node_id $iface_id]]
		set cfg [concat $cfg [nodeCfggenIfcIPv6 $node_id $iface_id]]
	    }
	}
    }

    return $cfg
}

proc getRouterProtocolCfg { node_id protocol } {
    setToRunning "${node_id}_old_$protocol" [getNodeProtocol $node_id $protocol]
    if { [getNodeProtocol $node_id $protocol] == 0 } {
	return ""
    }

    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set router_id [ip::intToString [expr 1 + [string trimleft $node_id "n"]]]
	    switch -exact -- $protocol {
		"rip" {
		    lappend cfg "router rip"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute ospf"
		    lappend cfg " network 0.0.0.0/0"
		    lappend cfg "!"
		}
		"ripng" {
		    lappend cfg "router ripng"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute ospf6"
		    lappend cfg " network ::/0"
		    lappend cfg "!"
		}
		"ospf" {
		    lappend cfg "router ospf"
		    lappend cfg " ospf router-id $router_id"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute rip"
		    lappend cfg "!"
		}
		"ospf6" {
		    if { $model == "quagga" } {
			set id_string "router-id $router_id"
			#set area_string "network ::/0 area 0.0.0.0"
		    } else {
			set id_string "ospf6 router-id $router_id"
			#set area_string "area 0.0.0.0 range ::/0"
		    }

		    lappend cfg "router ospf6"
		    lappend cfg " $id_string"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg " redistribute ripng"

		    if { $model == "quagga" } {
			foreach iface_id [ifcList $node_id] {
			    lappend cfg " interface $iface_id area 0.0.0.0"
			}
		    }

		    lappend cfg "!"
		}
		"bgp" {
		    set loopback_ipv4 [lindex [split [getIfcIPv4addr $node_id "lo0" ] "/"] 0]
		    lappend cfg "router bgp 1000"
		    lappend cfg " bgp router-id $loopback_ipv4"
		    lappend cfg " no bgp ebgp-requires-policy"
		    lappend cfg " neighbor DEFAULT peer-group"
		    lappend cfg " neighbor DEFAULT remote-as 1000"
		    lappend cfg " neighbor DEFAULT update-source $loopback_ipv4"
		    lappend cfg " redistribute static"
		    lappend cfg " redistribute connected"
		    lappend cfg "!"
		}
	    }

	    lappend cfg "__EOF__"
	}
	"static" {
	    # nothing to return
	}
    }


    return $cfg
}

proc getRouterProtocolUnconfig { node_id protocol } {
    if { [getFromRunning "${node_id}_old_$protocol"] == 0 } {
	return ""
    }

    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set router_id [ip::intToString [expr 1 + [string trimleft $node_id "n"]]]
	    switch -exact -- $protocol {
		"rip" {
		    lappend cfg "no router rip"
		}
		"ripng" {
		    lappend cfg "no router ripng"
		}
		"ospf" {
		    lappend cfg "no router ospf"
		}
		"ospf6" {
		    lappend cfg "no router ospf6"

		    if { $model == "quagga" } {
			foreach iface [ifcList $node_id] {
			    lappend cfg " no interface $iface area 0.0.0.0"
			}
		    }

		    lappend cfg "!"
		}
		"bgp" {
		    lappend cfg "no router bgp 1000"
		}
	    }

	    lappend cfg "__EOF__"
	}
	"static" {
	    # nothing to return
	}
    }


    return $cfg
}

proc routerRoutesCfggen { node_id } {
    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set cfg [concat $cfg [nodeCfggenStaticRoutes4 $node_id 1]]
	    set cfg [concat $cfg [nodeCfggenStaticRoutes6 $node_id 1]]

	    lappend cfg "!"
	    lappend cfg "__EOF__"

	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set cfg [concat $cfg [nodeCfggenAutoRoutes4 $node_id 1]]
	    set cfg [concat $cfg [nodeCfggenAutoRoutes6 $node_id 1]]

	    lappend cfg "!"
	    lappend cfg "__EOF__"
	}
	"static" {
	    set cfg [concat $cfg [nodeCfggenStaticRoutes4 $node_id]]
	    set cfg [concat $cfg [nodeCfggenStaticRoutes6 $node_id]]

	    lappend cfg ""

	    set cfg [concat $cfg [nodeCfggenAutoRoutes4 $node_id]]
	    set cfg [concat $cfg [nodeCfggenAutoRoutes6 $node_id]]

	    lappend cfg ""
	}
    }

    return $cfg
}

proc routerRoutesUncfggen { node_id } {
    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id 1]]
	    set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id 1]]

	    lappend cfg "!"
	    lappend cfg "__EOF__"

	    lappend cfg "vtysh << __EOF__"
	    lappend cfg "conf term"

	    set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id 1]]
	    set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id 1]]

	    lappend cfg "!"
	    lappend cfg "__EOF__"
	}
	"static" {
	    set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id]]
	    set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id]]

	    lappend cfg ""

	    set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id]]
	    set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id]]

	    lappend cfg ""
	}
    }

    return $cfg
}

#****f* nodecfg.tcl/setNodeType
# NAME
#   setNodeType -- set node's type.
# SYNOPSIS
#   setNodeType $node_id $type
# FUNCTION
#   Sets node's type.
# INPUTS
#   * node_id -- node id
#   * type -- type of node
#****
proc setNodeType { node_id type } {
    cfgSet "nodes" $node_id "type" $type

    if { $type == "pseudo" } {
	return
    }

    trigger_nodeRecreate $node_id
}

#****f* nodecfg.tcl/registerModule
# NAME
#   registerModule -- register module
# SYNOPSIS
#   registerModule $module
# FUNCTION
#   Adds a module to all_modules_list.
# INPUTS
#   * module -- module to add
#****
proc registerModule { module } {
    global all_modules_list

    lappend all_modules_list $module
}

#****f* nodecfg.tcl/deregisterModule
# NAME
#   deregisterModule -- deregister module
# SYNOPSIS
#   deregisterModule $module
# FUNCTION
#   Removes a module from all_modules_list.
# INPUTS
#   * module -- module to remove
#****
proc deregisterModule { module } {
    global all_modules_list

    set all_modules_list [removeFromList $all_modules_list $module]
}

#****f* nodecfg.tcl/getEtherVlanEnabled
# NAME
#   getEtherVlanEnabled -- get node rj45 vlan.
# SYNOPSIS
#   set state [getEtherVlanEnabled $node_id]
# FUNCTION
#   Returns whether the rj45 node is vlan enabled.
# INPUTS
#   * node_id -- node id
# RESULT
#   * state -- vlan enabled
#****
proc getEtherVlanEnabled { node_id } {
    return [cfgGetWithDefault 0 "nodes" $node_id "vlan" "enabled"]
}

#****f* nodecfg.tcl/setEtherVlanEnabled
# NAME
#   setEtherVlanEnabled -- set node rj45 vlan.
# SYNOPSIS
#   setEtherVlanEnabled $node_id $state
# FUNCTION
#   Sets rj45 node vlan setting.
# INPUTS
#   * node -- node id
#   * state -- vlan enabled
#****
proc setEtherVlanEnabled { node_id state } {
    cfgSet "nodes" $node_id "vlan" "enabled" $state
}

#****f* nodecfg.tcl/getEtherVlanTag
# NAME
#   getEtherVlanTag -- get node rj45 vlan tag.
# SYNOPSIS
#   set tag [getEtherVlanTag $node_id]
# FUNCTION
#   Returns rj45 node vlan tag.
# INPUTS
#   * node_id -- node id
# RESULT
#   * tag -- vlan tag
#****
proc getEtherVlanTag { node_id } {
    return [cfgGetWithDefault 1 "nodes" $node_id "vlan" "tag"]
}

#****f* nodecfg.tcl/setEtherVlanTag
# NAME
#   setEtherVlanTag -- set node rj45 vlan tag.
# SYNOPSIS
#   setEtherVlanTag $node_id $value
# FUNCTION
#   Sets rj45 node vlan tag.
# INPUTS
#   * node -- node id
#   * value -- vlan tag
#****
proc setEtherVlanTag { node_id tag } {
    cfgSet "nodes" $node_id "vlan" "tag" $tag
}

#****f* nodecfg.tcl/getNodeServices
# NAME
#   getNodeServices -- get node active services.
# SYNOPSIS
#   set services [getNodeServices $node_id]
# FUNCTION
#   Returns node's selected services.
# INPUTS
#   * node_id -- node id
# RESULT
#   * services -- active services
#****
proc getNodeServices { node_id } {
    return [cfgGet "nodes" $node_id "services"]
}

#****f* nodecfg.tcl/setNodeServices
# NAME
#   setNodeServices -- set node active services.
# SYNOPSIS
#   setNodeServices $node_id $services
# FUNCTION
#   Sets node selected services.
# INPUTS
#   * node_id -- node id
#   * services -- list of services
#****
proc setNodeServices { node_id services } {
    cfgSet "nodes" $node_id "services" $services
}

#****f* nodecfg.tcl/getNodeCustomImage
# NAME
#   getNodeCustomImage -- get node custom image.
# SYNOPSIS
#   set value [getNodeCustomImage $node_id]
# FUNCTION
#   Returns node custom image setting.
# INPUTS
#   * node_id -- node id
# RESULT
#   * status -- custom image identifier
#****
proc getNodeCustomImage { node_id } {
    return [cfgGet "nodes" $node_id "custom_image"]
}

#****f* nodecfg.tcl/setNodeCustomImage
# NAME
#   setNodeCustomImage -- set node custom image.
# SYNOPSIS
#   setNodeCustomImage $node_id $img
# FUNCTION
#   Sets node custom image.
# INPUTS
#   * node_id -- node id
#   * img -- image identifier
#****
proc setNodeCustomImage { node_id img } {
    cfgSet "nodes" $node_id "custom_image" $img

    trigger_nodeRecreate $node_id
}

#****f* nodecfg.tcl/getNodeDockerAttach
# NAME
#   getNodeDockerAttach -- get node docker ext iface attach.
# SYNOPSIS
#   set value [getNodeDockerAttach $node_id]
# FUNCTION
#   Returns node docker ext iface attach setting.
# INPUTS
#   * node_id -- node id
# RESULT
#   * status -- attach enabled
#****
proc getNodeDockerAttach { node_id } {
    return [cfgGetWithDefault "false" "nodes" $node_id "docker_attach"]
}

#****f* nodecfg.tcl/setNodeDockerAttach
# NAME
#   setNodeDockerAttach -- set node docker ext iface attach.
# SYNOPSIS
#   setNodeDockerAttach $node_id $state
# FUNCTION
#   Sets node docker ext iface attach status.
# INPUTS
#   * node_id -- node id
#   * state -- attach status
#****
proc setNodeDockerAttach { node_id state } {
    cfgSet "nodes" $node_id "docker_attach" $state

    trigger_nodeRecreate $node_id
}

#****f* nodecfg.tcl/getNodeIPsec
# NAME
#   getNodeIPsec -- retreives IPsec configuration for selected node
# SYNOPSIS
#   getNodeIPsec $node_id
# FUNCTION
#   Retreives all IPsec connections for current node
# INPUTS
#   node - node id
#****
proc getNodeIPsec { node_id } {
    return [cfgGet "nodes" $node_id "ipsec" "ipsec_configs"]
}

proc setNodeIPsec { node_id new_value } {
    cfgSet "nodes" $node_id "ipsec" "ipsec_configs" $new_value
}

#****f* nodecfg.tcl/getNodeIPsecItem
# NAME
#   getNodeIPsecItem -- get node IPsec item
# SYNOPSIS
#   getNodeIPsecItem $node_id $item
# FUNCTION
#   Retreives an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc getNodeIPsecItem { node_id item } {
    return [cfgGet "nodes" $node_id "ipsec" $item]
}

#****f* nodecfg.tcl/setNodeIPsecItem
# NAME
#   setNodeIPsecItem -- set node IPsec item
# SYNOPSIS
#   setNodeIPsecItem $node $item
# FUNCTION
#   Sets an item from IPsec configuration of given node
# INPUTS
#   node - node id
#   item - search item
proc setNodeIPsecItem { node_id item new_value } {
    cfgSet "nodes" $node_id "ipsec" $item $new_value

    # TODO: check services
    trigger_nodeRecreate $node_id
}

proc setNodeIPsecConnection { node_id connection new_value } {
    cfgSet "nodes" $node_id "ipsec" "ipsec_configs" $connection $new_value

    # TODO: check services
    trigger_nodeRecreate $node_id
}

proc delNodeIPsecConnection { node_id connection } {
    cfgUnset "nodes" $node_id "ipsec" "ipsec_configs" $connection

    if { $connection != "%default" } {
	# TODO: check services
	trigger_nodeRecreate $node_id
    }
}

proc getNodeIPsecSetting { node_id connection setting } {
    return [cfgGet "nodes" $node_id "ipsec" "ipsec_configs" $connection $setting]
}

proc setNodeIPsecSetting { node_id connection setting new_value } {
    cfgSet "nodes" $node_id "ipsec" "ipsec_configs" $connection $setting $new_value
}

proc getNodeIPsecConnList { node_id } {
    return [dict keys [cfgGet "nodes" $node_id "ipsec" "ipsec_configs"]]
}

#****f* nodecfg.tcl/getAllNodesType
# NAME
#   getAllNodesType -- get list of all nodes of a certain type
# SYNOPSIS
#   getAllNodesType $type
# FUNCTION
#   Passes through the list of all nodes and returns a list of nodes of the
#   specified type.
# INPUTS
#   * type -- node type
# RESULT
#   * list -- list of all nodes of the type
#****
proc getAllNodesType { type } {
    set type_list ""
    foreach node_id [getFromRunning "node_list"] {
	if { [string match "$type*" [getNodeType $node_id]] } {
	    lappend type_list $node_id
	}
    }

    return $type_list
}

#****f* nodecfg.tcl/getNewNodeNameType
# NAME
#   getNewNodeNameType -- get a new node name for a certain type
# SYNOPSIS
#   getNewNodeNameType $type $namebase
# FUNCTION
#   Returns a new node name for the type and namebase, e.g. pc0 for pc.
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
# RESULT
#   * name -- new node name to be assigned
#****
proc getNewNodeNameType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    #if the variable pcnodes isn't set we need to check through all the nodes
    #to assign a non duplicate name
    if { ! [info exists num$type] } {
	recalculateNumType $type $namebase
    }

    incr num$type

    return $namebase[set num$type]
}

#****f* nodecfg.tcl/recalculateNumType
# NAME
#   recalculateNumType -- recalculate number for type
# SYNOPSIS
#   recalculateNumType $type $namebase
# FUNCTION
#   Calculates largest number for the given type
# INPUTS
#   * type -- node type
#   * namebase -- base for the node name
#****
proc recalculateNumType { type namebase } {
    upvar 0 ::cf::[set ::curcfg]::num$type num$type

    set num$type 0
    foreach node_id [getAllNodesType $type] {
	set name [getNodeName $node_id]
	if { [string match "$namebase*" $name] } {
	    set rest [string trimleft $name $namebase]
	    if { [string is integer $rest] && $rest > [set num$type] } {
		set num$type $rest
	    }
	}
    }
}

#****f* nodecfg.tcl/transformNodes
# NAME
#   transformNodes -- change nodes' types
# SYNOPSIS
#   transformNodes $nodes $to_type
# FUNCTION
#   Changes nodes' type and configuration. Conversion is possible between router
#   on the one side, and the pc or host on the other side.
# INPUTS
#   * nodes -- node ids
#   * to_type -- new type of node
#****
proc transformNodes { nodes to_type } {
    global routerRipEnable routerRipngEnable routerOspfEnable routerOspf6Enable
    global rdconfig routerDefaultsModel
    global changed

    lassign $rdconfig ripEnable ripngEnable ospfEnable ospf6Enable bgpEnable

    foreach node_id $nodes {
	if { [[getNodeType $node_id].netlayer] == "NETWORK" } {
	    set from_type [getNodeType $node_id]

	    # replace type
	    setNodeType $node_id $to_type

	    if { $to_type == "pc" || $to_type == "host" } {
		if { $from_type == "router" } {
		    setNodeModel $node_id {}
		    cfgUnset "nodes" $node_id "router_config"
		}

		set changed 1
	    } elseif { $from_type != "router" && $to_type == "router" } {
		setNodeModel $node_id $routerDefaultsModel
		if { $routerDefaultsModel != "static" } {
		    setNodeProtocol $node_id "rip" $ripEnable
		    setNodeProtocol $node_id "ripng" $ripngEnable
		    setNodeProtocol $node_id "ospf" $ospfEnable
		    setNodeProtocol $node_id "ospf6" $ospf6Enable
		    setNodeProtocol $node_id "bgp" $bgpEnable
		}

		set changed 1
	    }
	}
    }
}

proc getNodeFromHostname { hostname } {
    foreach node_id [getFromRunning "node_list"] {
	if { $hostname == [getNodeName $node_id] } {
	    return $node_id
	}
    }

    return ""
}

#****f* nodecfg.tcl/getLocalIpAddress
# NAME
#   getLocalIpAddress -- retreives local IP addresses for current node
# SYNOPSIS
#   getLocalIpAddress $node
# FUNCTION
#   Retreives all local addresses (IPv4 and IPv6) for current node
# INPUTS
#   node - node id
#****
proc getAllIpAddresses { node } {
    set ifaces_list [ifcList $node]
    foreach logifc [logIfcList $node] {
	if { [string match "vlan*" $logifc]} {
	    lappend ifaces_list $logifc
	}
    }

    set ipv4_list ""
    set ipv6_list ""
    foreach item $ifaces_list {
	set ifcIP [getIfcIPv4addr $node $item]
	if { $ifcIP != "" } {
	    lappend ipv4_list $ifcIP
	}

	set ifcIP [getIfcIPv6addr $node $item]
	if { $ifcIP != "" } {
	    lappend ipv6_list $ifcIP
	}
    }

    return "\"$ipv4_list\" \"$ipv6_list\""
}

#****f* nodecfg.tcl/pseudo.netlayer
# NAME
#   pseudo.netlayer -- pseudo layer
# SYNOPSIS
#   set layer [pseudo.netlayer]
# FUNCTION
#   Returns the layer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * layer -- returns an empty string
#****
proc pseudo.netlayer {} {
}

#****f* nodecfg.tcl/pseudo.virtlayer
# NAME
#   pseudo.virtlayer -- pseudo virtlayer
# SYNOPSIS
#   set virtlayer [pseudo.virtlayer]
# FUNCTION
#   Returns the virtlayer on which the pseudo node operates
#   i.e. returns no layer.
# RESULT
#   * virtlayer -- returns an empty string
#****
proc pseudo.virtlayer {} {
}

proc nodeCfggenStaticRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    set croutes4 [getStatIPv4routes $node_id]
    setToRunning "${node_id}_old_croutes4" $croutes4
    foreach statrte $croutes4 {
	if { $vtysh } {
	    lappend cfg "ip route $statrte"
	} else {
	    lappend cfg [getIPv4RouteCmd $statrte]
	}
    }

    return $cfg
}

proc nodeUncfggenStaticRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    foreach statrte [getFromRunning "${node_id}_old_croutes4"] {
	if { $vtysh } {
	    lappend cfg "no ip route $statrte"
	} else {
	    lappend cfg [getRemoveIPv4RouteCmd $statrte]
	}
    }
    unsetRunning "${node_id}_old_croutes4"

    return $cfg
}

proc nodeCfggenAutoRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes4 [getDefaultIPv4routes $node_id]
    setToRunning "${node_id}_old_default_routes4" $default_routes4
    foreach statrte $default_routes4 {
	if { $vtysh } {
	    lappend cfg "ip route $statrte"
	} else {
	    lappend cfg [getIPv4RouteCmd $statrte]
	}
    }
    setDefaultIPv4routes $node_id {}

    return $cfg
}

proc nodeUncfggenAutoRoutes4 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes4 [getFromRunning "${node_id}_old_default_routes4"]
    foreach statrte $default_routes4 {
	if { $vtysh } {
	    lappend cfg "no ip route $statrte"
	} else {
	    lappend cfg [getRemoveIPv4RouteCmd $statrte]
	}
    }
    setDefaultIPv4routes $node_id {}
    unsetRunning "${node_id}_old_default_routes4"

    return $cfg
}

proc nodeCfggenAutoRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes6 [getDefaultIPv6routes $node_id]
    setToRunning "${node_id}_old_default_routes6" $default_routes6
    foreach statrte $default_routes6 {
	if { $vtysh } {
	    lappend cfg "ipv6 route $statrte"
	} else {
	    lappend cfg [getIPv6RouteCmd $statrte]
	}
    }
    setDefaultIPv6routes $node_id {}

    return $cfg
}

proc nodeUncfggenAutoRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    set default_routes6 [getFromRunning "${node_id}_old_default_routes6"]
    foreach statrte $default_routes6 {
	if { $vtysh } {
	    lappend cfg "no ipv6 route $statrte"
	} else {
	    lappend cfg [getRemoveIPv6RouteCmd $statrte]
	}
    }
    setDefaultIPv6routes $node_id {}
    unsetRunning "${node_id}_old_default_routes6"

    return $cfg
}

proc nodeCfggenStaticRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    set croutes6 [getStatIPv6routes $node_id]
    setToRunning "${node_id}_old_croutes6" $croutes6
    foreach statrte $croutes6 {
	if { $vtysh } {
	    lappend cfg "ipv6 route $statrte"
	} else {
	    lappend cfg [getIPv6RouteCmd $statrte]
	}
    }

    return $cfg
}

proc nodeUncfggenStaticRoutes6 { node_id { vtysh 0 } } {
    set cfg {}

    foreach statrte [getFromRunning "${node_id}_old_croutes6"] {
	if { $vtysh } {
	    lappend cfg "no ipv6 route $statrte"
	} else {
	    lappend cfg [getRemoveIPv6RouteCmd $statrte]
	}
    }
    unsetRunning "${node_id}_old_croutes6"

    return $cfg
}

proc updateNode { node_id old_node_cfg new_node_cfg } {
    puts ""
    puts "= /UPDATE NODE $node_id START ="

    if { $old_node_cfg == "*" } {
	set old_node_cfg [cfgGet "nodes" $node_id]
    }

    set cfg_diff [dictDiff $old_node_cfg $new_node_cfg]
    puts "= cfg_diff: '$cfg_diff'"
    if { $cfg_diff == "" || [lsort -uniq [dict values $cfg_diff]] == "copy" } {
	puts "= NO CHANGE"
	puts "= /UPDATE NODE $node_id END ="
	return $new_node_cfg
    }

    set eid [getFromRunning "eid"]

    set commands {}

    if { $new_node_cfg == "" } {
	return $old_node_cfg
    }

    dict for {key change} $cfg_diff {
	if { $change == "copy" } {
	    continue
	}

	puts "==== $change: '$key'"

	set old_value [_cfgGet $old_node_cfg $key]
	set new_value [_cfgGet $new_node_cfg $key]
	if { $change in "changed" } {
	    puts "==== OLD: '$old_value'"
	}
	if { $change in "new changed" } {
	    puts "==== NEW: '$new_value'"
	}

	switch -exact $key {
	    "name" {
		setNodeName $node_id $new_value
	    }

	    "custom_image" {
		setNodeCustomImage $node_id $new_value
	    }

	    "docker_attach" {
		setNodeDockerAttach $node_id $new_value
	    }

	    "croutes4" {
		setStatIPv4routes $node_id $new_value
	    }

	    "croutes6" {
		setStatIPv6routes $node_id $new_value
	    }

	    "auto_default_routes" {
		setAutoDefaultRoutesStatus $node_id $new_value
	    }

	    "services" {
		setNodeServices $node_id $new_value
	    }

	    "custom_configs" {
		set custom_configs_diff [dictDiff $old_value $new_value]
		dict for {custom_configs_key custom_configs_change} $custom_configs_diff {
		    if { $custom_configs_change == "copy" } {
			continue
		    }

		    puts "======== $custom_configs_change: '$custom_configs_key'"

		    set custom_configs_old_value [_cfgGet $old_value $custom_configs_key]
		    set custom_configs_new_value [_cfgGet $new_value $custom_configs_key]
		    if { $custom_configs_change in "changed" } {
			puts "======== OLD: '$custom_configs_old_value'"
		    }
		    if { $custom_configs_change in "new changed" } {
			puts "======== NEW: '$custom_configs_new_value'"
		    }

		    lassign [dict values $custom_configs_new_value] cmd cfg
		    setCustomConfig $node_id $custom_configs_key $cmd $cfg
		}
	    }

	    "ipsec" {
		set ipsec_diff [dictDiff $old_value $new_value]
		dict for {ipsec_key ipsec_change} $ipsec_diff {
		    if { $ipsec_change == "copy" } {
			continue
		    }

		    puts "======== $ipsec_change: '$ipsec_key'"

		    set ipsec_old_value [_cfgGet $old_value $ipsec_key]
		    set ipsec_new_value [_cfgGet $new_value $ipsec_key]
		    if { $ipsec_change in "changed" } {
			puts "======== OLD: '$ipsec_old_value'"
		    }
		    if { $ipsec_change in "new changed" } {
			puts "======== NEW: '$ipsec_new_value'"
		    }

		    switch -exact $ipsec_key {
			"ipsec_logging" {
			    setNodeIPsecItem $node_id "ipsec_logging" $ipsec_new_value
			}

			"ipsec_configs" {
			    set ipsec_configs_diff [dictDiff $ipsec_old_value $ipsec_new_value]
			    dict for {ipsec_configs_key ipsec_configs_change} $ipsec_configs_diff {
				if { $ipsec_configs_change == "copy" } {
				    continue
				}

				puts "============ $ipsec_configs_change: '$ipsec_configs_key'"

				set ipsec_configs_old_value [_cfgGet $ipsec_old_value $ipsec_configs_key]
				set ipsec_configs_new_value [_cfgGet $ipsec_new_value $ipsec_configs_key]
				if { $ipsec_configs_change in "changed" } {
				    puts "============ OLD: '$ipsec_configs_old_value'"
				}
				if { $ipsec_configs_change in "new changed" } {
				    puts "============ NEW: '$ipsec_configs_new_value'"
				}

				switch -exact $ipsec_configs_change {
				    "removed" {
					delNodeIPsecConnection $node_id $ipsec_configs_key
				    }

				    "new" -
				    "changed" {
					setNodeIPsecConnection $node_id $ipsec_configs_key $ipsec_configs_new_value
				    }
				}
			    }
			}
		    }
		}
	    }

	    "nat64" {
		set nat64_diff [dictDiff $old_value $new_value]
		dict for {nat64_key nat64_change} $nat64_diff {
		    if { $nat64_change == "copy" } {
			continue
		    }

		    puts "======== $nat64_change: '$nat64_key'"

		    set nat64_old_value [_cfgGet $old_value $nat64_key]
		    set nat64_new_value [_cfgGet $new_value $nat64_key]
		    if { $nat64_change in "changed" } {
			puts "======== OLD: '$nat64_old_value'"
		    }
		    if { $nat64_change in "new changed" } {
			puts "======== NEW: '$nat64_new_value'"
		    }

		    switch -exact $nat64_key {
			"tun_ipv4_addr" {
			    setTunIPv4Addr $node_id $nat64_new_value
			}

			"tun_ipv6_addr" {
			    setTunIPv6Addr $node_id $nat64_new_value
			}

			"tayga_ipv4_addr" {
			    setTaygaIPv4Addr $node_id $nat64_new_value
			}

			"tayga_ipv6_prefix" {
			    setTaygaIPv6Prefix $node_id $nat64_new_value
			}

			"tayga_ipv4_pool" {
			    setTaygaIPv4DynPool $node_id $nat64_new_value
			}

			"tayga_mappings" {
			    setTaygaMappings $node_id $nat64_new_value
			}
		    }
		}
	    }

	    "custom_enabled" {
		setCustomEnabled $node_id $new_value
	    }

	    "custom_selected" {
		setCustomConfigSelected $node_id $new_value
	    }

	    "canvas" {
		setNodeCanvas $node_id $new_value
	    }

	    "iconcoords" {
		setNodeCoords $node_id $new_value
	    }

	    "labelcoords" {
		setNodeLabelCoords $node_id $new_value
	    }

	    "events" {
		# TODO
	    }

	    "custom_icon" {
		setCustomIcon $node_id $new_value
	    }

	    "ifaces" {
		set ifaces_diff [dictDiff $old_value $new_value]
		dict for {iface_key iface_change} $ifaces_diff {
		    if { $iface_change == "copy" } {
			continue
		    }

		    puts "======== $iface_change: '$iface_key'"

		    set iface_old_value [_cfgGet $old_value $iface_key]
		    set iface_new_value [_cfgGet $new_value $iface_key]
		    if { $iface_change in "changed" } {
			puts "======== OLD: '$iface_old_value'"
		    }
		    if { $iface_change in "new changed" } {
			puts "======== NEW: '$iface_new_value'"
		    }

		    switch -exact $iface_change {
			"removed" {
			    removeIface $node_id $iface_key
			}

			"new" -
			"changed" {
			    set iface_type [_cfgGet $iface_new_value "type"]
			    if { $iface_change == "new" } {
				if { [string match "lifc*" $iface_key] } {
				    set iface_id [newLogIface $node_id $iface_type]
				} else {
				    set iface_id [newIface $node_id $iface_type 0]
				}
			    } else {
				set iface_id $iface_key
			    }

			    set iface_diff [dictDiff $iface_old_value $iface_new_value]
			    dict for {iface_prop_key iface_prop_change} $iface_diff {
				if { $iface_prop_change == "copy" } {
				    continue
				}

				set iface_prop_old_value [_cfgGet $iface_old_value $iface_prop_key]
				set iface_prop_new_value [_cfgGet $iface_new_value $iface_prop_key]
				puts "============ $iface_prop_change: '$iface_prop_key'"
				if { $iface_prop_change in "changed" } {
				    puts "============ OLD: '$iface_prop_old_value'"
				}
				if { $iface_prop_change in "new changed" } {
				    puts "============ NEW: '$iface_prop_new_value'"
				}

				switch -exact $iface_prop_key {
				    "link" {
					# link cannot be changed, only removed
					if { $iface_prop_change == "removed" } {
					    removeLink $iface_prop_old_value 1
					}
				    }

				    "type" {
					setIfcType $node_id $iface_id $iface_prop_new_value
				    }

				    "name" {
					setIfcName $node_id $iface_id $iface_prop_new_value
				    }

				    "oper_state" {
					setIfcOperState $node_id $iface_id $iface_prop_new_value
				    }

				    "nat_state" {
					setIfcNatState $node_id $iface_id $iface_prop_new_value
				    }

				    "mtu" {
					setIfcMTU $node_id $iface_id $iface_prop_new_value
				    }

				    "ifc_qdisc" {
					setIfcQDisc $node_id $iface_id $iface_prop_new_value
				    }

				    "ifc_qdrop" {
					setIfcQDrop $node_id $iface_id $iface_prop_new_value
				    }

				    "queue_len" {
					setIfcQLen $node_id $iface_id $iface_prop_new_value
				    }

				    "vlan_dev" {
					setIfcVlanDev $node_id $iface_id $iface_prop_new_value
				    }

				    "vlan_tag" {
					setIfcVlanTag $node_id $iface_id $iface_prop_new_value
				    }

				    "mac" {
					if { $iface_prop_new_value == "auto" } {
					    autoMACaddr $node_id $iface_id
					} else {
					    setIfcMACaddr $node_id $iface_id $iface_prop_new_value
					}
				    }

				    "ipv4_addrs" {
					if { $iface_prop_new_value == "auto" } {
					    autoIPv4addr $node_id $iface_id
					} else {
					    setIfcIPv4addrs $node_id $iface_id $iface_prop_new_value
					}
				    }

				    "ipv6_addrs" {
					if { $iface_prop_new_value == "auto" } {
					    autoIPv6addr $node_id $iface_id
					} else {
					    setIfcIPv6addrs $node_id $iface_id $iface_prop_new_value
					}
				    }

				    "filter_rules" {
					clearFilterIfcRules $node_id $iface_id

					if { $iface_change != "removed" } {
					    foreach {rule_id rule_cfg} $iface_prop_new_value {
						addFilterIfcRule $node_id $iface_id $rule_id $rule_cfg
					    }
					}
				    }

				    "stp_discover" {
					setBridgeIfcDiscover $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_learn" {
					setBridgeIfcLearn $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_sticky" {
					setBridgeIfcSticky $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_private" {
					setBridgeIfcPrivate $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_snoop" {
					setBridgeIfcSnoop $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_enabled" {
					setBridgeIfcStp $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_edge" {
					setBridgeIfcEdge $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_autoedge" {
					setBridgeIfcAutoedge $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_ptp" {
					setBridgeIfcPtp $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_autoptp" {
					setBridgeIfcAutoptp $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_priority" {
					setBridgeIfcPriority $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_path_cost" {
					setBridgeIfcPathcost $node_id $iface_id $iface_prop_new_value
				    }

				    "stp_max_addresses" {
					setBridgeIfcMaxaddr $node_id $iface_id $iface_prop_new_value
				    }
				}
			    }
			}
		    }
		}
	    }

	    "packgen" {
		set packgen_diff [dictDiff $old_value $new_value]
		dict for {packets_key packets_change} $packgen_diff {
		    if { $packets_change == "copy" } {
			continue
		    }

		    puts "======== $packets_change: '$packets_key'"

		    set packets_old_value [_cfgGet $old_value $packets_key]
		    set packets_new_value [_cfgGet $new_value $packets_key]
		    if { $packets_change in "changed" } {
			puts "======== OLD: '$packets_old_value'"
		    }
		    if { $packets_change in "new changed" } {
			puts "======== NEW: '$packets_new_value'"
		    }

		    if { $packets_key == "packetrate" } {
			puts "setPackgenPacketRate $node_id $packets_new_value"
			setPackgenPacketRate $node_id $packets_new_value
			continue
		    }

		    set packets_diff [dictDiff $packets_old_value $packets_new_value]
		    foreach {packet_key packet_change} $packets_diff {
			if { $packet_change == "copy" } {
			    continue
			}

			puts "============ $packet_change: '$packet_key'"

			set packet_old_value [_cfgGet $packets_old_value $packet_key]
			set packet_new_value [_cfgGet $packets_new_value $packet_key]
			if { $packet_change in "changed" } {
			    puts "============ OLD: '$packet_old_value'"
			}
			if { $packet_change in "new changed" } {
			    puts "============ NEW: '$packet_new_value'"
			}

			switch -exact $packet_change {
			    "removed" {
				removePackgenPacket $node_id $packet_key
			    }

			    "new" {
				addPackgenPacket $node_id $packet_key $packet_new_value
			    }

			    "changed" {
				removePackgenPacket $node_id $packet_key
				addPackgenPacket $node_id $packet_key $packet_new_value
			    }
			}
		    }
		}
	    }

	    "bridge" {
		set bridge_diff [dictDiff $old_value $new_value]
		dict for {bridge_key bridge_change} $bridge_diff {
		    if { $bridge_change == "copy" } {
			continue
		    }

		    puts "======== $bridge_change: '$bridge_key'"

		    set bridge_old_value [_cfgGet $old_value $bridge_key]
		    set bridge_new_value [_cfgGet $new_value $bridge_key]
		    if { $bridge_change in "changed" } {
			puts "======== OLD: '$bridge_old_value'"
		    }
		    if { $bridge_change in "new changed" } {
			puts "======== NEW: '$bridge_new_value'"
		    }

		    switch -exact $bridge_key {
			"protocol" {
			    setBridgeProtocol $node_id $bridge_new_value
			}

			"priority" {
			    setBridgePriority $node_id $bridge_new_value
			}

			"hold_count" {
			    setBridgeHoldCount $node_id $bridge_new_value
			}

			"max_age" {
			    setBridgeMaxAge $node_id $bridge_new_value
			}

			"forwarding_delay" {
			    setBridgeFwdDelay $node_id $bridge_new_value
			}

			"hello_time" {
			    setBridgeHelloTime $node_id $bridge_new_value
			}

			"max_addresses" {
			    setBridgeMaxAddr $node_id $bridge_new_value
			}

			"address_timeout" {
			    setBridgeTimeout $node_id $bridge_new_value
			}
		    }
		}
	    }

	    default {
		# do nothing
	    }
	}
    }

    puts "= /UPDATE NODE $node_id END ="
    puts ""

    return $new_node_cfg
}
