#
# Copyright 2004- University of Zagreb.
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

proc getNodeDir { node_id } {
	return [getVrootDir]/[getFromRunning "eid"]/$node_id
}

#****f* nodecfg.tcl/getNodeCustomConfigIDs
# NAME
#   getNodeCustomConfigIDs -- get custom configuration IDs
# SYNOPSIS
#   getNodeCustomConfigIDs $node_id
# FUNCTION
#   For input node this procedure returns all custom configuration IDs.
# INPUTS
#   * node_id -- node id
# RESULT
#   * IDs -- returns custom configuration IDs
#****
proc getNodeCustomConfigIDs { node_id hook } {
	return [dict keys [cfgGet "nodes" $node_id "custom_configs" $hook]]
}

#****f* nodecfg.tcl/getNodeStolenIfaces
# NAME
#   getNodeStolenIfaces -- set node's stolen interfaces
# SYNOPSIS
#   getNodeStolenIfaces $node_id
# FUNCTION
#   Gets pairs of the node's stolen interfaces
# INPUTS
#   * node_id -- node id
# RESULT
#   * ifaces -- list of {iface_id stolen_iface} pairs
#****
proc getNodeStolenIfaces { node_id } {
	set external_ifaces {}
	foreach {iface_id iface_cfg} [cfgGet "nodes" $node_id "ifaces"] {
		if { [dictGet $iface_cfg "type"] == "stolen" } {
			lappend external_ifaces "$iface_id [dictGet $iface_cfg "name"]"
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
#   lassign [getSubnetData $this_node_id $this_iface_id \
#     $subnet_gws $nodes_l2data $subnet_idx] \
#     subnet_gws nodes_l2data
# FUNCTION
#   Called when checking L2 network for routers/extnats in order to get all
#   default gateways. Returns all possible default IPv4/IPv6 gateways in this
#   LAN appended to the subnet_gws list and updates the members of this subnet
#   as {node_id iface_id subnet_idx} triplets in the nodes_l2data dictionary.
# INPUTS
#   * this_node_id -- node id
#   * this_iface_id -- node interface
#   * subnet_gws -- already known {node_type|gateway4|gateway6} values
#   * nodes_l2data -- a dictionary of already known {node_id iface_id subnet_idx}
#   triplets in this subnet
# RESULT
#   * subnet_gws -- refreshed {node_type|gateway4|gateway6} values
#   * nodes_l2data -- refreshed dictionary of {node_id iface_id subnet_idx} triplets in
#   this subnet
#****
proc getSubnetData { this_node_id this_iface_id subnet_gws nodes_l2data subnet_idx } {
	set my_gws [lindex $subnet_gws $subnet_idx]

	if { [dict exists $nodes_l2data $this_node_id $this_iface_id] } {
		# this node/iface is already a part of this subnet
		set subnet_idx [dict get $nodes_l2data $this_node_id $this_iface_id]
		return [list $subnet_gws $nodes_l2data]
	}

	dict set nodes_l2data $this_node_id $this_iface_id $subnet_idx

	set this_type [getNodeType $this_node_id]
	if { $this_type in "" } {
		return [list $subnet_gws $nodes_l2data]
	}

	if { [$this_type.netlayer] == "NETWORK" } {
		if { $this_type in "router nat64" || ($this_type == "ext" && [getNodeNATIface $this_node_id] != "UNASSIGNED") } {
			# this node is a router/extnat, add our IP addresses to lists
			# TODO: multiple addresses per iface - split subnet4data and subnet6data
			set gw4 [lindex [split [getIfcIPv4addrs $this_node_id $this_iface_id] /] 0]
			if { $gw4 == "dhcp" } {
				set gw4 ""
			}
			set gw6 [lindex [split [getIfcIPv6addrs $this_node_id $this_iface_id] /] 0]
			lappend my_gws $this_type|$gw4|$gw6
			lset subnet_gws $subnet_idx $my_gws
		}

		# first, get this node/iface peer's subnet data in case it is an L2 node
		# and we're not yet gone through it
		lassign [logicalPeerByIfc $this_node_id $this_iface_id] peer_id peer_iface_id
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
	# This is just a temporary field, no need to mark the topology as modified
	set tmp [getFromRunning "modified"]
	cfgSet "nodes" $node_id "default_routes4" $routes
	setToRunning "modified" $tmp
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
	# This is just a temporary field, no need to mark the topology as modified
	set tmp [getFromRunning "modified"]
	cfgSet "nodes" $node_id "default_routes6" $routes
	setToRunning "modified" $tmp
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

	lassign [getAllIpAddresses $node_id] ipv4_addrs ipv6_addrs
	if { $ipv4_addrs == "" && $ipv6_addrs == "" } {
		return "\"$all_routes4\" \"$all_routes6\""
	}

	# remove all non-extnat routes
	if { [getNodeType $node_id] in "router nat64" } {
		set gws [lsearch -inline -all $gws "ext*"]
	}

	foreach route $gws {
		lassign [split $route "|"] route_type gateway4 -

		if { $gateway4 == "" } {
			continue
		}

		set match4 false
		foreach ipv4_addr $ipv4_addrs {
			if { $ipv4_addr == "dhcp" } {
				continue
			}

			set mask [ip::mask $ipv4_addr]
			if { [ip::prefix $gateway4/$mask] == [ip::prefix $ipv4_addr] } {
				set match4 true
				break
			}
		}

		if { $match4 && "0.0.0.0/0 $gateway4" ni $all_routes4 } {
			if { $route_type == "ext" } {
				set all_routes4 [linsert $all_routes4 0 "0.0.0.0/0 $gateway4"]
			} else {
				lappend all_routes4 "0.0.0.0/0 $gateway4"
			}
		}
	}

	foreach route $gws {
		lassign [split $route "|"] route_type - gateway6

		if { $gateway6 == "" } {
			continue
		}

		set match6 false
		foreach ipv6_addr $ipv6_addrs {
			set mask [ip::mask $ipv6_addr]
			if { [ip::contract [ip::prefix $gateway6/$mask]] == [ip::contract [ip::prefix $ipv6_addr]] } {
				set match6 true
				break
			}
		}

		if { $match6 && "::/0 $gateway6" ni $all_routes6 } {
			if { $route_type == "ext" } {
				set all_routes6 [linsert $all_routes6 0 "::/0 $gateway6"]
			} else {
				lappend all_routes6 "::/0 $gateway6"
			}
		}
	}

	return "\"$all_routes4\" \"$all_routes6\""
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

	foreach iface_id [ifcList $node_id] {
		removeIface $node_id $iface_id $keep_other_ifaces
	}

	setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]
	setToRunning "no_auto_execute_nodes" [removeFromList [getFromRunning "no_auto_execute_nodes"] $node_id]

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
	setToRunning "${node_id}_running" false

	lappendToRunning "node_list" $node_id

	if { [info procs $type.confNewNode] == "$type.confNewNode" } {
		$type.confNewNode $node_id
	}

	return $node_id
}

#****f* nodecfg.tcl/getRouterProtocolCfg
# NAME
#   getRouterProtocolCfg -- get router protocol configuration
# SYNOPSIS
#   getRouterProtocolCfg $node_id $protocol
# FUNCTION
#   Returns the router protocol configuration.
# INPUTS
#   * node_id -- node id
#   * protocol -- router protocol
#****
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
					set loopback_ipv4 [lindex [split [getIfcIPv4addrs $node_id "lo0" ] "/"] 0]
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
			if { [getNodeCustomEnabled $node_id] != true } {
				set routes4 [nodeCfggenStaticRoutes4 $node_id 1]
				set routes6 [nodeCfggenStaticRoutes6 $node_id 1]

				if { $routes4 != "" || $routes6 != "" } {
					lappend cfg "vtysh << __EOF__"
					lappend cfg "conf term"

					set cfg [concat $cfg $routes4]
					set cfg [concat $cfg $routes6]

					lappend cfg "!"
					lappend cfg "__EOF__"
				}
			}

			set routes4 [nodeCfggenAutoRoutes4 $node_id 1]
			set routes6 [nodeCfggenAutoRoutes6 $node_id 1]

			if { $routes4 != "" || $routes6 != "" } {
				lappend cfg "vtysh << __EOF__"
				lappend cfg "conf term"

				set cfg [concat $cfg $routes4]
				set cfg [concat $cfg $routes6]

				lappend cfg "!"
				lappend cfg "__EOF__"
			}
		}
		"static" {
			if { [getNodeCustomEnabled $node_id] != true } {
				set cfg [concat $cfg [nodeCfggenStaticRoutes4 $node_id]]
				set cfg [concat $cfg [nodeCfggenStaticRoutes6 $node_id]]

				lappend cfg ""
			}

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
			if { [getNodeCustomEnabled $node_id] != true } {
				lappend cfg "vtysh << __EOF__"
				lappend cfg "conf term"

				set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id 1]]
				set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id 1]]

				lappend cfg "!"
				lappend cfg "__EOF__"
			}

			lappend cfg "vtysh << __EOF__"
			lappend cfg "conf term"

			set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id 1]]
			set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id 1]]

			lappend cfg "!"
			lappend cfg "__EOF__"
		}
		"static" {
			if { [getNodeCustomEnabled $node_id] != true } {
				set cfg [concat $cfg [nodeUncfggenStaticRoutes4 $node_id]]
				set cfg [concat $cfg [nodeUncfggenStaticRoutes6 $node_id]]

				lappend cfg ""
			}

			set cfg [concat $cfg [nodeUncfggenAutoRoutes4 $node_id]]
			set cfg [concat $cfg [nodeUncfggenAutoRoutes6 $node_id]]

			lappend cfg ""
		}
	}

	return $cfg
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
proc registerModule { module { supported_os "linux freebsd" } } {
	global all_modules_list
	global isOSfreebsd isOSlinux runnable_node_types

	if { $module ni $all_modules_list } {
		lappend all_modules_list $module
	}

	if { $isOSfreebsd } {
		if { "freebsd" in $supported_os && $module ni $runnable_node_types } {
			lappend runnable_node_types $module
		}
	} elseif { $isOSlinux } {
		if { "linux" in $supported_os && $module ni $runnable_node_types } {
			lappend runnable_node_types $module
		}
	}
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

#****f* editor.tcl/listLANNodes
# NAME
#   listLANNodes -- list LAN nodes
# SYNOPSIS
#   set l2peers [listLANNodes $l2node_id $l2peers]
# FUNCTION
#   Recursive function for finding all link layer nodes that are
#   connected to node l2node. Returns the list of all link layer
#   nodes that are on the same LAN as l2node.
# INPUTS
#   * l2node_id -- node id of a link layer node
#   * l2peers -- old link layer nodes on the same LAN
# RESULT
#   * l2peers -- new link layer nodes on the same LAN
#****
proc listLANNodes { l2node_id l2peers } {
	lappend l2peers $l2node_id

	foreach iface_id [ifcList $l2node_id] {
		lassign [logicalPeerByIfc $l2node_id $iface_id] peer_id peer_iface_id
		if { [getIfcLink $peer_id $peer_iface_id] == "" } {
			continue
		}

		if { [[getNodeType $peer_id].netlayer] == "LINK" && [getNodeType $peer_id] != "rj45" } {
			if { $peer_id ni $l2peers } {
				set l2peers [listLANNodes $peer_id $l2peers]
			}
		}
	}

	return $l2peers
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
	global routerRipEnable routerRipngEnable routerOspfEnable routerOspf6Enable routerBgpEnable routerLdpEnable
	global rdconfig routerDefaultsModel
	global changed

	lassign $rdconfig ripEnable ripngEnable ospfEnable ospf6Enable bgpEnable ldpEnable

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
					setNodeProtocol $node_id "ldp" $ldpEnable
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

proc getNodeIdFromHostname { node_id_name } {
	if { $node_id_name in [getFromRunning "node_list"] } {
		return $node_id_name
	}

	return [getNodeFromHostname $node_id_name]
}

#****f* nodecfg.tcl/getAllIpAddresses
# NAME
#   getAllIpAddresses -- retreives all IP addresses for current node
# SYNOPSIS
#   getAllIpAddresses $node_id
# FUNCTION
#   Retreives all local addresses (IPv4 and IPv6) for current node
# INPUTS
#   node_id - node id
#****
proc getAllIpAddresses { node_id } {
	set ifaces_list [ifcList $node_id]
	foreach logifc [logIfcList $node_id] {
		if { [string match "vlan*" $logifc] } {
			lappend ifaces_list $logifc
		}
	}

	set ipv4_list ""
	set ipv6_list ""
	foreach iface_id $ifaces_list {
		set ifcIPs [getIfcIPv4addrs $node_id $iface_id]
		if { $ifcIPs != "" } {
			lappend ipv4_list {*}$ifcIPs
		}

		set ifcIPs [getIfcIPv6addrs $node_id $iface_id]
		if { $ifcIPs != "" } {
			lappend ipv6_list {*}$ifcIPs
		}
	}

	return "\"$ipv4_list\" \"$ipv6_list\""
}

proc nodeCfggenStaticRoutes4 { node_id { vtysh 0 } } {
	set cfg {}

	set croutes4 [getNodeStatIPv4routes $node_id]
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

proc nodeCfggenStaticRoutes6 { node_id { vtysh 0 } } {
	set cfg {}

	set croutes6 [getNodeStatIPv6routes $node_id]
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

proc updateNode { node_id old_node_cfg new_node_cfg } {
	dputs ""
	dputs "= /UPDATE NODE $node_id START ="

	if { $old_node_cfg == "*" } {
		set old_node_cfg [cfgGet "nodes" $node_id]
	}

	dputs "OLD : '$old_node_cfg'"
	dputs "NEW : '$new_node_cfg'"

	set cfg_diff [dictDiff $old_node_cfg $new_node_cfg]
	dputs "= cfg_diff: '$cfg_diff'"
	if { $cfg_diff == "" || [lsort -uniq [dict values $cfg_diff]] == "copy" } {
		dputs "= NO CHANGE"
		dputs "= /UPDATE NODE $node_id END ="
		return $new_node_cfg
	}

	if { $new_node_cfg == "" } {
		return $old_node_cfg
	}

	if { [getFromRunning "cfg_deployed"] && [getFromRunning "auto_execution"] } {
		setToExecuteVars "terminate_cfg" [cfgGet]
	}

	dict for {key change} $cfg_diff {
		if { $change == "copy" } {
			continue
		}

		dputs "==== $change: '$key'"

		set old_value [_cfgGet $old_node_cfg $key]
		set new_value [_cfgGet $new_node_cfg $key]
		if { $change in "changed" } {
			dputs "==== OLD: '$old_value'"
		}
		if { $change in "new changed" } {
			dputs "==== NEW: '$new_value'"
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

			"vlan_filtering" {
				setNodeVlanFiltering $node_id $new_value
			}

			"nat_iface" {
				setNodeNATIface $node_id $new_value
			}

			"croutes4" {
				setNodeStatIPv4routes $node_id $new_value
			}

			"croutes6" {
				setNodeStatIPv6routes $node_id $new_value
			}

			"auto_default_routes" {
				setNodeAutoDefaultRoutesStatus $node_id $new_value
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

					dputs "======== $custom_configs_change: '$custom_configs_key'"

					set custom_configs_old_value [_cfgGet $old_value $custom_configs_key]
					set custom_configs_new_value [_cfgGet $new_value $custom_configs_key]
					if { $custom_configs_change in "changed" } {
						dputs "======== OLD: '$custom_configs_old_value'"
					}
					if { $custom_configs_change in "new changed" } {
						dputs "======== NEW: '$custom_configs_new_value'"
					}

					set hook_diff [dictDiff $custom_configs_old_value $custom_configs_new_value]
					dict for {hook_key hook_change} $hook_diff {
						if { $hook_change == "copy" } {
							continue
						}

						dputs "============ $hook_change: '$hook_key'"

						set hook_old_value [_cfgGet $custom_configs_old_value $hook_key]
						set hook_new_value [_cfgGet $custom_configs_new_value $hook_key]
						if { $hook_change in "changed" } {
							dputs "============ OLD: '$hook_old_value'"
						}
						if { $hook_change in "new changed" } {
							dputs "============ NEW: '$hook_new_value'"
						}

						if { $hook_change == "removed" } {
							removeNodeCustomConfig $node_id $custom_configs_key $hook_key
						} else {
							try {
								dict get $hook_new_value "custom_command"
							} on ok cmd {
							} on error {} {
								set cmd [dict get $hook_old_value "custom_command"]
							}

							try {
								dict get $hook_new_value "custom_config"
							} on ok cfg {
							} on error {} {
								set cfg [dict get $hook_old_value "custom_config"]
							}

							setNodeCustomConfig $node_id $custom_configs_key $hook_key $cmd $cfg
						}
					}
				}
			}

			"ipsec" {
				set ipsec_diff [dictDiff $old_value $new_value]
				dict for {ipsec_key ipsec_change} $ipsec_diff {
					if { $ipsec_change == "copy" } {
						continue
					}

					dputs "======== $ipsec_change: '$ipsec_key'"

					set ipsec_old_value [_cfgGet $old_value $ipsec_key]
					set ipsec_new_value [_cfgGet $new_value $ipsec_key]
					if { $ipsec_change in "changed" } {
						dputs "======== OLD: '$ipsec_old_value'"
					}
					if { $ipsec_change in "new changed" } {
						dputs "======== NEW: '$ipsec_new_value'"
					}

					switch -exact $ipsec_key {
						"ca_cert" -
						"local_cert" -
						"local_key_file" -
						"ipsec_logging" {
							setNodeIPsecItem $node_id $ipsec_key $ipsec_new_value
						}

						"ipsec_configs" {
							set ipsec_configs_diff [dictDiff $ipsec_old_value $ipsec_new_value]
							dict for {ipsec_configs_key ipsec_configs_change} $ipsec_configs_diff {
								if { $ipsec_configs_change == "copy" } {
									continue
								}

								dputs "============ $ipsec_configs_change: '$ipsec_configs_key'"

								set ipsec_configs_old_value [_cfgGet $ipsec_old_value $ipsec_configs_key]
								set ipsec_configs_new_value [_cfgGet $ipsec_new_value $ipsec_configs_key]
								if { $ipsec_configs_change in "changed" } {
									dputs "============ OLD: '$ipsec_configs_old_value'"
								}
								if { $ipsec_configs_change in "new changed" } {
									dputs "============ NEW: '$ipsec_configs_new_value'"
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

					dputs "======== $nat64_change: '$nat64_key'"

					set nat64_old_value [_cfgGet $old_value $nat64_key]
					set nat64_new_value [_cfgGet $new_value $nat64_key]
					if { $nat64_change in "changed" } {
						dputs "======== OLD: '$nat64_old_value'"
					}
					if { $nat64_change in "new changed" } {
						dputs "======== NEW: '$nat64_new_value'"
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
				setNodeCustomEnabled $node_id $new_value
			}

			"custom_selected" {
				set custom_selected_diff [dictDiff $old_value $new_value]
				dict for {custom_selected_key custom_selected_change} $custom_selected_diff {
					if { $custom_selected_change == "copy" } {
						continue
					}

					dputs "======== $custom_selected_change: '$custom_selected_key'"

					set custom_selected_old_value [_cfgGet $old_value $custom_selected_key]
					set custom_selected_new_value [_cfgGet $new_value $custom_selected_key]
					if { $custom_selected_change in "changed" } {
						dputs "======== OLD: '$custom_selected_old_value'"
					}
					if { $custom_selected_change in "new changed" } {
						dputs "======== NEW: '$custom_selected_new_value'"
					}

					setNodeCustomConfigSelected $node_id $custom_selected_key $custom_selected_new_value
				}
			}

			"events" {
				setElementEvents $node_id $new_value
			}

			"ifaces" {
				set ifaces_diff [dictDiff $old_value $new_value]
				dict for {iface_key iface_change} $ifaces_diff {
					if { $iface_change == "copy" } {
						continue
					}

					dputs "======== $iface_change: '$iface_key'"

					set iface_old_value [_cfgGet $old_value $iface_key]
					set iface_new_value [_cfgGet $new_value $iface_key]
					if { $iface_change in "changed" } {
						dputs "======== OLD: '$iface_old_value'"
					}
					if { $iface_change in "new changed" } {
						dputs "======== NEW: '$iface_new_value'"
					}

					switch -exact $iface_change {
						"removed" {
							removeIface $node_id $iface_key
						}

						"new" -
						"changed" {
							set iface_type [_cfgGet $iface_new_value "type"]
							if { $iface_change == "new" } {
								set iface_id [newIface $node_id $iface_type 0]
							} else {
								set iface_id $iface_key
							}

							updateIface $node_id $iface_id $iface_old_value $iface_new_value
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

					dputs "======== $packets_change: '$packets_key'"

					set packets_old_value [_cfgGet $old_value $packets_key]
					set packets_new_value [_cfgGet $new_value $packets_key]
					if { $packets_change in "changed" } {
						dputs "======== OLD: '$packets_old_value'"
					}
					if { $packets_change in "new changed" } {
						dputs "======== NEW: '$packets_new_value'"
					}

					if { $packets_key == "packetrate" } {
						dputs "setPackgenPacketRate $node_id $packets_new_value"
						setPackgenPacketRate $node_id $packets_new_value
						continue
					}

					set packets_diff [dictDiff $packets_old_value $packets_new_value]
					foreach {packet_key packet_change} $packets_diff {
						if { $packet_change == "copy" } {
							continue
						}

						dputs "============ $packet_change: '$packet_key'"

						set packet_old_value [_cfgGet $packets_old_value $packet_key]
						set packet_new_value [_cfgGet $packets_new_value $packet_key]
						if { $packet_change in "changed" } {
							dputs "============ OLD: '$packet_old_value'"
						}
						if { $packet_change in "new changed" } {
							dputs "============ NEW: '$packet_new_value'"
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

					dputs "======== $bridge_change: '$bridge_key'"

					set bridge_old_value [_cfgGet $old_value $bridge_key]
					set bridge_new_value [_cfgGet $new_value $bridge_key]
					if { $bridge_change in "changed" } {
						dputs "======== OLD: '$bridge_old_value'"
					}
					if { $bridge_change in "new changed" } {
						dputs "======== NEW: '$bridge_new_value'"
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

	dputs "= /UPDATE NODE $node_id END ="
	dputs ""

	return $new_node_cfg
}
