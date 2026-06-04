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

# NODE/IFACE STATE
proc getStateNode { node_id } {
	return [_cfgGet [getFromRunning "running_state"] "nodes" $node_id "state"]
}

proc getStateLink { link_id } {
	return [_cfgGet [getFromRunning "running_state"] "links" $link_id "state"]
}

proc getStateNodeIface { node_id iface_id } {
	return [_cfgGet [getFromRunning "running_state"] "nodes" $node_id "ifaces" $iface_id "state"]
}

proc setStateNode { node_id state } {
	setToRunning "running_state" \
		[_cfgSet [getFromRunning "running_state"] "nodes" $node_id "state" $state]
}

proc setStateLink { link_id state } {
	setToRunning "running_state" \
		[_cfgSet [getFromRunning "running_state"] "links" $link_id "state" $state]
}

proc setStateNodeIface { node_id iface_id state } {
	setToRunning "running_state" \
		[_cfgSet [getFromRunning "running_state"] "nodes" $node_id "ifaces" $iface_id "state" $state]
}

proc unsetStateNode { node_id } {
	setToRunning "running_state" \
		[_cfgUnset [getFromRunning "running_state"] "nodes" $node_id]
}

proc unsetStateLink { link_id } {
	setToRunning "running_state" \
		[_cfgUnset [getFromRunning "running_state"] "links" $link_id]
}

proc unsetStateNodeIface { node_id iface_id } {
	setToRunning "running_state" \
		[_cfgUnset [getFromRunning "running_state"] "nodes" $node_id "ifaces" $iface_id]
}

proc getStateErrorMsgNode { node_id } {
	return [_cfgGet [getFromRunning "running_state"] "nodes" $node_id "error_msg"]
}

proc getStateErrorMsgLink { link_id } {
	return [_cfgGet [getFromRunning "running_state"] "links" $link_id "error_msg"]
}

proc getStateErrorMsgNodeIface { node_id iface_id } {
	return [_cfgGet [getFromRunning "running_state"] "nodes" $node_id "ifaces" $iface_id "error_msg"]
}

proc setStateErrorMsgNode { node_id error_msg } {
	setToRunning "running_state" \
		[_cfgSet [getFromRunning "running_state"] "nodes" $node_id "error_msg" $error_msg]
}

proc setStateErrorMsgLink { link_id error_msg } {
	setToRunning "running_state" \
		[_cfgSet [getFromRunning "running_state"] "links" $link_id "error_msg" $error_msg]
}

proc setStateErrorMsgNodeIface { node_id iface_id error_msg } {
	setToRunning "running_state" \
		[_cfgSet [getFromRunning "running_state"] "nodes" $node_id "ifaces" $iface_id "error_msg" $error_msg]
}

proc addStateNode { node_id states } {
	if { $states == "" } {
		return
	}

	set all_states [getStateNode $node_id]
	if { $all_states == "" } {
		set all_states $states
	} else {
		foreach state $states {
			if { $state ni $all_states } {
				lappend all_states $state
			}
		}
	}

	setStateNode $node_id $all_states
}

proc addStateLink { link_id states } {
	if { $states == "" } {
		return
	}

	set all_states [getStateLink $link_id]
	if { $all_states == "" } {
		set all_states $states
	} else {
		foreach state $states {
			if { $state ni $all_states } {
				lappend all_states $state
			}
		}
	}

	setStateLink $link_id $all_states
}

proc addStateNodeIface { node_id iface_id states } {
	if { $states == "" } {
		return
	}

	set all_states [getStateNodeIface $node_id $iface_id]
	if { $all_states == "" } {
		set all_states $states
	} else {
		foreach state $states {
			if { $state ni $all_states } {
				lappend all_states $state
			}
		}
	}

	setStateNodeIface $node_id $iface_id $all_states
}

proc removeStateNode { node_id states } {
	setStateNode $node_id [removeFromList [getStateNode $node_id] $states]
}

proc removeStateLink { link_id states } {
	setStateLink $link_id [removeFromList [getStateLink $link_id] $states]
}

proc removeStateNodeIface { node_id iface_id states } {
	setStateNodeIface $node_id $iface_id [removeFromList [getStateNodeIface $node_id $iface_id] $states]
}

proc isRunningNode { node_id } {
	if { "running" in [getStateNode $node_id] } {
		return true
	}

	return false
}

proc isRunningLink { link_id } {
	if { "running" in [getStateLink $link_id] } {
		return true
	}

	return false
}

proc isRunningNodeIface { node_id iface_id } {
	if {
		[isRunningNode $node_id] &&
		"running" in [getStateNodeIface $node_id $iface_id]
	} {
		return true
	}

	return false
}

proc isErrorNode { node_id } {
	if { "error" in [getStateNode $node_id] } {
		return true
	}

	return false
}

proc isErrorLink { link_id } {
	if { "error" in [getStateLink $link_id] } {
		return true
	}

	return false
}

proc isErrorNodeIface { node_id iface_id } {
	if { "error" in [getStateNodeIface $node_id $iface_id] } {
		return true
	}

	return false
}

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
#   lassign [getDefaultRoutesConfig $node_id] routes4 routes6
# FUNCTION
#   Called when translating IMUNES default gateways configuration to node
#   pre-running configuration. Returns IPv4 and IPv6 routes lists.
# INPUTS
#   * node_id -- node id
# RESULT
#   * all_routes4 -- {0.0.0.0/0 gw4} pairs of default IPv4 routes
#   * all_routes6 -- {0.0.0.0/0 gw6} pairs of default IPv6 routes
#****
proc getDefaultRoutesConfig { node_id } {
	set all_routes4 {}
	set all_routes6 {}
	foreach iface_id [ifcList $node_id] {
		lassign [getSubnetNextIpAndGateways "ipv4" $node_id $iface_id] - subnet_gws4
		lassign [getSubnetNextIpAndGateways "ipv6" $node_id $iface_id] - subnet_gws6

		foreach ipv4_addr [getIfcIPv4addrs $node_id $iface_id] {
			if { $ipv4_addr == "dhcp" } {
				continue
			}

			set mask [ip::mask $ipv4_addr]
			foreach gateway4 $subnet_gws4 {
				set gw_mask [ip::mask $gateway4]
				if {
					$mask == $gw_mask &&
					[ip::prefix $gateway4] == [ip::prefix $ipv4_addr]
				} {
					set gateway4 [lindex [split $gateway4 "/"] 0]
					if { "0.0.0.0/0 $gateway4" ni $all_routes4 } {
						lappend all_routes4 "0.0.0.0/0 $gateway4"
					}
				}
			}
		}

		foreach ipv6_addr [getIfcIPv6addrs $node_id $iface_id] {
			set mask [ip::mask $ipv6_addr]
			foreach gateway6 $subnet_gws6 {
				set gw_mask [ip::mask $gateway6]
				if {
					$mask == $gw_mask &&
					[ip::prefix $gateway6] == [ip::prefix $ipv6_addr]
				} {
					set gateway6 [lindex [split $gateway6 "/"] 0]
					if { "::/0 $gateway6" ni $all_routes6 } {
						lappend all_routes6 "::/0 $gateway6"
					}
				}
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

	foreach iface_id [ifcList $node_id] {
		removeIface $node_id $iface_id $keep_other_ifaces
	}

	setToRunning "node_list" [removeFromList [getFromRunning "node_list"] $node_id]
	setToRunning "no_auto_execute_nodes" [removeFromList [getFromRunning "no_auto_execute_nodes"] $node_id]

	set node_type [getNodeType $node_id]
	recalculateNumType $node_type [invokeTypeProc $node_type "namingBase"]

	cfgUnset "nodes" $node_id
	if { ! [isRunningNode $node_id] } {
		unsetStateNode $node_id
	}
}

#****f* nodecfg.tcl/newNode
# NAME
#   newNode -- new node
# SYNOPSIS
#   set node_id [newNode $node_type]
# FUNCTION
#   Returns the node id of a new node of the specified type.
# INPUTS
#   * node_type -- node type
# RESULT
#   * node_id -- node id of a new node of the specified type
#****
proc newNode { node_type } {
	global viewid
	catch { unset viewid }

	set node_list [getFromRunning "node_list"]
	set node_id ""
	while { $node_id == "" } {
		set node_id [newObjectId $node_list "n"]
		if { [getStateNode $node_id] != "" } {
			lappend node_list $node_id
			set node_id ""
		}
	}

	setNodeType $node_id $node_type

	lappendToRunning "node_list" $node_id

	invokeTypeProc $node_type "confNewNode" $node_id

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
		lassign [logicalPeerByIfc $l2node_id $iface_id] peer_id peer_iface_id -
		if {
			[getIfcLink $peer_id $peer_iface_id] == "" ||
			$peer_id in $l2peers
		} {
			continue
		}

		set peer_type [getNodeType $peer_id]
		if {
			$peer_type != "rj45" &&
			[invokeTypeProc $peer_type "netlayer"] == "LINK"
		} {
			set l2peers [listLANNodes $peer_id $l2peers]
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
	global changed

	foreach node_id $nodes {
		set from_type [getNodeType $node_id]
		if { $from_type == $to_type } {
			continue
		}

		set changed 1

		invokeNodeProc $node_id "transformNode" $node_id $to_type
		recalculateNumType $from_type [invokeTypeProc $from_type "namingBase"]
	}

	recalculateNumType $to_type [invokeTypeProc $to_type "namingBase"]
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
	upvar ::switch_cases::updateNode switch_cases_var

	global changed

	dputs ""
	dputs "= UPDATE NODE $node_id START ="

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

		# trigger undo log
		set changed 1

		dputs "==== $change: '$key'"

		set old_value [_cfgGet $old_node_cfg $key]
		set new_value [_cfgGet $new_node_cfg $key]
		if { $change in "changed" } {
			dputs "==== OLD: '$old_value'"
		}
		if { $change in "new changed" } {
			dputs "==== NEW: '$new_value'"
		}

		switch -exact $key [list {*}$switch_cases_var default {}]
	}

	if { $changed } {
		# will reset 'changed' to 0
		updateUndoLog

		# changed needs to be 1 to trigger redrawing
		set changed 1
	}

	dputs "= /UPDATE NODE $node_id END ="
	dputs ""

	return $new_node_cfg
}

proc getSubnetIfaces { node_id iface_id } {
	global possible_loop possible_vlan_loop

	set possible_loop 0
	set possible_vlan_loop 0

	set current_depth 0
	set vlan_id 0
	if { [getNodeType $node_id] in "lanswitch" } {
		if {
			[getNodeVlanFiltering $node_id] &&
			[getIfcVlanType $node_id $iface_id] == "access"
		} {
			set vlan_id [getIfcVlanTag $node_id $iface_id]
		}
	} else {
		set vlan_id [getIfcVlanTag $node_id $iface_id]
		if { $vlan_id == "" } {
			set vlan_id 0
		}
	}

	set my_prio [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
	set retv [collectSubnet $current_depth "$my_prio $node_id $iface_id $vlan_id" {} {} 0]

	#dputs "$node_id - $iface_id"
	#foreach elem $retv {
	#	lassign $elem prio node_id iface_id vlan_id
	#	dputs "\t'[getNodeName $node_id]' '[getIfcName $node_id $iface_id]' '$vlan_id'"
	#}

	if { $possible_loop } {
		sputs "Possible loop detected!"
	}

	if { $possible_vlan_loop } {
		sputs "Possible VLAN loop detected!"
	}

	return $retv
}

proc collectSubnet { current_depth elem exclude_elems depth_tree level } {
	global possible_loop possible_vlan_loop

	if { $possible_loop } {
		return
	}

	set cur_state [dictGet $depth_tree $current_depth]
	set sorted_cur_state [lsort $cur_state]

	set upper_depth [expr $current_depth + 1]
	set upper_state [lsort [dictGet $depth_tree $upper_depth]]

	set lower_depth [expr $current_depth - 1]
	set lower_state [lsort [dictGet $depth_tree $lower_depth]]

	# if we're getting the same state on upper/lower levels, we assume it's looping
	if { $cur_state != {} && ($sorted_cur_state == $lower_state || $sorted_cur_state == $upper_state) } {
		set possible_vlan_loop 1

		return
	}

	if { $possible_vlan_loop && ($current_depth < -2 || $current_depth > 2) } {
		return
	}

	# fallback for loop detection
	if { $current_depth < -5 || $current_depth > 5 } {
		set possible_vlan_loop 1

		return
	}

	if { $elem in $cur_state } {
		# already covered this interface
		return
	}

	dict lappend depth_tree $current_depth $elem

	lassign $elem - node_id iface_id -

	set retv [dictGet $depth_tree 0]
	set upper_state [dictGet $depth_tree $upper_depth]
	if { $current_depth < 0 } {
		foreach upper [invokeNodeProc $node_id "collectIfcUppers" $node_id $iface_id] {
			if { $upper in $exclude_elems } {
				continue
			}

			set upper_vlan_id [lindex $upper end]
			if { $upper_state != {} } {
				set skip 0
				# upper elements != 0 set the VLAN
				foreach upper_state_elem $upper_state {
					set upper_state_vlan_id [lindex $upper_state_elem end]
					if { $upper_state_vlan_id == 0 } {
						continue
					}

					# upper not matching our VLAN, skip
					if { $upper_state_vlan_id != $upper_vlan_id } {
						set skip 1
					} else {
						set skip 0

						break
					}
				}

				if { $skip } {
					continue
				}
			}

			set res [collectSubnet $upper_depth $upper {} $depth_tree [expr $level + 1]]
			if { $res != {} && $res != $retv } {
				lappend retv {*}$res
				set retv [lsort -uniq -decreasing $retv]
			}

			set upper_state [dictGet $depth_tree $upper_depth]
		}
	}

	foreach lower [invokeNodeProc $node_id "collectIfcLowers" $node_id $iface_id] {
		if { $lower in $exclude_elems } {
			continue
		}

		set res [collectSubnet $lower_depth $lower {} $depth_tree [expr $level + 1]]
		if { $res != {} && $res != $retv } {
			lappend retv {*}$res
			set retv [lsort -uniq -decreasing $retv]
		}
	}

	set peer_data {}
	set peers [invokeNodeProc $node_id "collectIfcPeers" $node_id $iface_id]
	foreach peer $peers {
		if { $peer in $exclude_elems } {
			continue
		}

		# for loop detection, we don't want to include other peers
		set res [collectSubnet $current_depth $peer [removeFromList $peers $peer] $depth_tree [expr $level + 1]]
		if { $res == {} } {
			continue
		}

		if { $res in $peer_data } {
			set possible_loop 1

			return $retv
		}

		if { $res != $retv } {
			lappend peer_data $res
			lappend retv {*}$res
			set retv [lsort -uniq -decreasing $retv]
		}
	}

	return [lsort -uniq -decreasing $retv]
}

proc getSubnetAddrsByPrio { node_id iface_id } {
	set nodes_ifaces [getSubnetIfaces $node_id $iface_id]

	set sub4 {}
	set sub6 {}

	set sorted_nodes_ifaces [lsort -integer -decreasing -index 0 $nodes_ifaces]
	foreach node_subnet_data $sorted_nodes_ifaces {
		lassign $node_subnet_data - subnet_node_id subnet_iface_id -
		if { "$node_id $iface_id" == "$subnet_node_id $subnet_iface_id" } {
			continue
		}

		set addrs [getIfcIPv4addrs $subnet_node_id $subnet_iface_id]
		if { $sub4 == "" && $addrs != {} } {
			set sub4 [lindex $addrs 0]
		}

		set addrs [getIfcIPv6addrs $subnet_node_id $subnet_iface_id]
		if { $sub6 == "" && $addrs != {} } {
			set sub6 [lindex $addrs 0]
		}

		if { $sub4 != "" && $sub6 != "" } {
			break
		}
	}

	return [list $sub4 $sub6]
}

# returns next free IP address and all gateway IP addresses in subnet
proc getSubnetNextIpAndGateways { ip_version orig_node_id orig_iface_id { nodes "*" } } {
	set ip_version_num [string index $ip_version 3]
	set orig_priority [invokeNodeProc $orig_node_id "getSubnetPriority" $orig_node_id $orig_iface_id]

	set subnet_addrs {}
	set subnet_gws [dict create]

	foreach node_subnet_data [getSubnetIfaces $orig_node_id $orig_iface_id] {
		lassign $node_subnet_data gw_priority node_id iface_id -
		if { $nodes != "*" && $node_id ni $nodes } {
			continue
		}

		# getIfcIPv4addrs/getIfcIPv6addrs
		set addr [lindex [getIfcIPv${ip_version_num}addrs $node_id $iface_id] 0]
		if { $addr == "" || $addr == "dhcp"} {
			continue
		}

		if { $gw_priority > $orig_priority } {
			dict lappend subnet_gws $gw_priority $addr
		}

		lappend subnet_addrs $addr
	}

	set min_ip [invokeNodeProc $orig_node_id "IPAddrRange"]
	if { $min_ip == "" } {
		set min_ip 0
	}

	if { $subnet_addrs == {} } {
		set subnet_gws {}

		# ipv4_used_list/ipv6_used_list
		set subnet_addrs [getFromRunning "ipv${ip_version_num}_used_list"]

		# findFreeIPv4Subnet/findFreeIPv6Subnet
		set template_ip [findFreeIPv${ip_version_num}Subnet "" $subnet_addrs]
	} else {
		set subnet_gws [concat {*}[dict values [lsort -decreasing -stride 2 -index 0 $subnet_gws]]]
		if { $subnet_gws != {} } {
			set template_ip [lindex $subnet_gws 0]
		} else {
			set template_ip [lindex $subnet_addrs 0]
		}
	}

	return [list [nextAddrInSubnet $ip_version $template_ip $subnet_addrs $min_ip] $subnet_gws]
}

proc appendNodeSubnetRoutes { node_id routes { ip_version "both" } } {
	foreach iface_id [ifcList $node_id] {
		set old_subnet_data [getSubnetIfaces $node_id $iface_id]

		set my_priority [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
		foreach node_subnet_data $old_subnet_data {
			lassign $node_subnet_data priority subnet_node_id subnet_iface_id -
			if { $priority < 0 } {
				continue
			}

			if { $subnet_node_id ni [dict keys $routes] } {
				set all_routes [getDefaultRoutesConfig $subnet_node_id]
				if { $ip_version == "both" } {
					set filtered_routes $all_routes
				} elseif { $ip_version == "ipv4" } {
					set filtered_routes [lindex $all_routes 0]
				} elseif { $ip_version == "ipv6" } {
					set filtered_routes [lindex $all_routes 1]
				}

				dict set routes $subnet_node_id $filtered_routes
			}
		}
	}

	return $routes
}

proc assignSubnet { ip_version node_id iface_id selected { subnet "" } } {
	set ip_version_num [string index $ip_version 3]
	if { $ip_version == "ipv4" } {
		set overlap_proc "::ip::isOverlap"
	} else {
		set overlap_proc "ip6_isOverlap"
	}

	if { $subnet == "" } {
		lassign [getSubnetNextIpAndGateways $ip_version $node_id $iface_id] subnet -
	}

	set nodes_ifaces [getSubnetIfaces $node_id $iface_id]

	# first, get all non-selected used addresses from this subnet
	set used_addrs {}
	foreach node_subnet_data $nodes_ifaces {
		lassign $node_subnet_data priority subnet_node_id subnet_iface_id -

		# getIfcIPv4addrs/getIfcIPv6addrs
		set cur_addrs [getIfcIPv${ip_version_num}addrs $subnet_node_id $subnet_iface_id]

		if { $priority >= 0 && $subnet_node_id in $selected } {
			# skip if we're the main gateway
			foreach cur_addr $cur_addrs {
				set subnet_mask [ip::mask $subnet]
				set cur_mask [ip::mask $cur_addr]
				if { $subnet_mask == $cur_mask && [$overlap_proc $subnet $cur_addr] } {
					lappend used_addrs {*}$cur_addrs
					set nodes_ifaces [removeFromList $nodes_ifaces [list $node_subnet_data]]

					break
				}
			}

			continue
		}

		if { $priority >= 0 } {
			lappend used_addrs {*}$cur_addrs
		}

		set nodes_ifaces [removeFromList $nodes_ifaces [list $node_subnet_data]]
	}

	# change selected nodes interfaces to new subnet
	foreach node_subnet_data $nodes_ifaces {
		lassign $node_subnet_data - subnet_node_id subnet_iface_id

		# getIfcIPv4addrs/getIfcIPv6addrs
		set cur_addrs [getIfcIPv${ip_version_num}addrs $subnet_node_id $subnet_iface_id]

		# skip if we're the main gateway and subnet matches
		foreach cur_addr $cur_addrs {
			if { [$overlap_proc $subnet $cur_addr] } {
				lappend used_addrs {*}$cur_addrs
				set nodes_ifaces [removeFromList $nodes_ifaces [list $node_subnet_data]]

				continue
			}
		}

		set addr [nextAddrInSubnet $ip_version $subnet $used_addrs [invokeNodeProc $subnet_node_id "IPAddrRange"]]
		if { $addr == "" } {
			continue
		}

		lappend used_addrs $addr

		setToRunning "${ip_version}_used_list" \
			[removeFromList [getFromRunning "${ip_version}_used_list"] $cur_addrs "keep_doubles"]

		# setIfcIPv4addrs/setIfcIPv6addrs
		setIfcIPv${ip_version_num}addrs $subnet_node_id $subnet_iface_id $addr
		lappendToRunning "${ip_version}_used_list" $addr
	}
}

proc nextAddrInSubnet { ip_version subnet used_addrs { min_ip 0 } } {
	set mask [ip::mask $subnet]
	set subnet [ip::prefix $subnet]

	if { $ip_version == "ipv4" } {
		set toint_proc "ip::toInteger"
		set tostr_proc "ip::intToString"
		set overlap_proc "ip::isOverlap"
	} else {
		set min_ip "0x$min_ip"
		set toint_proc "ip6_strToInt"
		set tostr_proc "ip6_intToStr"
		set overlap_proc "ip6_isOverlap"
	}

	set addr_int [expr [$toint_proc $subnet] + $min_ip]
	set addr "[$tostr_proc $addr_int]"
	if { $ip_version == "ipv6" } {
		set addr "[::ip::contract $addr]"
	}

	set addr "$addr/$mask"

	if { ! [$overlap_proc $subnet/$mask $addr] } {
		# out of prefix range, start from first
		set addr_int [expr $addr_int - $min_ip + 1]
		set addr "[$tostr_proc $addr_int]"
		if { $ip_version == "ipv6" } {
			set addr "[::ip::contract $addr]"
		}

		set addr "$addr/$mask"
	}

	while { $addr in $used_addrs } {
		incr addr_int
		set addr "[$tostr_proc $addr_int]"
		if { $ip_version == "ipv6" } {
			set addr "[::ip::contract $addr]"
		}

		set addr "$addr/$mask"

		if { ! [$overlap_proc $subnet/$mask $addr] } {
			# out of prefix range
			return ""
		}
	}

	return $addr
}

#****f* nodeconfig.tcl/autoIPAddr
# NAME
#   autoIPAddr -- automaticaly assign an IPv4/IPv6 address
# SYNOPSIS
#   autoIPAddr $ip_version $node_id $iface_id { $nodes }
# FUNCTION
#   Automaticaly assignes an IPv4/IPv6 address to the interface $iface_id of
#   of the node $node_id for IP version $ip_version. Setting $nodes adds a
#   filter for nodes to take into consideration when assigning a subnet
#   (default is *: 'my subnet').
# INPUTS
#   * ip_version -- IP version: ipv4 or ipv6
#   * node_id -- the node id containing the interface to witch a new
#     IPv4/IPv6 address should be assigned
#   * iface_id -- the interface to witch a new, automatically generated,
#     IPv4/IPv6 address will be assigned
#   * nodes (optional) -- a list of nodes to consider when calculating the next
#     IP address.
#****
proc autoIPAddr { ip_version node_id iface_id { nodes "*" } } {
	set ip_version_num [string index $ip_version 3]
	if { ! [getActiveOption "IPv${ip_version_num}autoAssign"] } {
		return
	}

	lassign [getSubnetNextIpAndGateways $ip_version $node_id $iface_id $nodes] addr -
	if { $addr == "" } {
		global gui execMode

		if { $gui && $execMode != "batch" } {
			after idle { .dialog1.msg configure -wraplength 4i }
			tk_dialog .dialog1 "IMUNES warning" \
				"You have depleted the current IPv$ip_version_num pool of addresses for this subnet. You can disable IP auto assign using:\n\nTools -> IPv${ip_version_num} auto-assign addresses/routes\n\nor change the pool in\n\nTools -> IPv${ip_version_num} address pool\n\nand renumber the subnet." \
				info 0 Dismiss
		}

		return
	}

	setIfcIPv${ip_version_num}addrs $node_id $iface_id $addr
	lappendToRunning "ipv${ip_version_num}_used_list" $addr
}
