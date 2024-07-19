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
# getDefaultGateways { node subnet_gws nodes_l2data }
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
# getCustomEnabled { node }
#
# setCustomEnabled { node state }
#
# getCustomConfigSelected { node }
#
# setCustomConfigSelected { node conf }
#
# getCustomConfig { node id }
#
# setCustomConfig { node id cmd config }
#
# removeCustomConfig { node id }
#
# getCustomConfigCommand { node id }
#
# getCustomConfigIDs { node }
#
#****

proc getNodeDir { node } {
    set node_dir [getNodeCustomImage $node]
    if { $node_dir == "" } {
	set node_dir [getVrootDir]/[getFromRunning "eid"]/$node
    }

    return $node_dir
}

#****f* nodecfg.tcl/getCustomEnabled
# NAME
#   getCustomEnabled -- get custom configuration enabled state
# SYNOPSIS
#   set enabled [getCustomEnabled $node]
# FUNCTION
#   For input node this procedure returns true if custom configuration is
#   enabled for the specified node.
# INPUTS
#   * node -- node id
# RESULT
#   * enabled -- returns true if custom configuration is enabled
#****
proc getCustomEnabled { node_id } {
    return [cfgGet "nodes" $node_id "custom_enabled"]
}

#****f* nodecfg.tcl/setCustomEnabled
# NAME
#   setCustomEnabled -- set custom configuration enabled state
# SYNOPSIS
#   setCustomEnabled $node $enabled
# FUNCTION
#   For input node this procedure enables or disables custom configuration.
# INPUTS
#   * node -- node id
#   * enabled -- true if enabling custom configuration, false if disabling
#****
proc setCustomEnabled { node_id state } {
    cfgSet "nodes" $node_id "custom_enabled" $state
}

#****f* nodecfg.tcl/getCustomConfigSelected
# NAME
#   getCustomConfigSelected -- get default custom configuration
# SYNOPSIS
#   getCustomConfigSelected $node
# FUNCTION
#   For input node this procedure returns ID of a default configuration
# INPUTS
#   * node -- node id
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
#   setCustomConfigSelected $node
# FUNCTION
#   For input node this procedure sets ID of a default configuration
# INPUTS
#   * node -- node id
#   * conf -- custom-config id
#****
proc setCustomConfigSelected { node_id state } {
    cfgSet "nodes" $node_id "custom_selected" $state
}

#****f* nodecfg.tcl/getCustomConfig
# NAME
#   getCustomConfig -- get custom configuration
# SYNOPSIS
#   getCustomConfig $node $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration.
# INPUTS
#   * node -- node id
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
#   setCustomConfig $node $id $cmd $config
# FUNCTION
#   For input node this procedure sets custom configuration section in input
#   node.
# INPUTS
#   * node -- node id
#   * id -- custom-config id
#   * cmd -- custom command
#   * config -- custom configuration section
#****
proc setCustomConfig { node_id cfg_id cmd config } {
    cfgSet "nodes" $node_id "custom_configs" $cfg_id "custom_command" $cmd
    cfgSet "nodes" $node_id "custom_configs" $cfg_id "custom_config" $config
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
#   getCustomConfigCommand $node $id
# FUNCTION
#   For input node and configuration ID this procedure returns custom
#   configuration boot command.
# INPUTS
#   * node -- node id
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
#   getCustomConfigIDs $node
# FUNCTION
#   For input node this procedure returns all custom configuration IDs.
# INPUTS
#   * node -- node id
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
#   getNodeStolenIfaces $node $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node -- node id
#   * name -- logical name of the node
#****
proc getNodeStolenIfaces { node_id } {
    set external_ifaces {}
    foreach {iface iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
	if { [dictGet $iface_cfg "type"] == "stolen" } {
	    set stolen_iface [dictGet $iface_cfg "stolen_iface"]
	    lappend external_ifaces "$iface $stolen_iface"
	}
    }

    return $external_ifaces
}

#****f* nodecfg.tcl/getDefaultGateways
# NAME
#   getDefaultGateways -- get default IPv4/IPv6 gateways.
# SYNOPSIS
#   lassign [getDefaultGateways $node $subnet_gws $nodes_l2data] \
#     my_gws subnets_and_gws
# FUNCTION
#   Returns a list of all default IPv4/IPv6 gateways for the subnets in which
#   this node belongs as a {getNodeType|gateway4|gateway6} values. Additionally,
#   it refreshes newly discovered gateways and subnet members to the existing
#   $subnet_gws list and $nodes_l2data dictionary.
# INPUTS
#   * node -- node id
#   * subnet_gws -- already known {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node ifc subnet_idx}
#   triplets in this subnet
# RESULT
#   * my_gws -- list of all possible default gateways for the specified node
#   * subnet_gws -- refreshed {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node ifc subnet_idx} triplets in
#   this subnet
#****
proc getDefaultGateways { node_id subnet_gws nodes_l2data } {
    set all_ifc [ifcList $node_id]
    if { [llength $all_ifc] == 0 } {
	return [list {} {} {}]
    }

    # go through all interfaces and collect data for each subnet
    foreach ifc $all_ifc {
	if { [dict exists $nodes_l2data $node_id $ifc] } {
	    continue
	}

	# add new subnet at the end of the list
	set subnet_idx [llength $subnet_gws]
	lassign [logicalPeerByIfc $node_id $ifc] peer_node peer_ifc
	if { $peer_node == "" } {
	    continue
	}

	lassign [getSubnetData $peer_node $peer_ifc \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    # merge all gateways values and return
    set my_gws {}
    if { $nodes_l2data != {} } {
	foreach subnet_idx [lsort -unique [dict values [dict get $nodes_l2data $node_id]]] {
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
#   as {nodes ifc subnet_idx} triplets in the nodes_l2data dictionary.
# INPUTS
#   * this_node -- node id
#   * this_ifc -- node interface
#   * subnet_gws -- already known {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node ifc subnet_idx}
#   triplets in this subnet
# RESULT
#   * subnet_gws -- refreshed {getNodeType|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node ifc subnet_idx} triplets in
#   this subnet
#****
proc getSubnetData { this_node_id this_ifc subnet_gws nodes_l2data subnet_idx } {
    set my_gws [lindex $subnet_gws $subnet_idx]

    if { [dict exists $nodes_l2data $this_node_id $this_ifc] } {
	# this node/ifc is already a part of this subnet
	set subnet_idx [dict get $nodes_l2data $this_node_id $this_ifc]
	return [list $subnet_gws $nodes_l2data]
    }

    dict set nodes_l2data $this_node_id $this_ifc $subnet_idx

    set this_type [getNodeType $this_node_id]
    if { [$this_type.netlayer] == "NETWORK" } {
	if { $this_type in "router extnat" } {
	    # this node is a router/extnat, add our IP addresses to lists
	    set gw4 [lindex [split [getIfcIPv4addr $this_node_id $this_ifc] /] 0]
	    set gw6 [lindex [split [getIfcIPv6addr $this_node_id $this_ifc] /] 0]
	    lappend my_gws $this_type|$gw4|$gw6
	    lset subnet_gws $subnet_idx $my_gws
	}

	# first, get this node/ifc peer's subnet data in case it is an L2 node
	# and we're not yet gone through it
	lassign [logicalPeerByIfc $this_node_id $this_ifc] peer_node peer_ifc
	lassign [getSubnetData $peer_node $peer_ifc \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data

	# this node is done, do nothing else
	if { $subnet_gws == "" } {
	    set subnet_gws "{||}"
	}
	return [list $subnet_gws $nodes_l2data]
    }

    # this node is an L2 node
    # - collect data from all interfaces
    foreach ifc [ifcList $this_node_id] {
	dict set nodes_l2data $this_node_id $ifc $subnet_idx

	lassign [logicalPeerByIfc $this_node_id $ifc] peer_node peer_ifc
	if { $peer_node == "" } {
	    continue
	}

	lassign [getSubnetData $peer_node $peer_ifc \
	  $subnet_gws $nodes_l2data $subnet_idx] \
	  subnet_gws nodes_l2data
    }

    return [list $subnet_gws $nodes_l2data]
}

#****f* nodecfg.tcl/getStatIPv4routes
# NAME
#   getStatIPv4routes -- get static IPv4 routes.
# SYNOPSIS
#   set routes [getStatIPv4routes $node]
# FUNCTION
#   Returns a list of all static IPv4 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
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
#   setStatIPv4routes $node $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node -- the node id of the node whose static routes are set.
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv4routes { node_id routes } {
    cfgSet "nodes" $node_id "croutes4" $routes
}

#****f* nodecfg.tcl/getDefaultIPv4routes
# NAME
#   getDefaultIPv4routes -- get auto default IPv4 routes.
# SYNOPSIS
#   set routes [getDefaultIPv4routes $node]
# FUNCTION
#   Returns a list of all auto default IPv4 routes as a list of
#   {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node -- node id
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
#   setDefaultIPv4routes $node $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {0.0.0.0/0 gateway} pairs.
# INPUTS
#   * node -- the node id of the node whose default routes are set
#   * routes -- list of all IPv4 default routes defined for the specified node
#****
proc setDefaultIPv4routes { node_id routes } {
    cfgSet "nodes" $node_id "default_routes4" $routes
}

#****f* nodecfg.tcl/getDefaultIPv6routes
# NAME
#   getDefaultIPv6routes -- get auto default IPv6 routes.
# SYNOPSIS
#   set routes [getDefaultIPv6routes $node]
# FUNCTION
#   Returns a list of all auto default IPv6 routes as a list of
#   {::/0 gateway} pairs.
# INPUTS
#   * node -- node id
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
#   setDefaultIPv6routes $node $routes
# FUNCTION
#   Replace all current auto default route entries with a new one, in form of a
#   list of {::/0 gateway} pairs.
# INPUTS
#   * node -- the node id of the node whose default routes are set
#   * routes -- list of all IPv6 default routes defined for the specified node
#****
proc setDefaultIPv6routes { node_id routes } {
    cfgSet "nodes" $node_id "default_routes6" $routes
}

#****f* nodecfg.tcl/getStatIPv6routes
# NAME
#   getStatIPv6routes -- get static IPv6 routes.
# SYNOPSIS
#   set routes [getStatIPv6routes $node]
# FUNCTION
#   Returns a list of all static IPv6 routes as a list of
#   {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
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
#   setStatIPv6routes $node $routes
# FUNCTION
#   Replace all current static route entries with a new one, in form of a list
#   of {destination gateway {metric}} pairs.
# INPUTS
#   * node -- node id
#   * routes -- list of all static routes defined for the specified node
#****
proc setStatIPv6routes { node_id routes } {
    cfgSet "nodes" $node_id "croutes6" $routes
}

#****f* nodecfg.tcl/getDefaultRoutesConfig
# NAME
#   getDefaultRoutesConfig -- get node default routes in a configuration format
# SYNOPSIS
#   lassign [getDefaultRoutesConfig $node $gws] routes4 routes6
# FUNCTION
#   Called when translating IMUNES default gateways configuration to node
#   pre-running configuration. Returns IPv4 and IPv6 routes lists.
# INPUTS
#   * node -- node id
#   * gws -- gateway values in the {getNodeType|gateway4|gateway6} format
# RESULT
#   * all_routes4 -- {0.0.0.0/0 gw4} pairs of default IPv4 routes
#   * all_routes6 -- {0.0.0.0/0 gw6} pairs of default IPv6 routes
#****
proc getDefaultRoutesConfig { node_id gws } {
    set all_routes4 {}
    set all_routes6 {}
    foreach route $gws {
	lassign [split $route "|"] route_type gateway4 gateway6
	if { [getNodeType $node_id] == "router" } {
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
#   set name [getNodeName $node]
# FUNCTION
#   Returns node's logical name.
# INPUTS
#   * node -- node id
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
#   setNodeName $node $name
# FUNCTION
#   Sets node's logical name.
# INPUTS
#   * node -- node id
#   * name -- logical name of the node
#****
proc setNodeName { node_id name } {
    cfgSet "nodes" $node_id "name" $name
}

#****f* nodecfg.tcl/getNodeType
# NAME
#   getNodeType -- get node type.
# SYNOPSIS
#   set type [getNodeType $node]
# FUNCTION
#   Returns node's type.
# INPUTS
#   * node -- node id
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
#   set model [getNodeModel $node]
# FUNCTION
#   Returns node's optional routing model. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node -- node id
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
#   setNodeModel $node $model
# FUNCTION
#   Sets an optional routing model to the node. Currently supported models are
#   frr, quagga and static and only nodes of type router have a defined model.
# INPUTS
#   * node -- node id
#   * model -- routing model of the specified node
#****
proc setNodeModel { node_id model } {
    cfgSet "nodes" $node_id "model" $model
}

#****f* nodecfg.tcl/getNodeSnapshot
# NAME
#   getNodeSnapshot -- get node snapshot image name.
# SYNOPSIS
#   set snapshot [getNodeSnapshot $node]
# FUNCTION
#   Returns node's snapshot name.
# INPUTS
#   * node -- node id
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
#   setNodeSnapshot $node $snapshot
# FUNCTION
#   Sets node's snapshot name.
# INPUTS
#   * node -- node id
#   * snapshot -- snapshot name for the specified node
#****
proc setNodeSnapshot { node_id snapshot } {
    cfgSet "nodes" $node_id "snapshot" $snapshot
}

#****f* nodecfg.tcl/getStpEnabled
# NAME
#   getStpEnabled -- get STP enabled state
# SYNOPSIS
#   set enabled [getStpEnabled $node]
# FUNCTION
#   For input node this procedure returns true if STP is enabled
#   for the specified node.
# INPUTS
#   * node -- node id
# RESULT
#   * enabled -- returns true if STP is enabled
#****
proc getStpEnabled { node_id } {
    return [cfgGet "nodes" $node_id "stp_enabled"]
}

#****f* nodecfg.tcl/setStpEnabled
# NAME
#   setStpEnabled -- set STP enabled state
# SYNOPSIS
#   setStpEnabled $node $enabled
# FUNCTION
#   For input node this procedure enables or disables STP.
# INPUTS
#   * node -- node id
#   * enabled -- true if enabling STP, false if disabling
#****
proc setStpEnabled { node_id state } {
    cfgSet "nodes" $node_id "stp_enabled" $state
}

#****f* nodecfg.tcl/getNodeCoords
# NAME
#   getNodeCoords -- get node icon coordinates.
# SYNOPSIS
#   set coords [getNodeCoords $node]
# FUNCTION
#   Returns node's icon coordinates.
# INPUTS
#   * node -- node id
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
#   setNodeCoords $node $coords
# FUNCTION
#   Sets node's icon coordinates.
# INPUTS
#   * node -- node id
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
#   set coords [getNodeLabelCoords $node]
# FUNCTION
#   Returns node's label coordinates.
# INPUTS
#   * node -- node id
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
#   setNodeLabelCoords $node $coords
# FUNCTION
#   Sets node's label coordinates.
# INPUTS
#   * node -- node id
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
#   set conf [getNodeCPUConf $node]
# FUNCTION
#   Returns node's CPU scheduling parameters { minp maxp weight }.
# INPUTS
#   * node -- node id
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
#   setNodeCPUConf $node $param_list
# FUNCTION
#   Sets the node's CPU scheduling parameters.
# INPUTS
#   * node -- node id
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
}

#****f* nodecfg.tcl/removeNode
# NAME
#   removeNode -- removes the node
# SYNOPSIS
#   removeNode $node
# FUNCTION
#   Removes the specified node as well as all the links binding that node to
#   the other nodes.
# INPUTS
#   * node -- node id
#****
proc removeNode { node_id { keep_other_ifaces 0 } } {
    global nodeNamingBase

    if { [getCustomIcon $node_id] != "" } {
	removeImageReference [getCustomIcon $node_id] $node_id
    }

    foreach iface_id [ifcList $node_id] {
	removeLink [linkByPeers $node_id [getIfcPeer $node_id $iface_id]] $keep_other_ifaces
    }

    setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]

    set node_type [getNodeType $node_id]
    if { $node_type in [array names nodeNamingBase] } {
	recalculateNumType $node_type $nodeNamingBase($node_type)
    }

    cfgUnset "nodes" $node_id
}

#****f* nodecfg.tcl/getNodeCanvas
# NAME
#   getNodeCanvas -- get node canvas id
# SYNOPSIS
#   set canvas [getNodeCanvas $node]
# FUNCTION
#   Returns node's canvas affinity.
# INPUTS
#   * node -- node id
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
#   setNodeCanvas $node $canvas
# FUNCTION
#   Sets node's canvas affinity.
# INPUTS
#   * node -- node id
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
    global viewid
    catch { unset viewid }

    set node_id [newObjectId "node"]
    setNodeType $node_id $type
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
#   set mirror_node_id [getNodeMirror $node]
# FUNCTION
#   Returns the node id of a mirror pseudo node of the node. Mirror node is
#   the corresponding pseudo node. The pair of pseudo nodes, node and his
#   mirror node, are introduced to form a split in a link. This split can be
#   used for avoiding crossed links or for displaying a link between the nodes
#   on a different canvas.
# INPUTS
#   * node -- node id
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
#   setNodeMirror $node $value
# FUNCTION
#   Sets the node id of a mirror pseudo node of the specified node. Mirror
#   node is the corresponding pseudo node. The pair of pseudo nodes, node and
#   his mirror node, are introduced to form a split in a link. This split can
#   be used for avoiding crossed links or for displaying a link between the
#   nodes on a different canvas.
# INPUTS
#   * node -- node id
#   * value -- node id of a mirror node
#****
proc setNodeMirror { node_id value } {
    cfgSet "nodes" $node_id "mirror" $value
}

#****f* nodecfg.tcl/getNodeProtocolRip
# NAME
#   getNodeProtocolRip
# SYNOPSIS
#   getNodeProtocolRip $node
# FUNCTION
#   Checks if node's current protocol is rip.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is rip, otherwise 0
#****
proc getNodeProtocol { node_id protocol } {
    return [cfgGetWithDefault 0 "nodes" $node_id "router_config" $protocol]
}

proc setNodeProtocol { node_id protocol state } {
    cfgSet "nodes" $node_id "router_config" $protocol $state
}

#****f* nodecfg.tcl/getNodeProtocolRipng
# NAME
#   getNodeProtocolRipng
# SYNOPSIS
#   getNodeProtocolRipng $node
# FUNCTION
#   Checks if node's current protocol is ripng.
# INPUTS
#   * node -- node id
# RESULT
#   * check -- 1 if it is ripng, otherwise 0
#****

#****f* nodecfg.tcl/getNodeProtocolOspfv2
# NAME
#   getNodeProtocolOspfv2
# SYNOPSIS
#   getNodeProtocolOspfv2 $node
# FUNCTION
#   Checks if node's current protocol is ospfv2.
# INPUTS
#   * node -- node id
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
    if { [getNodeProtocol $node_id $protocol] == 0 } {
	return ""
    }

    set cfg {}

    set model [getNodeModel $node_id]
    switch -exact -- $model {
	"quagga" -
	"frr" {
	    set router_id [ip::intToString [expr 1 + [string trimleft $node_id "n"]]]
	    switch -exact -- $protocol {
		"rip" {
		    set cfg [list "router rip" \
			" redistribute static" \
			" redistribute connected" \
			" redistribute ospf" \
			" network 0.0.0.0/0" \
			! ]
		}
		"ripng" {
		    set cfg [list "router ripng" \
			" redistribute static" \
			" redistribute connected" \
			" redistribute ospf6" \
			" network ::/0" \
			! ]
		}
		"ospf" {
		    set cfg [list "router ospf" \
			" ospf router-id $router_id" \
			" redistribute static" \
			" redistribute connected" \
			" redistribute rip" \
			! ]
		}
		"ospf6" {
		    if { $model == "quagga" } {
			set id_string "router-id $router_id"
			#set area_string "network ::/0 area 0.0.0.0"
		    } else {
			set id_string "ospf6 router-id $router_id"
			#set area_string "area 0.0.0.0 range ::/0"
		    }

		    set cfg [list "router ospf6" \
			" $id_string" \
			" redistribute static" \
			" redistribute connected" \
			" redistribute ripng" \
			]

		    if { $model == "quagga" } {
			foreach iface [ifcList $node_id] {
			    lappend cfg " interface $iface area 0.0.0.0"
			}
		    }

		    lappend cfg "!"
		}
		"bgp" {
		    set loopback_ipv4 [lindex [split [getIfcIPv4addr $node_id "lo0" ] "/"] 0]
		    set cfg [list "router bgp 1000" \
			" bgp router-id $loopback_ipv4" \
			" no bgp ebgp-requires-policy" \
			" neighbor DEFAULT peer-group" \
			" neighbor DEFAULT remote-as 1000" \
			" neighbor DEFAULT update-source $loopback_ipv4" \
			" redistribute static" \
			" redistribute connected" \
			! ]
		}
	    }
	}
	"static" {
	    # nothing to return
	}
    }

    return $cfg
}

proc getRouterStaticRoutes4Cfg { node_id } {
    set cfg {}

    switch -exact -- [getNodeModel $node_id] {
	"quagga" -
	"frr" {
	    set cfg [nodeCfggenRouteIPv4 $node_id 1]
	}
	"static" {
	    set cfg [nodeCfggenRouteIPv4 $node_id]
	}
    }

    return $cfg
}

proc getRouterStaticRoutes6Cfg { node_id } {
    set cfg {}

    switch -exact -- [getNodeModel $node_id] {
	"quagga" -
	"frr" {
	    set cfg [nodeCfggenRouteIPv6 $node_id 1]
	}
	"static" {
	    set cfg [nodeCfggenRouteIPv6 $node_id]
	}
    }

    return $cfg
}

#****f* nodecfg.tcl/setNodeType
# NAME
#   setNodeType -- set node's type.
# SYNOPSIS
#   setNodeType $node $type
# FUNCTION
#   Sets node's type.
# INPUTS
#   * node -- node id
#   * type -- type of node
#****
proc setNodeType { node_id type } {
    cfgSet "nodes" $node_id "type" $type
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
#   set value [getEtherVlanEnabled $node]
# FUNCTION
#   Returns whether the rj45 node is vlan enabled.
# INPUTS
#   * node -- node id
# RESULT
#   * value -- vlan enabled
#****
proc getEtherVlanEnabled { node_id } {
    return [cfgGetWithDefault 0 "nodes" $node_id "vlan" "enabled"]
}

#****f* nodecfg.tcl/setEtherVlanEnabled
# NAME
#   setEtherVlanEnabled -- set node rj45 vlan.
# SYNOPSIS
#   setEtherVlanEnabled $node $value
# FUNCTION
#   Sets rj45 node vlan setting.
# INPUTS
#   * node -- node id
#   * value -- vlan enabled
#****
proc setEtherVlanEnabled { node_id state } {
    cfgSet "nodes" $node_id "vlan" "enabled" $state
}

#****f* nodecfg.tcl/getEtherVlanTag
# NAME
#   getEtherVlanTag -- get node rj45 vlan tag.
# SYNOPSIS
#   set value [getEtherVlanTag $node]
# FUNCTION
#   Returns rj45 node vlan tag.
# INPUTS
#   * node -- node id
# RESULT
#   * value -- vlan tag
#****
proc getEtherVlanTag { node_id } {
    return [cfgGetWithDefault 1 "nodes" $node_id "vlan" "tag"]
}

#****f* nodecfg.tcl/setEtherVlanTag
# NAME
#   setEtherVlanTag -- set node rj45 vlan tag.
# SYNOPSIS
#   setEtherVlanTag $node $value
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
#   set services [getNodeServices $node]
# FUNCTION
#   Returns node's selected services.
# INPUTS
#   * node -- node id
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
#   setNodeServices $node $services
# FUNCTION
#   Sets node selected services.
# INPUTS
#   * node -- node id
#   * services -- list of services
#****
proc setNodeServices { node_id services } {
    cfgSet "nodes" $node_id "services" $services
}

#****f* nodecfg.tcl/getNodeCustomImage
# NAME
#   getNodeCustomImage -- get node custom image.
# SYNOPSIS
#   set value [getNodeCustomImage $node]
# FUNCTION
#   Returns node custom image setting.
# INPUTS
#   * node -- node id
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
#   setNodeCustomImage $node $img
# FUNCTION
#   Sets node custom image.
# INPUTS
#   * node -- node id
#   * img -- image identifier
#****
proc setNodeCustomImage { node_id img } {
    cfgSet "nodes" $node_id "custom_image" $img
}

#****f* nodecfg.tcl/getNodeDockerAttach
# NAME
#   getNodeDockerAttach -- get node docker ext ifc attach.
# SYNOPSIS
#   set value [getNodeDockerAttach $node]
# FUNCTION
#   Returns node docker ext ifc attach setting.
# INPUTS
#   * node -- node id
# RESULT
#   * status -- attach enabled
#****
proc getNodeDockerAttach { node_id } {
    return [cfgGetWithDefault "false" "nodes" $node_id "docker_attach"]
}

#****f* nodecfg.tcl/setNodeDockerAttach
# NAME
#   setNodeDockerAttach -- set node docker ext ifc attach.
# SYNOPSIS
#   setNodeDockerAttach $node $enabled
# FUNCTION
#   Sets node docker ext ifc attach status.
# INPUTS
#   * node -- node id
#   * enabled -- attach status
#****
proc setNodeDockerAttach { node_id state } {
    cfgSet "nodes" $node_id "docker_attach" $state
}

#****f* nodecfg.tcl/nodeCfggenRouteIPv4
# NAME
#   nodeCfggenRouteIPv4 -- generate ifconfig IPv4 configuration
# SYNOPSIS
#   nodeCfggenRouteIPv4 $node
# FUNCTION
#   Generate IPv4 route configuration.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- route IPv4 configuration script
#****
proc nodeCfggenRouteIPv4 { node_id { vtysh 0 } } {
    set cfg {}
    foreach statrte [getStatIPv4routes $node_id] {
	if { $vtysh } {
	    lappend cfg "ip route $statrte"
	} else {
	    lappend cfg [getIPv4RouteCmd $statrte]
	}
    }

    if { [getAutoDefaultRoutesStatus $node_id] == "enabled" } {
	foreach statrte [getDefaultIPv4routes $node_id] {
	    if { $vtysh } {
		lappend cfg "ip route $statrte"
	    } else {
		lappend cfg [getIPv4RouteCmd $statrte]
	    }
	}
	setDefaultIPv4routes $node_id {}
    }

    return $cfg
}

#****f* nodecfg.tcl/nodeCfggenRouteIPv6
# NAME
#   nodeCfggenRouteIPv6 -- generate ifconfig IPv6 configuration
# SYNOPSIS
#   nodeCfggenRouteIPv6 $node
# FUNCTION
#   Generate IPv6 route configuration.
# INPUTS
#   * node -- node to generate configuration for
# RESULT
#   * value -- route IPv6 configuration script
#****
proc nodeCfggenRouteIPv6 { node_id { vtysh 0 } } {
    set cfg {}
    foreach statrte [getStatIPv6routes $node_id] {
	if { $vtysh } {
	    lappend cfg "ipv6 route $statrte"
	} else {
	    lappend cfg [getIPv6RouteCmd $statrte]
	}
    }

    if { [getAutoDefaultRoutesStatus $node_id] == "enabled" } {
	foreach statrte [getDefaultIPv6routes $node_id] {
	    if { $vtysh } {
		lappend cfg "ipv6 route $statrte"
	    } else {
		lappend cfg [getIPv6RouteCmd $statrte]
	    }
	}
	setDefaultIPv6routes $node_id {}
    }

    return $cfg
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
