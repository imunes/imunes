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
		lassign [logicalPeerByIfc $l2node_id $iface_id] peer_id peer_iface_id
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

		switch -exact $key {
			"name" {
				setNodeName $node_id $new_value
			}

			"model" {
				setNodeModel $node_id $new_value
			}

			"router_config" {
				dict for {protocol_key protocol_change} [dictDiff $old_value $new_value] {
					if { $protocol_change == "copy" } {
						continue
					}

					setNodeProtocol $node_id $protocol_key [_cfgGet $new_value $protocol_key]
				}
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
	set nodes_ifaces {}

	foreach iface_id [invokeNodeProc $node_id "getSubnetIfaces" $node_id $iface_id] {
		set gw_priority [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
		lappend nodes_ifaces "$gw_priority $node_id $iface_id"
	}

	if { [llength $nodes_ifaces] == 0 } {
		return {}
	}

	set idx 0
	while { $idx < [llength $nodes_ifaces] } {
		lassign [lindex $nodes_ifaces $idx] gw_priority node_id iface_id
		incr idx

		lassign [logicalPeerByIfc $node_id $iface_id] node_id iface_id
		if { $node_id == {} || $iface_id == {} } {
			continue
		}

		set gw_priority [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
		if { "$gw_priority $node_id $iface_id" in $nodes_ifaces } {
			continue
		}

		foreach iface_id [invokeNodeProc $node_id "getSubnetIfaces" $node_id $iface_id] {
			set gw_priority [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
			if { "$gw_priority $node_id $iface_id" in $nodes_ifaces } {
				continue
			}

			lappend nodes_ifaces "$gw_priority $node_id $iface_id"
		}
	}

	return $nodes_ifaces
}

proc getSubnetAddrsByPrio { ip_version node_id iface_id { ignore_self "true" } } {
	set nodes_ifaces [getSubnetIfaces $node_id $iface_id]

	if { $ip_version == "ipv4" } {
		set getter_proc "getIfcIPv4addrs"
	} else {
		set getter_proc "getIfcIPv6addrs"
	}

	set sorted_nodes_ifaces [lsort -integer -decreasing -index 0 $nodes_ifaces]
	foreach node_subnet_data $sorted_nodes_ifaces {
		lassign $node_subnet_data gw_priority subnet_node_id subnet_iface_id
		if { $ignore_self && $node_id == $subnet_node_id && $iface_id == $subnet_iface_id} {
			continue
		}

		set addrs [$getter_proc $subnet_node_id $subnet_iface_id]
		if { $addrs != {} } {
			return [lindex $addrs 0]
		}
	}
}

# returns next free IP address and all gateway IP addresses in subnet
proc getSubnetNextIpAndGateways { ip_version orig_node_id orig_iface_id { nodes "*" } } {
	set orig_priority [invokeNodeProc $orig_node_id "getSubnetPriority" $orig_node_id $orig_iface_id]

	set subnet_addrs {}
	set subnet_gws [dict create]

	if { $ip_version == "ipv4" } {
		set getter_proc "getIfcIPv4addrs"
		set next_addr_proc "getNextIPv4addr"
		set next_subnet_proc "nextFreeIP4Addr"
		set used_list [getFromRunning "ipv4_used_list"]
	} else {
		set getter_proc "getIfcIPv6addrs"
		set next_addr_proc "getNextIPv6addr"
		set next_subnet_proc "nextFreeIP6Addr"
		set used_list [getFromRunning "ipv6_used_list"]
	}

	foreach node_subnet_data [getSubnetIfaces $orig_node_id $orig_iface_id] {
		lassign $node_subnet_data gw_priority node_id iface_id
		if { $nodes != "*" && $node_id ni $nodes } {
			continue
		}

		set addr [lindex [$getter_proc $node_id $iface_id] 0]
		if { $addr == "" || $addr == "dhcp"} {
			continue
		}

		if { $gw_priority > $orig_priority } {
			dict lappend subnet_gws $gw_priority $addr
		}

		lappend subnet_addrs $addr
	}

	if { $subnet_addrs == {} } {
		return [list [$next_addr_proc [getNodeType $orig_node_id] $used_list] {}]
	}

	set subnet_gws [concat {*}[dict values [lsort -decreasing -stride 2 -index 0 $subnet_gws]]]
	if { $subnet_gws != {} } {
		set template_ip [lindex $subnet_gws 0]
	} else {
		set template_ip [lindex $subnet_addrs 0]
	}

	set min_ip [invokeNodeProc $orig_node_id "IPAddrRange"]
	if { $min_ip == "" } {
		set min_ip 0
	}
	if { $ip_version == "ipv6" } {
		set min_ip [expr 0x$min_ip]
	}

	return [list [$next_subnet_proc $template_ip $min_ip $subnet_addrs] $subnet_gws]
}

proc appendNodeSubnetRoutes { node_id routes { ip_version "both" } } {
	foreach iface_id [ifcList $node_id] {
		set old_subnet_data [getSubnetIfaces $node_id $iface_id]

		set my_priority [invokeNodeProc $node_id "getSubnetPriority" $node_id $iface_id]
		foreach node_subnet_data $old_subnet_data {
			lassign $node_subnet_data priority subnet_node_id subnet_iface_id
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
